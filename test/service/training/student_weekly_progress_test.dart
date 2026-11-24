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

  group('streakWeeks', () {
    // Quinta, 12/11/2026. Semanas: 09/11 (atual), 02/11, 26/10, 19/10.
    final now = DateTime(2026, 11, 12, 10);

    test('sem treinos finalizados a sequencia e zero', () {
      expect(StudentWeeklyProgress.streakWeeks(const [], now), 0);
      expect(
        StudentWeeklyProgress.streakWeeks([
          session('aberto', DateTime(2026, 11, 10, 8),
            status: TrainingSessionStatus.inProgress),
        ], now),
        0,
      );
    });

    test('conta as semanas consecutivas ate a atual', () {
      final sessions = [
        session('atual', DateTime(2026, 11, 9, 7)),
        session('anterior-1', DateTime(2026, 11, 3, 18)),
        session('anterior-2', DateTime(2026, 11, 7, 18)),
        session('duas-atras', DateTime(2026, 10, 26, 18)),
        // A semana de 19/10 ficou sem treino: quebra a sequencia.
        session('antiga', DateTime(2026, 10, 12, 18)),
      ];
      expect(StudentWeeklyProgress.streakWeeks(sessions, now), 3);
    });

    test('semana atual sem treino ainda nao quebra a sequencia', () {
      final sessions = [
        session('anterior', DateTime(2026, 11, 8, 20)), // domingo
        session('duas-atras', DateTime(2026, 10, 27, 18)),
      ];
      expect(StudentWeeklyProgress.streakWeeks(sessions, now), 2);
    });

    test('uma semana inteira sem treino zera a sequencia', () {
      final sessions = [session('velha', DateTime(2026, 10, 28, 18))];
      expect(StudentWeeklyProgress.streakWeeks(sessions, now), 0);
    });

    test('sequencia atravessa a virada do ano', () {
      final sessions = [
        session('janeiro', DateTime(2027, 1, 1, 9)), // sexta
        session('dezembro', DateTime(2026, 12, 22, 9)),
      ];
      expect(
        StudentWeeklyProgress.streakWeeks(sessions, DateTime(2027, 1, 2)),
        2,
      );
    });
  });

  group('isOpenToday', () {
    final day = DateTime(2026, 11, 2, 12);
    final pending = session('aberta', DateTime(2026, 11, 2, 10),
      status: TrainingSessionStatus.inProgress);

    test('sessao aberta hoje da mesma rotina esta em andamento', () {
      expect(StudentWeeklyProgress.isOpenToday(
        pending: pending, routineId: 'treino-a', day: day), isTrue);
    });

    test('sessao de outro dia, outra rotina ou sem sessao nao conta', () {
      expect(StudentWeeklyProgress.isOpenToday(
        pending: pending, routineId: 'treino-b', day: day), isFalse);
      expect(StudentWeeklyProgress.isOpenToday(
        pending: pending, routineId: 'treino-a',
        day: DateTime(2026, 11, 3)), isFalse);
      expect(StudentWeeklyProgress.isOpenToday(
        pending: null, routineId: 'treino-a', day: day), isFalse);
      expect(StudentWeeklyProgress.isOpenToday(
        pending: pending, routineId: null, day: day), isFalse);
    });

    test('sessao superada por um treino finalizado depois dela nao conta', () {
      final finished = session('feita', DateTime(2026, 11, 2, 11));
      expect(StudentWeeklyProgress.isOpenToday(
        pending: pending, routineId: 'treino-a', day: day,
        finishedToday: finished), isFalse);
    });
  });
}
