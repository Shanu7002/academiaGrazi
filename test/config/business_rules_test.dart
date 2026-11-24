import 'package:academiagrazi/config/business_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessRules |', () {
    test('o aluno entra em risco de evasão antes de ficar inativo', () {
      expect(
        BusinessRules.riskDaysWithoutTraining,
        lessThan(BusinessRules.inactiveDaysWithoutTraining),
      );
    });

    test('as faixas de volume da montagem são crescentes', () {
      expect(BusinessRules.lightVolumeMaxSets, greaterThan(0));
      expect(
        BusinessRules.lightVolumeMaxSets,
        lessThan(BusinessRules.mediumVolumeMaxSets),
      );
    });

    test('a primeira avaliação é cobrada antes do prazo de reavaliação', () {
      expect(BusinessRules.firstAssessmentGraceDays, greaterThan(0));
      expect(
        BusinessRules.firstAssessmentGraceDays,
        lessThan(BusinessRules.assessmentOverdueDays),
      );
    });

    test('o alerta de inativos é uma fração entre 0 e 1', () {
      expect(BusinessRules.inactiveStudentsAlertRatio, inExclusiveRange(0, 1));
    });
  });
}
