import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/service/evaluations/evaluation_progress.dart';
import 'package:flutter_test/flutter_test.dart';

PhysicalEvaluation _evaluation(DateTime date, double weightKg) =>
    PhysicalEvaluation(
      date: date,
      instructorId: 'prof-1',
      sex: BiologicalSex.female,
      age: 30,
      weightKg: weightKg,
      heightCm: 165,
      skinfolds: const Skinfolds(
        chest: 10,
        midaxillary: 10,
        triceps: 10,
        subscapular: 10,
        abdominal: 10,
        suprailiac: 10,
        thigh: 10,
      ),
    );

void main() {
  test('com menos de duas avaliações não há variação', () {
    expect(latestWeightChangeKg(const []), isNull);
    expect(
      latestWeightChangeKg([_evaluation(DateTime(2026, 9, 1), 70)]),
      isNull,
    );
  });

  test('compara as duas avaliações mais recentes pela data', () {
    final change = latestWeightChangeKg([
      _evaluation(DateTime(2026, 10, 1), 68.5),
      _evaluation(DateTime(2026, 6, 1), 75),
      _evaluation(DateTime(2026, 8, 1), 70.3),
    ]);
    expect(change, closeTo(-1.8, 0.0001));
  });

  test('ganho de peso fica positivo', () {
    final change = latestWeightChangeKg([
      _evaluation(DateTime(2026, 8, 1), 60),
      _evaluation(DateTime(2026, 10, 1), 61.2),
    ]);
    expect(change, closeTo(1.2, 0.0001));
  });
}
