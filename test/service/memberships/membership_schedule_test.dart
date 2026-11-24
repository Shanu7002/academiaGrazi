import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

MembershipModel _membership({
  DateTime? start,
  int duration = 3,
  List<int> paid = const [],
}) {
  return MembershipModel(
    id: 'm1',
    studentId: 'aluno1',
    planId: 'plano1',
    planName: 'Trimestral',
    monthlyPriceCents: 12990,
    durationMonths: duration,
    startDate: start ?? DateTime(2026, 1, 10),
    createdBy: 'admin1',
    payments: [
      for (final installment in paid)
        MembershipPayment(
          installment: installment,
          paidOn: DateTime(2026, 1, 10),
          method: PaymentMethod.pix,
          amountCents: 12990,
          recordedBy: 'admin1',
          recordedAt: DateTime.utc(2026, 1, 10),
        ),
    ],
  );
}

void main() {
  group('addMonthsClamped |', () {
    test('soma meses mantendo o dia', () {
      expect(addMonthsClamped(DateTime(2026, 1, 10), 2), DateTime(2026, 3, 10));
    });

    test('usa o último dia quando o mês de destino é mais curto', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    });

    test('vira o ano', () {
      expect(
        addMonthsClamped(DateTime(2026, 11, 15), 3),
        DateTime(2027, 2, 15),
      );
    });
  });

  test('gera uma mensalidade por mês a partir do início', () {
    final fees = membershipFees(_membership(), DateTime(2025, 12, 1));

    expect(fees.map((fee) => fee.installment), [1, 2, 3]);
    expect(fees.map((fee) => fee.dueDate), [
      DateTime(2026, 1, 10),
      DateTime(2026, 2, 10),
      DateTime(2026, 3, 10),
    ]);
    expect(fees.every((fee) => fee.amountCents == 12990), isTrue);
    expect(fees.every((fee) => fee.status == FeeStatus.upcoming), isTrue);
  });

  test('classifica paga, vencida, vence em breve e futura', () {
    final fees = membershipFees(
      _membership(duration: 4, paid: [1]),
      // 2ª venceu em 10/02; 3ª vence em 10/03, dentro dos 5 dias.
      DateTime(2026, 3, 6, 15),
    );

    expect(fees.map((fee) => fee.status), [
      FeeStatus.paid,
      FeeStatus.overdue,
      FeeStatus.dueSoon,
      FeeStatus.upcoming,
    ]);
  });

  test('mensalidade que vence hoje ainda não está atrasada', () {
    final fees = membershipFees(_membership(), DateTime(2026, 1, 10, 23, 59));

    expect(fees.first.status, FeeStatus.dueSoon);
  });

  group('summarizeMembership |', () {
    test('em atraso soma quantidade e valor das vencidas', () {
      final summary = summarizeMembership(_membership(), DateTime(2026, 2, 20));

      expect(summary.standing, MembershipStanding.overdue);
      expect(summary.overdueCount, 2);
      expect(summary.overdueCents, 25980);
      expect(summary.nextOpenFee?.installment, 1);
    });

    test('vence em breve quando a próxima em aberto está perto', () {
      final summary = summarizeMembership(
        _membership(paid: [1]),
        DateTime(2026, 2, 7),
      );

      expect(summary.standing, MembershipStanding.dueSoon);
      expect(summary.nextOpenFee?.installment, 2);
    });

    test('em dia quando não há vencida nem próxima perto', () {
      final summary = summarizeMembership(
        _membership(paid: [1]),
        DateTime(2026, 1, 20),
      );

      expect(summary.standing, MembershipStanding.upToDate);
      expect(summary.paidCount, 1);
    });

    test('encerrado depois da vigência com tudo pago', () {
      final membership = _membership(paid: [1, 2, 3]);

      expect(membershipEndDate(membership), DateTime(2026, 4, 9));
      expect(
        summarizeMembership(membership, DateTime(2026, 4, 9)).standing,
        MembershipStanding.upToDate,
      );
      expect(
        summarizeMembership(membership, DateTime(2026, 4, 10)).standing,
        MembershipStanding.ended,
      );
    });

    test('vigência acabada com mensalidade em aberto continua em atraso', () {
      final summary = summarizeMembership(
        _membership(paid: [1, 2]),
        DateTime(2026, 6, 1),
      );

      expect(summary.standing, MembershipStanding.overdue);
      expect(summary.overdueCount, 1);
    });
  });

  test('lista só planos ativos em atraso, do maior valor para o menor', () {
    final umaVencida = _membership(paid: [1]);
    final duasVencidas = MembershipModel(
      id: 'm2',
      studentId: 'aluno2',
      planId: 'plano1',
      planName: 'Trimestral',
      monthlyPriceCents: 12990,
      durationMonths: 3,
      startDate: DateTime(2026, 1, 10),
      createdBy: 'admin1',
    );
    final emDia = _membership(paid: [1, 2, 3]);
    final encerrado = MembershipModel(
      id: 'm4',
      studentId: 'aluno4',
      planId: 'plano1',
      planName: 'Trimestral',
      monthlyPriceCents: 12990,
      durationMonths: 3,
      startDate: DateTime(2026, 1, 10),
      createdBy: 'admin1',
      status: MembershipStatus.closed,
    );

    final result = overdueMemberships([
      umaVencida,
      emDia,
      encerrado,
      duasVencidas,
    ], DateTime(2026, 2, 20));

    expect(result.map((entry) => entry.$1.id), ['m2', 'm1']);
    expect(result.first.$2.overdueCount, 2);
  });

  group('isAccessBlocked |', () {
    // 1ª mensalidade vence em 10/01; tolerância de 5 dias.
    test('libera até 5 dias depois do vencimento', () {
      expect(
        isAccessBlocked(_membership(), DateTime(2026, 1, 15, 23)),
        isFalse,
      );
    });

    test('bloqueia com mensalidade vencida há mais de 5 dias', () {
      expect(isAccessBlocked(_membership(), DateTime(2026, 1, 16)), isTrue);
    });

    test('libera de novo quando a mensalidade é paga', () {
      expect(
        isAccessBlocked(_membership(paid: [1]), DateTime(2026, 1, 16)),
        isFalse,
      );
    });

    test('aluno sem plano ou com plano encerrado não é bloqueado', () {
      final encerrado = MembershipModel(
        id: 'm9',
        studentId: 'aluno1',
        planId: 'plano1',
        planName: 'Trimestral',
        monthlyPriceCents: 12990,
        durationMonths: 3,
        startDate: DateTime(2026, 1, 10),
        createdBy: 'admin1',
        status: MembershipStatus.closed,
      );

      expect(isAccessBlocked(null, DateTime(2026, 6, 1)), isFalse);
      expect(isAccessBlocked(encerrado, DateTime(2026, 6, 1)), isFalse);
    });
  });
}
