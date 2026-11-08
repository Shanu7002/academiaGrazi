import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/student_weekly_progress.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingSession session(String id, DateTime finish, {
  String routine = 'treino-a',
  TrainingSessionStatus status = TrainingSessionStatus.finished,
}) => TrainingSession(
  id: id, studentId: 'aluno', instructorId: 'prof', planId: 'ficha',
  planVersion: 1, routineId: routine, routineName: 'Treino A',
  status: status,
  startedAt: finish.subtract(const Duration(minutes: 30)),
  finishedAt: status == TrainingSessionStatus.finished ? finish : null,
  warmupDone: true, exercises: const [],
);

void main() {
  test('semana e de segunda a domingo inclusive em virada de mes', () {
    expect(StudentWeeklyProgress.monday(DateTime(2026, 11, 1)),
      DateTime(2026, 10, 26));
    expect(StudentWeeklyProgress.monday(DateTime(2026, 11, 2)),
      DateTime(2026, 11, 2));
  });

  test('marca apenas sessoes finalizadas na data real e na semana', () {
    final sessions = [
      session('a', DateTime(2026, 11, 2, 12)),
      session('b', DateTime(2026, 11, 5, 18), routine: 'treino-b'),
      session('anterior', DateTime(2026, 11, 1, 18)),
      session('aberto', DateTime(2026, 11, 2, 16),
        status: TrainingSessionStatus.inProgress),
    ];
    expect(StudentWeeklyProgress.inWeek(sessions, DateTime(2026, 11, 3)).length, 2);
    expect(StudentWeeklyProgress.onDay(sessions, DateTime(2026, 11, 2)).length, 1);
    expect(StudentWeeklyProgress.completedRoutineOnDay(
      sessions, DateTime(2026, 11, 5), 'treino-a'), isNull);
    expect(StudentWeeklyProgress.completedRoutineOnDay(
      sessions, DateTime(2026, 11, 5), 'treino-b')?.id, 'b');
  });
}
