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
}
