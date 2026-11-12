import 'package:academiagrazi/service/students/student_status.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';

/// Um aluno na lista do professor, com a situação já calculada.
class TeacherStudentRow {
  final TeacherStudentSnapshot snapshot;
  final StudentStatus status;

  /// Dias sem treinar; null se nunca treinou.
  final int? daysIdle;

  /// Avaliação física atrasada (P9).
  final bool assessmentPending;

  /// Próximo dia com treino na programação da ficha (meia-noite local);
  /// null sem ficha presencial ou sem dia programado.
  final DateTime? nextTrainingDay;

  const TeacherStudentRow({
    required this.snapshot,
    required this.status,
    required this.daysIdle,
    required this.assessmentPending,
    required this.nextTrainingDay,
  });

  String get id => snapshot.student.id;
  String get name => snapshot.student.name;
}

/// Filtros da lista de alunos do professor.
enum TeacherStudentFilter { all, atRisk, inactive, assessmentPending }

/// Situação de cada aluno em [now], em ordem alfabética.
List<TeacherStudentRow> teacherStudentRows(
  Iterable<TeacherStudentSnapshot> snapshots,
  DateTime now,
) {
  final rows = [
    for (final item in snapshots)
      TeacherStudentRow(
        snapshot: item,
        status: statusFor(
          lastFinishedAt: item.lastFinishedAt,
          createdAt: item.student.createdAt,
          now: now,
        ),
        daysIdle: daysWithoutTraining(item.lastFinishedAt, now),
        assessmentPending: assessmentOverdueDays(item, now) != null,
        nextTrainingDay: nextTrainingDay(
          item.weeklySchedule,
          now,
          trainedToday: daysWithoutTraining(item.lastFinishedAt, now) == 0,
        ),
      ),
  ];
  // Ordem alfabética sem acentos ("Ângela" antes de "Bruno").
  String key(TeacherStudentRow row) =>
      ExerciseCatalogService.normalizeSearch(row.name);
  rows.sort((a, b) => key(a).compareTo(key(b)));
  return rows;
}

/// Alunos que casam com a busca por nome (sem diferenciar maiúsculas e
/// acentos), com o [filter] e, se informada, com a unidade [unitId].
List<TeacherStudentRow> filterTeacherStudents(
  Iterable<TeacherStudentRow> rows, {
  String query = '',
  TeacherStudentFilter filter = TeacherStudentFilter.all,
  String? unitId,
}) {
  final term = ExerciseCatalogService.normalizeSearch(query);
  return rows.where((row) {
    final matchesFilter = switch (filter) {
      TeacherStudentFilter.all => true,
      TeacherStudentFilter.atRisk => row.status == StudentStatus.atRisk,
      TeacherStudentFilter.inactive => row.status == StudentStatus.inactive,
      TeacherStudentFilter.assessmentPending => row.assessmentPending,
    };
    return matchesFilter &&
        (unitId == null || row.snapshot.student.unitId == unitId) &&
        (term.isEmpty ||
            ExerciseCatalogService.normalizeSearch(row.name).contains(term));
  }).toList();
}

/// Próximo dia com treino na programação semanal ([schedule]: 1 = segunda
/// … 7 = domingo → id do treino ou null), a partir de hoje.
///
/// Hoje só conta se o aluno ainda não treinou ([trainedToday]). Sem dia
/// programado, devolve null.
DateTime? nextTrainingDay(
  Map<int, String?>? schedule,
  DateTime now, {
  bool trainedToday = false,
}) {
  if (schedule == null) return null;
  for (var offset = trainedToday ? 1 : 0; offset <= 7; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    final routine = schedule[day.weekday];
    if (routine != null && routine.isNotEmpty) return day;
  }
  return null;
}
