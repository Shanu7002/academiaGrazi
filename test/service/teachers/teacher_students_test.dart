import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/teachers/teacher_students.dart';
import 'package:flutter_test/flutter_test.dart';

// Quinta, 12/11/2026, 15:00.
final _now = DateTime(2026, 11, 12, 15);
DateTime _daysAgo(int days) => DateTime(2026, 11, 12 - days, 9);

TeacherStudentSnapshot _student(
  String id,
  String name, {
  int? trainedDaysAgo,
  int? assessedDaysAgo = 10,
  String? unitId,
  Map<int, String?>? schedule,
}) => TeacherStudentSnapshot(
  student: UserModel(
    id: id,
    name: name,
    email: '$id@example.com',
    createdAt: _daysAgo(200),
    unitId: unitId,
  ),
  lastFinishedAt: trainedDaysAgo == null ? null : _daysAgo(trainedDaysAgo),
  hasActivePlan: true,
  weeklySchedule: schedule,
  lastAssessmentAt: assessedDaysAgo == null ? null : _daysAgo(assessedDaysAgo),
);

void main() {
  final rows = teacherStudentRows([
    _student('b', 'Bruno Alves', trainedDaysAgo: 15, unitId: 'centro'),
    _student('a', 'Ângela Souza', trainedDaysAgo: 1, unitId: 'jardim'),
    _student('c', 'Carla Dias', trainedDaysAgo: 40, assessedDaysAgo: 120),
  ], _now);

  test('calcula a situação de cada aluno em ordem alfabética', () {
    expect(rows.map((r) => r.id), ['a', 'b', 'c']);
    final byId = {for (final r in rows) r.id: r};
    expect(byId['a']!.status, StudentStatus.active);
    expect(byId['b']!.status, StudentStatus.atRisk);
    expect(byId['b']!.daysIdle, 15);
    expect(byId['c']!.status, StudentStatus.inactive);
    expect(byId['c']!.assessmentPending, isTrue);
    expect(byId['a']!.assessmentPending, isFalse);
  });

  test('busca por nome ignora maiúsculas e acentos', () {
    expect(filterTeacherStudents(rows, query: 'angela').map((r) => r.id), [
      'a',
    ]);
    expect(filterTeacherStudents(rows, query: 'ALVES').map((r) => r.id), ['b']);
    expect(filterTeacherStudents(rows, query: 'zzz'), isEmpty);
  });

  test('filtra por risco, inativos, avaliação pendente e unidade', () {
    List<String> ids(TeacherStudentFilter filter, {String? unitId}) =>
        filterTeacherStudents(
          rows,
          filter: filter,
          unitId: unitId,
        ).map((r) => r.id).toList();
    expect(ids(TeacherStudentFilter.all), hasLength(3));
    expect(ids(TeacherStudentFilter.atRisk), ['b']);
    expect(ids(TeacherStudentFilter.inactive), ['c']);
    expect(ids(TeacherStudentFilter.assessmentPending), ['c']);
    expect(ids(TeacherStudentFilter.all, unitId: 'jardim'), ['a']);
  });

  group('nextTrainingDay', () {
    // Quinta = 4.
    const schedule = {1: 'treino-a', 4: 'treino-b', 7: null};

    test('hoje, se há treino programado e o aluno ainda não treinou', () {
      expect(nextTrainingDay(schedule, _now), DateTime(2026, 11, 12));
    });

    test('quem já treinou hoje tem o próximo dia programado', () {
      expect(
        nextTrainingDay(schedule, _now, trainedToday: true),
        DateTime(2026, 11, 16),
      );
    });

    test('vira a semana e volta ao mesmo dia se for o único', () {
      expect(
        nextTrainingDay(const {4: 'treino-b'}, _now, trainedToday: true),
        DateTime(2026, 11, 19),
      );
    });

    test('sem ficha ou sem dia programado não há próximo treino', () {
      expect(nextTrainingDay(null, _now), isNull);
      expect(nextTrainingDay(const {1: null, 2: ''}, _now), isNull);
    });
  });
}
