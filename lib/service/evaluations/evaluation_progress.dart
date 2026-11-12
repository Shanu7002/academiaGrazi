import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';

/// Variação de peso (kg) da avaliação anterior para a mais recente, pela
/// data de cada avaliação. Null com menos de duas avaliações.
double? latestWeightChangeKg(Iterable<PhysicalEvaluation> evaluations) {
  final ordered = [...evaluations]..sort((a, b) => a.date.compareTo(b.date));
  if (ordered.length < 2) return null;
  return ordered.last.weightKg - ordered[ordered.length - 2].weightKg;
}
