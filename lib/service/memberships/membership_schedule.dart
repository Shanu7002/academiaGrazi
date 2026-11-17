import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';

/// Situação de uma mensalidade.
enum FeeStatus { paid, overdue, dueSoon, upcoming }

/// Situação geral do plano do aluno.
enum MembershipStanding {
  /// Nenhuma mensalidade vencida em aberto.
  upToDate,

  /// Há mensalidade em aberto vencendo nos próximos dias.
  dueSoon,

  /// Há mensalidade vencida e não paga.
  overdue,

  /// A vigência acabou e todas as mensalidades foram pagas.
  ended,
}

/// Uma mensalidade do plano, calculada a partir da data de início.
class MembershipFee {
  /// Número da mensalidade (1 = primeira).
  final int installment;
  final DateTime dueDate;
  final int amountCents;
  final MembershipPayment? payment;
  final FeeStatus status;

  const MembershipFee({
    required this.installment,
    required this.dueDate,
    required this.amountCents,
    required this.payment,
    required this.status,
  });
}

/// Resumo do plano para os cartões do aluno e do admin.
class MembershipSummary {
  final MembershipStanding standing;

  /// Último dia da vigência.
  final DateTime endDate;

  /// Próxima mensalidade em aberto (a mais antiga), se houver.
  final MembershipFee? nextOpenFee;
  final int overdueCount;
  final int overdueCents;
  final int paidCount;

  const MembershipSummary({
    required this.standing,
    required this.endDate,
    required this.nextOpenFee,
    required this.overdueCount,
    required this.overdueCents,
    required this.paidCount,
  });
}

/// Soma [months] meses a uma data sem hora. Quando o dia não existe no mês
/// de destino (ex.: 31 → fevereiro), usa o último dia desse mês.
DateTime addMonthsClamped(DateTime date, int months) {
  final firstOfTarget = DateTime(date.year, date.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    date.day > lastDay ? lastDay : date.day,
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Último dia da vigência: um dia antes de completar [durationMonths].
DateTime membershipEndDate(MembershipModel membership) {
  final end = addMonthsClamped(membership.startDate, membership.durationMonths);
  return end.subtract(const Duration(days: 1));
}

/// Mensalidades do plano, uma por mês a partir de `startDate`.
///
/// Em aberto com vencimento antes de hoje é [FeeStatus.overdue]; vencendo
/// hoje ou nos próximos [BusinessRules.membershipFeeDueSoonDays] dias é
/// [FeeStatus.dueSoon].
List<MembershipFee> membershipFees(MembershipModel membership, DateTime now) {
  final today = _dateOnly(now);
  final dueSoonLimit = today.add(
    const Duration(days: BusinessRules.membershipFeeDueSoonDays),
  );
  return [
    for (var index = 0; index < membership.durationMonths; index++)
      () {
        final installment = index + 1;
        final dueDate = addMonthsClamped(membership.startDate, index);
        final payment = membership.paymentFor(installment);
        final FeeStatus status;
        if (payment != null) {
          status = FeeStatus.paid;
        } else if (dueDate.isBefore(today)) {
          status = FeeStatus.overdue;
        } else if (!dueDate.isAfter(dueSoonLimit)) {
          status = FeeStatus.dueSoon;
        } else {
          status = FeeStatus.upcoming;
        }
        return MembershipFee(
          installment: installment,
          dueDate: dueDate,
          amountCents: payment?.amountCents ?? membership.monthlyPriceCents,
          payment: payment,
          status: status,
        );
      }(),
  ];
}

/// Situação geral do plano em [now].
MembershipSummary summarizeMembership(
  MembershipModel membership,
  DateTime now,
) {
  final fees = membershipFees(membership, now);
  final overdue = fees.where((fee) => fee.status == FeeStatus.overdue);
  final open = fees.where((fee) => fee.status != FeeStatus.paid);
  final endDate = membershipEndDate(membership);
  final nextOpen = open.isEmpty ? null : open.first;

  final MembershipStanding standing;
  if (overdue.isNotEmpty) {
    standing = MembershipStanding.overdue;
  } else if (nextOpen?.status == FeeStatus.dueSoon) {
    standing = MembershipStanding.dueSoon;
  } else if (open.isEmpty && _dateOnly(now).isAfter(endDate)) {
    standing = MembershipStanding.ended;
  } else {
    standing = MembershipStanding.upToDate;
  }

  return MembershipSummary(
    standing: standing,
    endDate: endDate,
    nextOpenFee: nextOpen,
    overdueCount: overdue.length,
    overdueCents: overdue.fold(0, (sum, fee) => sum + fee.amountCents),
    paidCount: fees.length - open.length,
  );
}

/// Planos com mensalidade vencida em aberto, do maior valor em atraso para
/// o menor (controle de inadimplência do admin).
List<(MembershipModel, MembershipSummary)> overdueMemberships(
  Iterable<MembershipModel> memberships,
  DateTime now,
) {
  final overdue =
      [
        for (final membership in memberships)
          if (membership.status == MembershipStatus.active)
            (membership, summarizeMembership(membership, now)),
      ].where((entry) => entry.$2.overdueCount > 0).toList();
  overdue.sort((a, b) => b.$2.overdueCents.compareTo(a.$2.overdueCents));
  return overdue;
}

/// O aluno fica sem acesso ao app quando o plano ativo tem mensalidade em
/// aberto vencida há mais de [BusinessRules.membershipBlockGraceDays] dias.
/// Sem plano, ou com plano encerrado, o acesso continua liberado.
bool isAccessBlocked(MembershipModel? membership, DateTime now) {
  if (membership == null || membership.status != MembershipStatus.active) {
    return false;
  }
  final limit = _dateOnly(
    now,
  ).subtract(const Duration(days: BusinessRules.membershipBlockGraceDays));
  return membershipFees(membership, now).any(
    (fee) => fee.status == FeeStatus.overdue && fee.dueDate.isBefore(limit),
  );
}
