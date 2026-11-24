import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Textos e selos de plano e mensalidade compartilhados entre o perfil do
// aluno e as telas do admin.

String paymentMethodLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.pix => 'Pix',
  PaymentMethod.cash => 'Dinheiro',
  PaymentMethod.card => 'Cartão',
  PaymentMethod.transfer => 'Transferência',
};

String standingLabel(MembershipStanding standing) => switch (standing) {
  MembershipStanding.upToDate => 'Em dia',
  MembershipStanding.dueSoon => 'Vence em breve',
  MembershipStanding.overdue => 'Em atraso',
  MembershipStanding.ended => 'Plano encerrado',
};

String feeStatusLabel(FeeStatus status) => switch (status) {
  FeeStatus.paid => 'Paga',
  FeeStatus.overdue => 'Em atraso',
  FeeStatus.dueSoon => 'Vence em breve',
  FeeStatus.upcoming => 'A vencer',
};

/// "1 mês", "6 meses".
String monthsLabel(int months) => months == 1 ? '1 mês' : '$months meses';

/// Cores (texto, fundo) do selo de cada situação.
(Color, Color) _colors({required bool danger, required bool alert}) {
  if (danger) return (AppColors.danger, AppColors.dangerSurface);
  if (alert) return (AppColors.accentText, AppColors.accentAlertSurface);
  return (AppColors.primary, AppColors.avatarBackground);
}

/// Selo arredondado com a situação do plano ou da mensalidade.
class MembershipStatusChip extends StatelessWidget {
  final String label;
  final bool danger;
  final bool alert;

  const MembershipStatusChip({
    super.key,
    required this.label,
    this.danger = false,
    this.alert = false,
  });

  MembershipStatusChip.standing(MembershipStanding standing, {Key? key})
    : this(
        key: key,
        label: standingLabel(standing),
        danger: standing == MembershipStanding.overdue,
        alert: standing == MembershipStanding.dueSoon,
      );

  MembershipStatusChip.fee(FeeStatus status, {Key? key})
    : this(
        key: key,
        label: feeStatusLabel(status),
        danger: status == FeeStatus.overdue,
        alert: status == FeeStatus.dueSoon,
      );

  @override
  Widget build(BuildContext context) {
    final (color, surface) = _colors(danger: danger, alert: alert);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.caption,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
