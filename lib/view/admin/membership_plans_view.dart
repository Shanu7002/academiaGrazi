import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/memberships/membership_plan_model.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:academiagrazi/service/memberships/money.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/membership_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Catálogo de planos da academia: listagem, criação, edição e retirada.
///
/// Plano não é apagado: retirado do catálogo, deixa de ser oferecido, mas os
/// alunos que já o têm continuam com ele (cada aluno guarda uma cópia).
class MembershipPlansView extends StatefulWidget {
  const MembershipPlansView({super.key});

  @override
  State<MembershipPlansView> createState() => _MembershipPlansViewState();
}

class _MembershipPlansViewState extends State<MembershipPlansView> {
  final MembershipService _service = locator<MembershipService>();
  late Stream<List<MembershipPlanModel>> _plans;

  @override
  void initState() {
    super.initState();
    _plans = _service.streamPlans(includeInactive: true);
  }

  void _reload() {
    setState(() {
      _plans = _service.streamPlans(includeInactive: true);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(success);
    } catch (error) {
      debugPrint('Erro ao salvar plano: $error');
      if (!mounted) return;
      _showMessage('Não conseguimos salvar o plano agora. Tente novamente.');
    }
  }

  Future<void> _openForm({MembershipPlanModel? plan}) async {
    final result = await showDialog<_PlanFormResult>(
      context: context,
      builder: (_) => _PlanFormDialog(plan: plan),
    );
    if (result == null || !mounted) return;

    if (plan == null) {
      await _save(
        () => _service.createPlan(
          name: result.name,
          monthlyPriceCents: result.monthlyPriceCents,
          durationMonths: result.durationMonths,
          modalities: result.modalities,
        ),
        'Plano cadastrado.',
      );
    } else {
      await _save(
        () => _service.updatePlan(
          plan.id,
          name: result.name,
          monthlyPriceCents: result.monthlyPriceCents,
          durationMonths: result.durationMonths,
          modalities: result.modalities,
        ),
        'Plano atualizado.',
      );
    }
  }

  Future<void> _toggleActive(MembershipPlanModel plan) async {
    if (plan.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text('Retirar ${plan.name} do catálogo?'),
              content: const Text(
                'O plano deixa de ser oferecido para novos alunos. Quem já '
                'tem este plano continua com ele, e você pode reativá-lo '
                'depois.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const Key('botao_confirmar_retirar_plano'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Retirar'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
    }

    await _save(
      () => _service.setPlanActive(plan.id, active: !plan.active),
      plan.active ? 'Plano retirado do catálogo.' : 'Plano reativado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Planos'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('botao_novo_plano'),
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo plano'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<List<MembershipPlanModel>>(
            stream: _plans,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Erro ao carregar planos: ${snapshot.error}');
                return _CenteredMessage(
                  icon: Icons.cloud_off_outlined,
                  text: 'Não conseguimos carregar os planos agora.',
                  action: TextButton(
                    key: const Key('botao_tentar_planos'),
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }
              final plans = snapshot.data;
              if (plans == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (plans.isEmpty) {
                return const _CenteredMessage(
                  icon: Icons.card_membership_outlined,
                  text:
                      'Nenhum plano cadastrado.\n'
                      'Toque em "Novo plano" para montar o catálogo.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder:
                    (_, index) => _PlanCard(
                      plan: plans[index],
                      onEdit: () => _openForm(plan: plans[index]),
                      onToggleActive: () => _toggleActive(plans[index]),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final modalities = plan.modalities;
    final secondary = GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.caption,
      color: AppColors.textSecondary,
    );
    return Material(
      key: Key('card_plano_${plan.id}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Icon(
                Icons.card_membership_outlined,
                color: plan.active ? AppColors.primary : AppColors.inactive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w700,
                        color:
                            plan.active
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${formatBrl(plan.monthlyPriceCents)}/mês · '
                      '${monthsLabel(plan.durationMonths)}',
                      style: secondary,
                    ),
                    if (modalities != null && modalities.isNotEmpty)
                      Text(modalities, style: secondary),
                    if (!plan.active)
                      Text(
                        'Fora do catálogo',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: Key('botao_ativar_plano_${plan.id}'),
                tooltip: plan.active ? 'Retirar do catálogo' : 'Reativar plano',
                onPressed: onToggleActive,
                icon: Icon(
                  plan.active ? Icons.toggle_on : Icons.toggle_off_outlined,
                  size: 32,
                  color: plan.active ? AppColors.primary : AppColors.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanFormResult {
  final String name;
  final int monthlyPriceCents;
  final int durationMonths;
  final String? modalities;

  const _PlanFormResult({
    required this.name,
    required this.monthlyPriceCents,
    required this.durationMonths,
    required this.modalities,
  });
}

class _PlanFormDialog extends StatefulWidget {
  final MembershipPlanModel? plan;

  const _PlanFormDialog({this.plan});

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.plan?.name ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text:
        widget.plan == null
            ? ''
            : formatBrl(
              widget.plan!.monthlyPriceCents,
            ).replaceFirst(r'R$ ', ''),
  );
  late final TextEditingController _duration = TextEditingController(
    text: widget.plan?.durationMonths.toString() ?? '',
  );
  late final TextEditingController _modalities = TextEditingController(
    text: widget.plan?.modalities ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _modalities.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final modalities = _modalities.text.trim();
    Navigator.pop(
      context,
      _PlanFormResult(
        name: _name.text.trim(),
        monthlyPriceCents: parseBrlToCents(_price.text)!,
        durationMonths: int.parse(_duration.text.trim()),
        modalities: modalities.isEmpty ? null : modalities,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? 'Novo plano' : 'Editar plano'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('campo_nome_plano'),
                controller: _name,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator:
                    (value) =>
                        (value ?? '').trim().isEmpty
                            ? 'Informe o nome do plano.'
                            : null,
              ),
              TextFormField(
                key: const Key('campo_valor_plano'),
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor da mensalidade',
                  prefixText: r'R$ ',
                  hintText: '129,90',
                ),
                validator: (value) {
                  final cents = parseBrlToCents(value ?? '');
                  return cents == null || cents <= 0
                      ? 'Informe um valor, como 129,90.'
                      : null;
                },
              ),
              TextFormField(
                key: const Key('campo_duracao_plano'),
                controller: _duration,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Duração (meses)',
                  helperText: 'Uma mensalidade por mês.',
                ),
                validator: (value) {
                  final months = int.tryParse((value ?? '').trim());
                  return months == null ||
                          months < 1 ||
                          months > MembershipService.maxDurationMonths
                      ? 'Informe de 1 a '
                          '${MembershipService.maxDurationMonths} meses.'
                      : null;
                },
              ),
              TextFormField(
                key: const Key('campo_modalidades_plano'),
                controller: _modalities,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Modalidades (opcional)',
                  hintText: 'Musculação + Pilates',
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('botao_salvar_plano'),
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _CenteredMessage({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.small,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
