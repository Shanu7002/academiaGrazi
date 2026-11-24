import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/models/training/training_session.dart';

/// Resumo semanal calculado a partir das sessoes reais, sem gravar estados
/// redundantes. Considera a semana local (segunda a domingo).
abstract final class StudentWeeklyProgress {
  static DateTime monday(DateTime day) =>
      DateTime(day.year, day.month, day.day).subtract(
        Duration(days: day.weekday - DateTime.monday),
      );

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<TrainingSession> onDay(
    Iterable<TrainingSession> sessions,
    DateTime date,
  ) => sessions.where((session) {
    final finished = session.finishedAt?.toLocal();
    return session.status == TrainingSessionStatus.finished &&
        finished != null && sameDay(finished, date);
  }).toList(growable: false);

  static List<TrainingSession> inWeek(
    Iterable<TrainingSession> sessions,
    DateTime now,
  ) {
    final start = monday(now);
    final end = start.add(const Duration(days: 7));
    return sessions.where((session) {
      final finished = session.finishedAt?.toLocal();
      return session.status == TrainingSessionStatus.finished &&
          finished != null && !finished.isBefore(start) && finished.isBefore(end);
    }).toList(growable: false);
  }

  static TrainingSession? completedRoutineOnDay(
    Iterable<TrainingSession> sessions,
    DateTime date,
    String? routineId,
  ) {
    if (routineId == null) return null;
    for (final session in onDay(sessions, date)) {
      if (session.routineId == routineId) return session;
    }
    return null;
  }

  /// A sessao [pending] e o treino [routineId] em andamento *hoje*.
  ///
  /// Uma sessao aberta em outro dia, de outra rotina, ou ja superada por uma
  /// sessao finalizada depois dela ([finishedToday]) nao conta.
  static bool isOpenToday({
    required TrainingSession? pending,
    required String? routineId,
    required DateTime day,
    TrainingSession? finishedToday,
  }) {
    if (routineId == null ||
        pending == null ||
        pending.status != TrainingSessionStatus.inProgress ||
        pending.routineId != routineId ||
        !sameDay(pending.startedAt.toLocal(), day)) {
      return false;
    }
    final end = finishedToday?.finishedAt;
    return end == null || end.isBefore(pending.startedAt);
  }

  /// P3 · Sequencia em semanas consecutivas (segunda a domingo) com pelo
  /// menos [BusinessRules.streakMinFinishedSessionsPerWeek] treinos
  /// finalizados.
  ///
  /// A semana atual ainda esta aberta: enquanto nao atinge o minimo, ela nao
  /// quebra a sequencia, que passa a ser contada a partir da semana anterior.
  static int streakWeeks(Iterable<TrainingSession> sessions, DateTime now) {
    final perWeek = <DateTime, int>{};
    for (final session in sessions) {
      final finished = session.finishedAt?.toLocal();
      if (session.status != TrainingSessionStatus.finished ||
          finished == null) {
        continue;
      }
      final week = monday(finished);
      perWeek[week] = (perWeek[week] ?? 0) + 1;
    }

    const minimum = BusinessRules.streakMinFinishedSessionsPerWeek;
    bool reached(DateTime week) => (perWeek[week] ?? 0) >= minimum;
    // A semana anterior e a do domingo de vespera, calculada por [monday]
    // como as chaves do mapa.
    DateTime previous(DateTime week) =>
        monday(DateTime(week.year, week.month, week.day - 1));

    var week = monday(now);
    if (!reached(week)) week = previous(week);
    var streak = 0;
    while (reached(week)) {
      streak++;
      week = previous(week);
    }
    return streak;
  }
}
