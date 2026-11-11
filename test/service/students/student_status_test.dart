import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime(2026, 11, 11, 10);
  DateTime diasAtras(int dias) => DateTime(2026, 11, 11 - dias, 18);

  const risco = BusinessRules.riskDaysWithoutTraining;
  const inativo = BusinessRules.inactiveDaysWithoutTraining;

  StudentStatus status({DateTime? ultimoTreino, DateTime? cadastro}) =>
      statusFor(lastFinishedAt: ultimoTreino, createdAt: cadastro, now: agora);

  group('daysSince', () {
    test('conta dias de calendário, não blocos de 24 horas', () {
      expect(daysSince(DateTime(2026, 11, 10, 23), agora), 1);
      expect(daysSince(DateTime(2026, 11, 11, 0, 5), agora), 0);
    });

    test('converte datas em UTC para o fuso local', () {
      final local = DateTime(2026, 11, 8, 12);
      expect(daysSince(local.toUtc(), agora), 3);
    });

    test('data no futuro conta como zero dias', () {
      expect(daysSince(DateTime(2026, 11, 12), agora), 0);
    });
  });

  test('daysWithoutTraining é nulo para quem nunca treinou', () {
    expect(daysWithoutTraining(null, agora), isNull);
    expect(daysWithoutTraining(diasAtras(4), agora), 4);
  });

  group('statusFor', () {
    test('treinou hoje ou há menos de $risco dias: ativo', () {
      expect(status(ultimoTreino: agora), StudentStatus.active);
      expect(status(ultimoTreino: diasAtras(risco - 1)), StudentStatus.active);
    });

    test('a partir de $risco dias sem treino: risco', () {
      expect(status(ultimoTreino: diasAtras(risco)), StudentStatus.atRisk);
      expect(
        status(ultimoTreino: diasAtras(inativo - 1)),
        StudentStatus.atRisk,
      );
    });

    test('a partir de $inativo dias sem treino: inativo', () {
      expect(status(ultimoTreino: diasAtras(inativo)), StudentStatus.inactive);
      expect(
        status(ultimoTreino: diasAtras(inativo + 40)),
        StudentStatus.inactive,
      );
    });

    test('nunca treinou e cadastro recente: novo', () {
      expect(status(cadastro: agora), StudentStatus.newcomer);
      expect(status(cadastro: diasAtras(inativo - 1)), StudentStatus.newcomer);
    });

    test('nunca treinou e cadastro com $inativo dias ou mais: inativo', () {
      expect(status(cadastro: diasAtras(inativo)), StudentStatus.inactive);
    });

    test('nunca treinou e sem data de cadastro: inativo', () {
      expect(status(), StudentStatus.inactive);
    });

    test('o último treino vale mais que a data de cadastro', () {
      expect(
        status(ultimoTreino: diasAtras(1), cadastro: diasAtras(200)),
        StudentStatus.active,
      );
    });
  });
}
