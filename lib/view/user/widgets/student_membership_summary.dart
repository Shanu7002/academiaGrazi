import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/memberships/money.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/admin/widgets/student_registration_details.dart';
import 'package:academiagrazi/view/components/membership_display.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plano do aluno no perfil: nome, validade, mensalidade e situação.
/// Só leitura; quem atribui o plano e registra pagamentos é o admin.
class StudentMembershipSummary extends StatefulWidget {
  final String studentId;

  /// Relógio injetável para os testes.
  final DateTime Function() clock;

  const StudentMembershipSummary({
    super.key,
    required this.studentId,
    this.clock = DateTime.now,
  });

  @override
  State<StudentMembershipSummary> createState() =>
      _StudentMembershipSummaryState();
}

class _StudentMembershipSummaryState extends State<StudentMembershipSummary> {
  Stream<MembershipModel?>? _membership;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    // Telas testadas isoladamente podem não registrar o serviço.
    _membership =
        locator.isRegistered<MembershipService>()
            ? locator<MembershipService>().streamActiveMembership(
              widget.studentId,
            )
            : null;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _membership;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<MembershipModel?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Erro ao carregar plano: ${snapshot.error}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text('Não conseguimos carregar seu plano agora.'),
              TextButton(
                key: const Key('botao_tentar_meu_plano'),
                onPressed: () => setState(_subscribe),
                child: const Text('Tentar novamente'),
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final membership = snapshot.data;
        if (membership == null) {
          return _text(
            'Você ainda não tem um plano cadastrado. Fale com a recepção '
            'para escolher o seu.',
          );
        }
        return _details(membership);
      },
    );
  }

  Widget _text(String text, {Color color = AppColors.textBody}) => Text(
    text,
    style: GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.small,
      color: color,
    ),
  );

  Widget _details(MembershipModel membership) {
    final summary = summarizeMembership(membership, widget.clock());
    final next = summary.nextOpenFee;
    final modalities = membership.modalities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.planName,
                    key: const Key('nome_meu_plano'),
                    style: GoogleFonts.barlowCondensed(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Válido até ${formatDateBr(summary.endDate)}',
                    style: GoogleFonts.barlowCondensed(
                      color: AppColors.textBody,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MembershipStatusChip.standing(
              summary.standing,
              key: const Key('situacao_meu_plano'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Mensalidade',
                value: formatBrl(membership.monthlyPriceCents),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                label: 'Próximo vencimento',
                value: next == null ? 'Tudo pago' : formatDateBr(next.dueDate),
              ),
            ),
          ],
        ),
        if (modalities != null && modalities.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoTile(label: 'Modalidades', value: modalities),
        ],
        if (summary.overdueCount > 0) ...[
          const SizedBox(height: 12),
          _text(
            summary.overdueCount == 1
                ? 'Você tem 1 mensalidade em aberto '
                    '(${formatBrl(summary.overdueCents)}). Procure a recepção '
                    'para regularizar.'
                : 'Você tem ${summary.overdueCount} mensalidades em aberto '
                    '(${formatBrl(summary.overdueCents)}). Procure a recepção '
                    'para regularizar.',
            color: AppColors.danger,
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: adminLabelStyle),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
