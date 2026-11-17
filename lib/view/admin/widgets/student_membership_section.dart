import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/models/memberships/membership_plan_model.dart';
import 'package:academiagrazi/service/memberships/membership_schedule.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/memberships/money.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/admin/widgets/student_registration_details.dart';
import 'package:academiagrazi/view/components/membership_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Plano e mensalidades do aluno nos detalhes do admin: atribuir, trocar e
/// encerrar o plano, e registrar ou desfazer o pagamento de cada mensalidade.
/// Não há gateway: o pagamento é registrado à mão.
class StudentMembershipSection extends StatefulWidget {
  final String studentId;

  /// Relógio injetável para os testes.
  final DateTime Function() clock;

  const StudentMembershipSection({
    super.key,
    required this.studentId,
    this.clock = DateTime.now,
  });

  @override
  State<StudentMembershipSection> createState() =>
      _StudentMembershipSectionState();
}

class _StudentMembershipSectionState extends State<StudentMembershipSection> {
  final MembershipService _service = locator<MembershipService>();
  late Stream<MembershipModel?> _membership;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _membership = _service.streamActiveMembership(widget.studentId);
  }

  void _reload() {
    setState(() {
      _membership = _service.streamActiveMembership(widget.studentId);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? get _adminId => locator<FirebaseAuth>().currentUser?.uid;

  Future<void> _save(
    Future<void> Function(String adminId) action, {
    required String success,
    required String failure,
  }) async {
    final adminId = _adminId;
    if (adminId == null) {
      _showMessage('Sua sessão expirou. Entre de novo para continuar.');
      return;
    }
    setState(() => _saving = true);
    try {
      await action(adminId);
      if (!mounted) return;
      _showMessage(success);
    } catch (error) {
      debugPrint('Erro ao salvar plano do aluno: $error');
      if (!mounted) return;
      _showMessage(failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignPlan(MembershipModel? current) async {
    final result = await showDialog<_AssignResult>(
      context: context,
      builder:
          (_) => _AssignPlanDialog(
            plans: _service.streamPlans(),
            today: widget.clock(),
            replacing: current,
          ),
    );
    if (result == null || !mounted) return;
    await _save(
      (adminId) => _service.assignPlan(
        studentId: widget.studentId,
        plan: result.plan,
        startDate: result.startDate,
        adminId: adminId,
      ),
      success:
          current == null
              ? 'Plano atribuído ao aluno.'
              : 'Plano trocado. O anterior foi encerrado.',
      failure: 'Não conseguimos atribuir o plano agora. Tente novamente.',
    );
  }

  Future<void> _close(MembershipModel membership) async {
    final confirmed = await _confirm(
      title: 'Encerrar ${membership.planName}?',
      message:
          'O aluno fica sem plano. As mensalidades em aberto deste plano '
          'deixam de ser cobradas.',
      confirmKey: const Key('botao_confirmar_encerrar_plano'),
      confirmLabel: 'Encerrar',
    );
    if (!confirmed || !mounted) return;
    await _save(
      (_) => _service.closeMembership(membership.id),
      success: 'Plano encerrado.',
      failure: 'Não conseguimos encerrar o plano agora. Tente novamente.',
    );
  }

  Future<void> _recordPayment(
    MembershipModel membership,
    MembershipFee fee,
  ) async {
    final result = await showDialog<_PaymentResult>(
      context: context,
      builder: (_) => _PaymentDialog(fee: fee, today: widget.clock()),
    );
    if (result == null || !mounted) return;
    await _save(
      (adminId) => _service.recordPayment(
        membership.id,
        installment: fee.installment,
        paidOn: result.paidOn,
        method: result.method,
        amountCents: result.amountCents,
        adminId: adminId,
      ),
      success: 'Pagamento da ${fee.installment}ª mensalidade registrado.',
      failure: 'Não conseguimos registrar o pagamento agora. Tente novamente.',
    );
  }

  Future<void> _undoPayment(
    MembershipModel membership,
    MembershipFee fee,
  ) async {
    final confirmed = await _confirm(
      title: 'Desfazer pagamento?',
      message:
          'A ${fee.installment}ª mensalidade volta a ficar em aberto. Use só '
          'para corrigir um registro feito por engano.',
      confirmKey: const Key('botao_confirmar_desfazer_pagamento'),
      confirmLabel: 'Desfazer',
    );
    if (!confirmed || !mounted) return;
    await _save(
      (_) => _service.undoPayment(membership.id, installment: fee.installment),
      success: 'Pagamento desfeito.',
      failure: 'Não conseguimos desfazer o pagamento agora. Tente novamente.',
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required Key confirmKey,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: confirmKey,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PLANO E MENSALIDADES', style: adminLabelStyle),
        const SizedBox(height: 12),
        StreamBuilder<MembershipModel?>(
          stream: _membership,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Erro ao carregar plano do aluno: ${snapshot.error}');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bodyText('Não conseguimos carregar o plano agora.'),
                  TextButton(
                    key: const Key('botao_tentar_plano_aluno'),
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final membership = snapshot.data;
            if (membership == null) return _empty();
            return _details(membership);
          },
        ),
      ],
    );
  }

  Widget _bodyText(String text) => Text(
    text,
    style: GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.small,
      color: AppColors.textBody,
    ),
  );

  Widget _empty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bodyText('Este aluno ainda não tem plano.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('botao_atribuir_plano'),
          onPressed: _saving ? null : () => _assignPlan(null),
          icon: const Icon(Icons.add_card_outlined),
          label: const Text('Atribuir plano'),
        ),
      ],
    );
  }

  Widget _details(MembershipModel membership) {
    final now = widget.clock();
    final summary = summarizeMembership(membership, now);
    final fees = membershipFees(membership, now);
    final modalities = membership.modalities;
    final secondary = GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.caption,
      color: AppColors.textBody,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    key: const Key('nome_plano_aluno'),
                    style: GoogleFonts.barlowCondensed(
                      fontSize: AppFontSize.subtitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (modalities != null && modalities.isNotEmpty)
                    Text(modalities, style: secondary),
                  Text(
                    '${formatBrl(membership.monthlyPriceCents)}/mês · '
                    '${formatDateBr(membership.startDate)} a '
                    '${formatDateBr(summary.endDate)}',
                    style: secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MembershipStatusChip.standing(
              summary.standing,
              key: const Key('situacao_plano_aluno'),
            ),
          ],
        ),
        if (summary.overdueCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${summary.overdueCount} '
            '${summary.overdueCount == 1 ? 'mensalidade' : 'mensalidades'} '
            'em atraso · ${formatBrl(summary.overdueCents)}',
            style: GoogleFonts.barlowCondensed(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final fee in fees) _feeRow(membership, fee),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('botao_trocar_plano'),
                onPressed: _saving ? null : () => _assignPlan(membership),
                child: const Text('Trocar plano'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                key: const Key('botao_encerrar_plano'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: _saving ? null : () => _close(membership),
                child: const Text('Encerrar plano'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _feeRow(MembershipModel membership, MembershipFee fee) {
    final payment = fee.payment;
    return Container(
      key: Key('mensalidade_${fee.installment}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fee.installment}ª · vence ${formatDateBr(fee.dueDate)}',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  payment == null
                      ? formatBrl(fee.amountCents)
                      : '${formatBrl(payment.amountCents)} · pago em '
                          '${formatDateBr(payment.paidOn)} · '
                          '${paymentMethodLabel(payment.method)}',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          MembershipStatusChip.fee(fee.status),
          if (payment == null)
            IconButton(
              key: Key('botao_registrar_pagamento_${fee.installment}'),
              tooltip: 'Registrar pagamento',
              onPressed: _saving ? null : () => _recordPayment(membership, fee),
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),
            )
          else
            IconButton(
              key: Key('botao_desfazer_pagamento_${fee.installment}'),
              tooltip: 'Desfazer pagamento',
              onPressed: _saving ? null : () => _undoPayment(membership, fee),
              icon: const Icon(Icons.undo_rounded, color: AppColors.slateText),
            ),
        ],
      ),
    );
  }
}

class _AssignResult {
  final MembershipPlanModel plan;
  final DateTime startDate;

  const _AssignResult(this.plan, this.startDate);
}

class _AssignPlanDialog extends StatefulWidget {
  final Stream<List<MembershipPlanModel>> plans;
  final DateTime today;
  final MembershipModel? replacing;

  const _AssignPlanDialog({
    required this.plans,
    required this.today,
    required this.replacing,
  });

  @override
  State<_AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends State<_AssignPlanDialog> {
  String? _planId;
  List<MembershipPlanModel> _available = const [];

  MembershipPlanModel? get _plan {
    for (final plan in _available) {
      if (plan.id == _planId) return plan;
    }
    return null;
  }

  late DateTime _startDate = DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(widget.today.year - 1),
      lastDate: DateTime(widget.today.year + 1, 12, 31),
      helpText: 'Início do plano',
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.replacing == null ? 'Atribuir plano' : 'Trocar plano'),
      content: StreamBuilder<List<MembershipPlanModel>>(
        stream: widget.plans,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Erro ao carregar planos: ${snapshot.error}');
            return const Text('Não conseguimos carregar os planos agora.');
          }
          final plans = snapshot.data;
          if (plans == null) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (plans.isEmpty) {
            return const Text(
              'Nenhum plano no catálogo. Cadastre um em Início › Planos.',
            );
          }
          _available = plans;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('campo_plano_aluno'),
                isExpanded: true,
                initialValue: _plan?.id,
                decoration: const InputDecoration(labelText: 'Plano'),
                items: [
                  for (final plan in plans)
                    DropdownMenuItem(
                      value: plan.id,
                      child: Text(
                        '${plan.name} · ${formatBrl(plan.monthlyPriceCents)}'
                        '/mês · ${monthsLabel(plan.durationMonths)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (planId) => setState(() => _planId = planId),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('botao_data_inicio_plano'),
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('Início: ${formatDateBr(_startDate)}'),
              ),
              const SizedBox(height: 8),
              Text(
                'A 1ª mensalidade vence no início; as outras, no mesmo dia '
                'dos meses seguintes.',
                style: GoogleFonts.barlowCondensed(
                  fontSize: AppFontSize.caption,
                  color: AppColors.textBody,
                ),
              ),
              if (widget.replacing != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${widget.replacing!.planName} será encerrado e as '
                  'mensalidades em aberto dele deixam de ser cobradas.',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentText,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('botao_salvar_plano_aluno'),
          onPressed:
              _plan == null
                  ? null
                  : () =>
                      Navigator.pop(context, _AssignResult(_plan!, _startDate)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _PaymentResult {
  final DateTime paidOn;
  final PaymentMethod method;
  final int amountCents;

  const _PaymentResult(this.paidOn, this.method, this.amountCents);
}

class _PaymentDialog extends StatefulWidget {
  final MembershipFee fee;
  final DateTime today;

  const _PaymentDialog({required this.fee, required this.today});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _paidOn = DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day,
  );
  PaymentMethod _method = PaymentMethod.pix;
  late final TextEditingController _amount = TextEditingController(
    text: formatBrl(widget.fee.amountCents).replaceFirst(r'R$ ', ''),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(widget.today.year - 2),
      lastDate: DateTime(
        widget.today.year,
        widget.today.month,
        widget.today.day,
      ),
      helpText: 'Data do pagamento',
    );
    if (picked != null && mounted) setState(() => _paidOn = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _PaymentResult(_paidOn, _method, parseBrlToCents(_amount.text)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pagamento da ${widget.fee.installment}ª mensalidade'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vencimento: ${formatDateBr(widget.fee.dueDate)}',
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.small,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('botao_data_pagamento'),
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('Pago em ${formatDateBr(_paidOn)}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              key: const Key('campo_forma_pagamento'),
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
              ),
              items: [
                for (final method in PaymentMethod.values)
                  DropdownMenuItem(
                    value: method,
                    child: Text(paymentMethodLabel(method)),
                  ),
              ],
              onChanged:
                  (method) =>
                      setState(() => _method = method ?? PaymentMethod.pix),
            ),
            TextFormField(
              key: const Key('campo_valor_pagamento'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor pago',
                prefixText: r'R$ ',
              ),
              validator: (value) {
                final cents = parseBrlToCents(value ?? '');
                return cents == null || cents <= 0
                    ? 'Informe um valor, como 129,90.'
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('botao_confirmar_pagamento'),
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
