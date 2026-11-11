import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AdminDashboardService service;
  final now = DateTime(2026, 10, 20);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AdminDashboardService(db: db);
  });

  Future<void> addUser(String id, String type, String? createdAt) {
    return db.collection('users').doc(id).set({
      'name': id,
      'type': type,
      if (createdAt != null) 'createdAt': createdAt,
    });
  }

  test('conta somente alunos e os novos dos últimos 30 dias', () async {
    await addUser('a1', 'user', DateTime(2026, 1, 1).toIso8601String());
    await addUser('a2', 'user', DateTime(2026, 2, 1).toIso8601String());
    await addUser('a3', 'user', DateTime(2026, 10, 10).toIso8601String());
    await addUser('a4', 'user', null);
    await addUser('p1', 'instructor', DateTime(2026, 10, 15).toIso8601String());
    await addUser('adm', 'admin', DateTime(2026, 10, 15).toIso8601String());

    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 4);
    expect(stats.newLast30Days, 1);
    expect(stats.growthPercent!.round(), 33);
  });

  group('remotos e inativos', () {
    Future<void> addStudent(
      String id, {
      DateTime? createdAt,
      String? modality,
    }) {
      return db.collection('users').doc(id).set({
        'name': id,
        'type': 'user',
        if (createdAt != null) 'createdAt': createdAt.toUtc().toIso8601String(),
        if (modality != null) 'modality': modality,
      });
    }

    Future<void> addSession(
      String studentId,
      DateTime finishedAt, {
      String status = 'finished',
    }) {
      return db
          .collection('users')
          .doc(studentId)
          .collection('trainingSessions')
          .add({
            'status': status,
            'startedAt': finishedAt.toUtc().toIso8601String(),
            if (status == 'finished')
              'finishedAt': finishedAt.toUtc().toIso8601String(),
          });
    }

    test('conta remotos e inativos pelas sessões finalizadas', () async {
      final antigo = DateTime(2026, 1, 1);
      // Treinou há 2 dias: ativo.
      await addStudent('ativo', createdAt: antigo, modality: 'remote');
      await addSession('ativo', DateTime(2026, 10, 18, 9));
      await addSession('ativo', DateTime(2026, 8, 1, 9));
      // Treinou há 12 dias: em risco, mas ainda conta como ativo.
      await addStudent('risco', createdAt: antigo, modality: 'onSite');
      await addSession('risco', DateTime(2026, 10, 8, 9));
      // Último treino há 40 dias: inativo.
      await addStudent('parado', createdAt: antigo, modality: 'remote');
      await addSession('parado', DateTime(2026, 9, 10, 9));
      // Sessão em andamento não conta como treino: inativo.
      await addStudent('emAndamento', createdAt: antigo);
      await addSession(
        'emAndamento',
        DateTime(2026, 10, 19),
        status: 'inProgress',
      );
      // Cadastrado há 5 dias e sem treino: novo (não é inativo).
      await addStudent('novo', createdAt: DateTime(2026, 10, 15));
      // Sem data de cadastro e sem treino: inativo.
      await addStudent('semData');

      final stats = await service.getStudentStats(now: now);

      expect(stats.total, 6);
      expect(stats.remote, 2);
      expect(stats.inactive, 3);
      expect(stats.active, 3);
    });

    test('sem sessões, só os novos ficam fora dos inativos', () async {
      await addStudent('novo', createdAt: DateTime(2026, 10, 1));
      await addStudent('antigo', createdAt: DateTime(2026, 1, 1));

      final stats = await service.getStudentStats(now: now);

      expect(stats.inactive, 1);
      expect(stats.active, 1);
      expect(stats.remote, 0);
    });
  });

  group('getHourlyMovement', () {
    Future<void> addSession(
      DateTime startedAt, {
      String status = 'finished',
      String student = 'a1',
    }) {
      return db
          .collection('users')
          .doc(student)
          .collection('trainingSessions')
          .add({
            'status': status,
            'startedAt': startedAt.toUtc().toIso8601String(),
            if (status == 'finished')
              'finishedAt':
                  startedAt
                      .add(const Duration(hours: 1))
                      .toUtc()
                      .toIso8601String(),
          });
    }

    test('conta os treinos finalizados dos últimos 30 dias por hora', () async {
      await addSession(DateTime(2026, 10, 19, 18, 10));
      await addSession(DateTime(2026, 10, 18, 18, 40), student: 'a2');
      await addSession(DateTime(2026, 10, 1, 7));
      // Em andamento não conta.
      await addSession(DateTime(2026, 10, 19, 9), status: 'inProgress');
      // Mais de 30 dias atrás não conta.
      await addSession(DateTime(2026, 9, 1, 9));

      final movimento = await service.getHourlyMovement(now: now);

      expect(movimento.total, 3);
      expect(movimento.peakHour, 18);
      expect(movimento.counts[18 - 6], 2);
      expect(movimento.counts[7 - 6], 1);
    });

    test('fica vazio quando não há treinos', () async {
      final movimento = await service.getHourlyMovement(now: now);

      expect(movimento.isEmpty, isTrue);
    });
  });

  test('growthPercent é null quando não há base anterior', () async {
    await addUser('a1', 'user', DateTime(2026, 10, 10).toIso8601String());

    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 1);
    expect(stats.growthPercent, isNull);
  });

  test('retorna zero quando não há alunos', () async {
    final stats = await service.getStudentStats(now: now);

    expect(stats.total, 0);
    expect(stats.growthPercent, isNull);
  });

  group('getTeamWorkload', () {
    Future<void> addMember(
      String id,
      String type, {
      String? name,
      String? responsable,
    }) {
      return db.collection('users').doc(id).set({
        'name': name ?? id,
        'email': '$id@grazi.com',
        'type': type,
        if (responsable != null) 'responsable': responsable,
      });
    }

    test('conta os alunos de cada professor e ordena pela carga', () async {
      await addMember('p1', 'instructor', name: 'Marcos');
      await addMember('p2', 'instructor', name: 'Juliana');
      await addMember('p3', 'instructor', name: 'Sem Alunos');
      await addMember('a1', 'user', responsable: 'p1');
      await addMember('a2', 'user', responsable: 'p2');
      await addMember('a3', 'user', responsable: 'p2');
      await addMember('a4', 'user');
      await addMember('adm', 'admin');

      final team = await service.getTeamWorkload();

      expect(team.map((i) => i.name), ['Juliana', 'Marcos', 'Sem Alunos']);
      expect(team.map((i) => i.activeStudents), [2, 1, 0]);
      expect(team.first.email, 'p2@grazi.com');
    });

    test('retorna lista vazia sem professores', () async {
      await addMember('a1', 'user', responsable: 'p1');

      expect(await service.getTeamWorkload(), isEmpty);
    });
  });

  group('getInstructorDetails', () {
    test('traz o professor e só os alunos vinculados, por nome', () async {
      await db.collection('users').doc('p1').set({
        'name': 'Marcos',
        'email': 'marcos@grazi.com',
        'type': 'instructor',
        'registrationCode': 'ABCD2345',
      });
      await db.collection('users').doc('a1').set({
        'name': 'Zeca',
        'email': 'zeca@grazi.com',
        'type': 'user',
        'responsable': 'p1',
        'createdAt': DateTime(2026, 10, 10).toIso8601String(),
      });
      await db.collection('users').doc('a2').set({
        'name': 'ana',
        'email': 'ana@grazi.com',
        'type': 'user',
        'responsable': 'p1',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      await db.collection('users').doc('a3').set({
        'name': 'Outro',
        'type': 'user',
        'responsable': 'p2',
      });

      final details = await service.getInstructorDetails('p1');

      expect(details!.instructor.name, 'Marcos');
      expect(details.instructor.registrationCode, 'ABCD2345');
      expect(details.students.map((s) => s.user.name), ['ana', 'Zeca']);
      expect(details.newStudents(now: now), 1);
    });

    test('retorna null quando o professor não existe', () async {
      expect(await service.getInstructorDetails('nao-existe'), isNull);
    });
  });
}
