/// Treinos por hora de início, para o gráfico de movimento do admin.
class HourlyMovement {
  /// Hora da primeira barra (inclusive).
  final int firstHour;

  /// Uma contagem por hora, a partir de [firstHour]: `counts[0]` é das
  /// [firstHour]:00 às [firstHour]:59, e assim por diante.
  final List<int> counts;

  const HourlyMovement({required this.firstHour, required this.counts});

  int get total => counts.fold(0, (sum, count) => sum + count);

  bool get isEmpty => total == 0;

  /// Maior contagem de uma hora (0 quando vazio).
  int get peakCount =>
      counts.fold(0, (max, count) => count > max ? count : max);

  /// Hora de maior movimento; no empate, a mais cedo. `null` se vazio.
  int? get peakHour => isEmpty ? null : firstHour + counts.indexOf(peakCount);
}

/// Agrupa os inícios de treino por hora local, das [firstHour] às
/// [lastHour] (exclusive). Horários fora da faixa são ignorados.
HourlyMovement hourlyMovement(
  Iterable<DateTime> startedAt, {
  int firstHour = 6,
  int lastHour = 22,
}) {
  final counts = List<int>.filled(lastHour - firstHour, 0);
  for (final start in startedAt) {
    final hour = start.toLocal().hour;
    if (hour >= firstHour && hour < lastHour) {
      counts[hour - firstHour]++;
    }
  }
  return HourlyMovement(
    firstHour: firstHour,
    counts: List.unmodifiable(counts),
  );
}
