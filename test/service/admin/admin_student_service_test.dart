import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AdminStudentService service;
  final agora = DateTime(2026, 11, 11, 10);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AdminStudentService(db: db, clock: () => agora);
  });

  Future<void> addUser(
    String id,
    String type, {
    String? name,
    String? modality,
    String? responsable,
    DateTime? createdAt,
  }) {
    return db.collection('users').doc(id).set({
      'name': name ?? id,
      'email': '$id@test.com',
      'type': type,
      if (modality != null) 'modality': modality,
      if (responsable != null) 'responsable': responsable,
      if (createdAt != null) 'createdAt': createdAt.toUtc().toIso8601String(),
    });
  }

  UserModel aluno(String name, {StudentModality? modality}) =>
      UserModel(id: name, name: name, email: '', modality: modality);

  group('filterStudents', () {
    final alunos = [
      aluno('João Pedro', modality: StudentModality.remote),
      aluno('Ana Lima', modality: StudentModality.onSite),
      aluno('Bruno'),
    ];

    test('filtra por modalidade', () {
      List<String> nomes(StudentModalityFilter filtro) =>
          filterStudents(alunos, modality: filtro).map((a) => a.name).toList();

      expect(nomes(StudentModalityFilter.all).length, 3);
      expect(nomes(StudentModalityFilter.remote), ['João Pedro']);
      expect(nomes(StudentModalityFilter.onSite), ['Ana Lima']);
      expect(nomes(StudentModalityFilter.undefined), ['Bruno']);
    });

    test('busca pelo nome sem diferenciar maiúsculas e acentos', () {
      expect(filterStudents(alunos, query: ' JOAO ').map((a) => a.name), [
        'João Pedro',
      ]);
      expect(
        filterStudents(
          alunos,
          query: 'ana',
          modality: StudentModalityFilter.remote,
        ),
        isEmpty,
      );
    });
  });

  test('lista só alunos, em ordem alfabética', () async {
    await addUser('a1', 'user', name: 'zeca');
    await addUser('a2', 'user', name: 'Ana');
    await addUser('p1', 'instructor', name: 'Prof');

    final alunos = await service.streamStudents().first;
    expect(alunos.map((a) => a.name), ['Ana', 'zeca']);

    final professores = await service.streamInstructors().first;
    expect(professores.map((p) => p.name), ['Prof']);
  });

  test('streamStudent devolve null para quem não é aluno', () async {
    await addUser('a1', 'user');
    await addUser('p1', 'instructor');

    expect((await service.streamStudent('a1').first)?.id, 'a1');
    expect(await service.streamStudent('p1').first, isNull);
    expect(await service.streamStudent('nao-existe').first, isNull);
  });

  test('troca o professor e a modalidade do aluno', () async {
    await addUser('a1', 'user', responsable: 'p1');

    await service.changeInstructor('a1', 'p2');
    await service.setModality('a1', StudentModality.remote);

    final data = (await db.collection('users').doc('a1').get()).data()!;
    expect(data['responsable'], 'p2');
    expect(data['modality'], 'remote');
  });

  test('recusa professor vazio', () {
    expect(() => service.changeInstructor('a1', ' '), throwsArgumentError);
  });

  group('getActivity', () {
    Future<void> addSession(String status, DateTime? finishedAt) {
      return db
          .collection('users')
          .doc('a1')
          .collection('trainingSessions')
          .add({
            'status': status,
            if (finishedAt != null)
              'finishedAt': finishedAt.toUtc().toIso8601String(),
          });
    }

    test('usa o último treino finalizado', () async {
      await addUser('a1', 'user', createdAt: DateTime(2026, 1, 1));
      await addSession('finished', DateTime(2026, 10, 1));
      await addSession('finished', DateTime(2026, 11, 9, 18));
      await addSession('inProgress', null);
      final student = (await service.streamStudent('a1').first)!;

      final atividade = await service.getActivity(student);

      expect(atividade.status, StudentStatus.active);
      expect(atividade.lastFinishedAt, DateTime(2026, 11, 9, 18).toUtc());
    });

    test('sem treinos e cadastro recente é novo', () async {
      await addUser('a1', 'user', createdAt: DateTime(2026, 11, 1));
      final student = (await service.streamStudent('a1').first)!;

      final atividade = await service.getActivity(student);

      expect(atividade.status, StudentStatus.newcomer);
      expect(atividade.lastFinishedAt, isNull);
    });
  });
}
