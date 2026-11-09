import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

PhysicalEvaluation _avaliacao(DateTime date, double weightKg) =>
    PhysicalEvaluation(
      date: date,
      instructorId: 'prof-1',
      sex: BiologicalSex.male,
      age: 30,
      weightKg: weightKg,
      heightCm: 180,
      skinfolds: const Skinfolds(
        chest: 10,
        midaxillary: 12,
        triceps: 14,
        subscapular: 16,
        abdominal: 20,
        suprailiac: 15,
        thigh: 13,
      ),
    );

void main() {
  late FakeFirebaseFirestore db;
  late PhysicalEvaluationService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = PhysicalEvaluationService(db: db);
  });

  test(
    'grava na subcoleção do aluno e lista da mais antiga para a mais nova',
    () async {
      await service.addEvaluation('aluno-1', _avaliacao(DateTime(2026, 6), 78));
      await service.addEvaluation('aluno-1', _avaliacao(DateTime(2026, 1), 82));
      await service.addEvaluation('aluno-2', _avaliacao(DateTime(2026, 3), 90));

      final docs =
          await db
              .collection('users')
              .doc('aluno-1')
              .collection('evaluations')
              .get();
      expect(docs.size, 2);

      final avaliacoes = await service.streamEvaluations('aluno-1').first;
      expect(avaliacoes.map((a) => a.weightKg), [82, 78]);
      expect(avaliacoes.every((a) => a.id.isNotEmpty), isTrue);
    },
  );

  test('exclui uma avaliação', () async {
    await service.addEvaluation('aluno-1', _avaliacao(DateTime(2026, 6), 78));
    final [avaliacao] = await service.streamEvaluations('aluno-1').first;

    await service.deleteEvaluation('aluno-1', avaliacao.id);

    expect(await service.streamEvaluations('aluno-1').first, isEmpty);
  });
}
