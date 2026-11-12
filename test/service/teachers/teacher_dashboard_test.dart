import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Quinta, 12/11/2026, 15:00.
final _now = DateTime(2026, 11, 12, 15);
DateTime _daysAgo(int days) => DateTime(2026, 11, 12 - days, 9);

TeacherStudentSnapshot _student(
  String id, {
  int? trainedDaysAgo,
  bool hasPlan = true,
  int? assessedDaysAgo = 10,
  int joinedDaysAgo = 200,
}) => TeacherStudentSnapshot(
  student: UserModel(
    id: id,
    name: id,
    email: '$id@example.com',
    createdAt: _daysAgo(joinedDaysAgo),
  ),
  lastFinishedAt: trainedDaysAgo == null ? null : _daysAgo(trainedDaysAgo),
  hasActivePlan: hasPlan,
  lastAssessmentAt: assessedDaysAgo == null ? null : _daysAgo(assessedDaysAgo),
);

List<(TeacherPriorityKind, String, int?)> _priorities(
  TeacherDashboardData data,
) => [for (final p in data.priorities) (p.kind, p.student.id, p.days)];

void main() {
  group('buildTeacherDashboard', () {
    test('sem alunos não há números nem pendências', () {
      final data = buildTeacherDashboard(const [], _now);
      expect(data.totalStudents, 0);
      expect(data.activeStudents, 0);
      expect(data.presentToday, 0);
      expect(data.priorities, isEmpty);
    });

    test('presença conta só quem finalizou treino hoje', () {
      final data = buildTeacherDashboard([
        _student('hoje', trainedDaysAgo: 0),
        _student('ontem', trainedDaysAgo: 1),
        _student('nunca', joinedDaysAgo: 3, assessedDaysAgo: null),
      ], _now);
      expect(data.presentToday, 1);
      expect(data.activeStudents, 2);
      expect(data.priorities, isEmpty);
    });

    test('risco começa em 10 dias e inativo em 30 dias sem treinar', () {
      final data = buildTeacherDashboard([
        _student('9-dias', trainedDaysAgo: 9),
        _student('10-dias', trainedDaysAgo: 10),
        _student('29-dias', trainedDaysAgo: 29),
        _student('30-dias', trainedDaysAgo: 30),
      ], _now);
      expect(data.activeStudents, 1);
      expect(data.atRisk.map((p) => p.student.id), ['29-dias', '10-dias']);
      expect(_priorities(data), [
        (TeacherPriorityKind.inactive, '30-dias', 30),
        (TeacherPriorityKind.atRisk, '29-dias', 29),
        (TeacherPriorityKind.atRisk, '10-dias', 10),
      ]);
    });

    test('quem nunca treinou é novo no início e inativo depois de 30 dias', () {
      final data = buildTeacherDashboard([
        _student('novo', joinedDaysAgo: 5, assessedDaysAgo: null),
        _student('sumido', joinedDaysAgo: 45),
      ], _now);
      expect(_priorities(data), [
        (TeacherPriorityKind.inactive, 'sumido', null),
      ]);
    });

    test('aluno sem ficha nem treino em casa pede montagem', () {
      final data = buildTeacherDashboard([
        _student('sem-ficha', trainedDaysAgo: 2, hasPlan: false),
      ], _now);
      expect(_priorities(data), [
        (TeacherPriorityKind.noPlan, 'sem-ficha', null),
      ]);
    });

    test('avaliação atrasa aos 90 dias; a primeira é cobrada aos 30', () {
      final data = buildTeacherDashboard([
        _student('89-dias', trainedDaysAgo: 1, assessedDaysAgo: 89),
        _student('90-dias', trainedDaysAgo: 1, assessedDaysAgo: 90),
        _student(
          'novo-29',
          trainedDaysAgo: 1,
          assessedDaysAgo: null,
          joinedDaysAgo: 29,
        ),
        _student(
          'novo-30',
          trainedDaysAgo: 1,
          assessedDaysAgo: null,
          joinedDaysAgo: 30,
        ),
      ], _now);
      expect(_priorities(data), [
        // Sem avaliação nenhuma vem antes de qualquer atraso em dias.
        (TeacherPriorityKind.assessmentOverdue, 'novo-30', null),
        (TeacherPriorityKind.assessmentOverdue, '90-dias', 90),
      ]);
    });

    test('ordena por gravidade e um aluno pode ter várias pendências', () {
      final data = buildTeacherDashboard([
        _student('avaliacao', trainedDaysAgo: 1, assessedDaysAgo: 120),
        _student('sem-ficha', trainedDaysAgo: 1, hasPlan: false),
        _student('risco', trainedDaysAgo: 12),
        _student(
          'tudo',
          trainedDaysAgo: 40,
          hasPlan: false,
          assessedDaysAgo: 100,
        ),
      ], _now);
      expect(_priorities(data).map((p) => (p.$1, p.$2)), [
        (TeacherPriorityKind.inactive, 'tudo'),
        (TeacherPriorityKind.atRisk, 'risco'),
        (TeacherPriorityKind.noPlan, 'sem-ficha'),
        (TeacherPriorityKind.noPlan, 'tudo'),
        (TeacherPriorityKind.assessmentOverdue, 'avaliacao'),
        (TeacherPriorityKind.assessmentOverdue, 'tudo'),
      ]);
    });
  });

  group('TeacherDashboardService', () {
    late FakeFirebaseFirestore db;
    late TeacherDashboardService service;

    Future<void> addStudent(
      String id, {
      String teacher = 'prof-1',
      int joinedDaysAgo = 200,
    }) => db.collection('users').doc(id).set({
      'name': id,
      'email': '$id@example.com',
      'type': 'user',
      'responsable': teacher,
      'createdAt': _daysAgo(joinedDaysAgo).toUtc().toIso8601String(),
    });

    Future<void> addSession(String student, int daysAgo, {String? status}) =>
        db.collection('users').doc(student).collection('trainingSessions').add({
          'status': status ?? 'finished',
          'startedAt': _daysAgo(daysAgo).toUtc().toIso8601String(),
          if (status == null)
            'finishedAt':
                _daysAgo(
                  daysAgo,
                ).add(const Duration(hours: 1)).toUtc().toIso8601String(),
        });

    setUp(() {
      db = FakeFirebaseFirestore();
      service = TeacherDashboardService(db: db, clock: () => _now);
    });

    test('lê só os alunos do professor e os dados de cada um', () async {
      await addStudent('ativo');
      await addSession('ativo', 20);
      await addSession('ativo', 0);
      await addSession('ativo', 0, status: 'inProgress');
      await db.doc('users/ativo/trainingState/current').set({
        'activePlanId': 'f1',
        'instructorId': 'prof-1',
      });
      await db.collection('users/ativo/evaluations').add({
        'date': Timestamp.fromDate(_daysAgo(100)),
      });
      await db.collection('users/ativo/evaluations').add({
        'date': Timestamp.fromDate(_daysAgo(5)),
      });

      await addStudent('remoto');
      await addSession('remoto', 12);
      await db.doc('users/remoto/homeWorkouts/current').set({'version': 1});
      await db.collection('users/remoto/evaluations').add({
        'date': Timestamp.fromDate(_daysAgo(95)),
      });

      await addStudent('outro-professor', teacher: 'prof-2');
      await db.collection('users').doc('prof-1').set({
        'name': 'Prof',
        'type': 'instructor',
        'responsable': 'prof-1',
      });

      final data = await service.load('prof-1');

      expect(data.totalStudents, 2);
      expect(data.activeStudents, 1);
      expect(data.presentToday, 1);
      expect(data.atRisk.single.student.id, 'remoto');
      expect(_priorities(data), [
        (TeacherPriorityKind.atRisk, 'remoto', 12),
        (TeacherPriorityKind.assessmentOverdue, 'remoto', 95),
      ]);
    });

    test('lê a programação da ficha ativa e o treino em casa', () async {
      await addStudent('presencial');
      await db.doc('users/presencial/trainingState/current').set({
        'activePlanId': 'ficha-1',
        'instructorId': 'prof-1',
      });
      await db.doc('users/presencial/trainingPlans/ficha-1').set({
        'weeklySchedule': {'1': 'treino-a', '2': null, '4': 'treino-b'},
      });
      await addStudent('remoto');
      await db.doc('users/remoto/homeWorkouts/current').set({'version': 1});

      final students = {
        for (final s in await service.loadStudents('prof-1')) s.student.id: s,
      };

      expect(students['presencial']!.weeklySchedule, {
        1: 'treino-a',
        2: null,
        4: 'treino-b',
      });
      expect(students['presencial']!.hasHomeWorkout, isFalse);
      expect(students['remoto']!.weeklySchedule, isNull);
      expect(students['remoto']!.hasHomeWorkout, isTrue);
      expect(students['remoto']!.hasActivePlan, isTrue);
      expect(service.now, _now);
    });

    test('recusa professor vazio', () {
      expect(() => service.load(' '), throwsArgumentError);
      expect(() => service.loadStudents(''), throwsArgumentError);
    });
  });
}
