import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Sete dobras somando 100 mm.
const _dobras = Skinfolds(
  chest: 10,
  midaxillary: 12,
  triceps: 14,
  subscapular: 16,
  abdominal: 20,
  suprailiac: 15,
  thigh: 13,
);

PhysicalEvaluation _avaliacao(BiologicalSex sex, double weightKg) =>
    PhysicalEvaluation(
      date: DateTime(2026, 6, 15),
      instructorId: 'prof-1',
      sex: sex,
      age: 30,
      weightKg: weightKg,
      heightCm: 180,
      skinfolds: _dobras,
    );

void main() {
  group('PhysicalEvaluation | Jackson & Pollock 7 dobras + Siri', () {
    test('soma as sete dobras', () {
      expect(_dobras.sum, 100);
    });

    test('calcula a composição corporal masculina', () {
      final avaliacao = _avaliacao(BiologicalSex.male, 80);

      expect(avaliacao.bodyDensity, closeTo(1.065353, 1e-6));
      expect(avaliacao.bodyFatPercent, closeTo(14.6346, 1e-4));
      expect(avaliacao.fatMassKg, closeTo(11.7077, 1e-4));
      expect(avaliacao.leanMassKg, closeTo(68.2923, 1e-4));
      expect(avaliacao.bmi, closeTo(24.6914, 1e-4));
    });

    test('calcula a composição corporal feminina', () {
      final avaliacao = _avaliacao(BiologicalSex.female, 60);

      expect(avaliacao.bodyDensity, closeTo(1.051781, 1e-6));
      expect(avaliacao.bodyFatPercent, closeTo(20.6305, 1e-4));
      expect(avaliacao.fatMassKg, closeTo(12.3783, 1e-4));
      expect(avaliacao.leanMassKg, closeTo(47.6217, 1e-4));
    });

    test('persiste apenas as medidas e as recupera do Firestore', () {
      final original = _avaliacao(BiologicalSex.female, 60);
      final json = original.toJson();

      expect(json.keys, {
        'date',
        'instructorId',
        'sex',
        'age',
        'weightKg',
        'heightCm',
        'skinfolds',
      });
      expect(json['date'], isA<Timestamp>());
      expect(json['sex'], 'female');

      // Firestore web grava doubles inteiros como int.
      final lido = PhysicalEvaluation.fromJson({
        ...json,
        'weightKg': 60,
      }, 'av-1');

      expect(lido.id, 'av-1');
      expect(lido.date, original.date);
      expect(lido.sex, BiologicalSex.female);
      expect(lido.weightKg, 60.0);
      expect(lido.skinfolds.sum, 100);
      expect(lido.bodyFatPercent, closeTo(original.bodyFatPercent, 1e-9));
    });
  });
}
