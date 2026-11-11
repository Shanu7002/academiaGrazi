import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Blocos (unidades) da academia: listagem, criação, edição e desativação.
///
/// Bloco não é apagado: desativado, some das listas de escolha, mas continua
/// ligado aos alunos e turnos que já apontam para ele.
class UnitsView extends StatefulWidget {
  const UnitsView({super.key});

  @override
  State<UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<UnitsView> {
  final UnitService _service = locator<UnitService>();
  late Stream<List<UnitModel>> _units;

  @override
  void initState() {
    super.initState();
    _units = _service.streamUnits(includeInactive: true);
  }

  void _reload() {
    setState(() {
      _units = _service.streamUnits(includeInactive: true);
    });
  }

  void _showMessage(String message) {
    // Substitui o aviso anterior em vez de entrar na fila.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Executa a gravação e traduz a falha em uma mensagem pt-BR.
  Future<bool> _save(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return true;
      _showMessage(success);
      return true;
    } catch (error) {
      debugPrint('Erro ao salvar bloco: $error');
      if (!mounted) return false;
      _showMessage('Não foi possível salvar o bloco. Tente novamente.');
      return false;
    }
  }

  Future<void> _openForm({UnitModel? unit}) async {
    final result = await showDialog<_UnitFormResult>(
      context: context,
      builder: (_) => _UnitFormDialog(unit: unit),
    );
    if (result == null || !mounted) return;

    if (unit == null) {
      await _save(
        () => _service.createUnit(name: result.name, address: result.address),
        'Bloco cadastrado.',
      );
    } else {
      await _save(
        () => _service.updateUnit(
          unit.id,
          name: result.name,
          address: result.address,
        ),
        'Bloco atualizado.',
      );
    }
  }

  Future<void> _toggleActive(UnitModel unit) async {
    if (unit.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text('Desativar ${unit.name}?'),
              content: const Text(
                'O bloco deixa de aparecer nas escolhas de alunos e escala. '
                'Os vínculos atuais são mantidos e você pode reativá-lo '
                'depois.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const Key('botao_confirmar_desativar_bloco'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Desativar'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
    }

    await _save(
      () => _service.setUnitActive(unit.id, active: !unit.active),
      unit.active ? 'Bloco desativado.' : 'Bloco reativado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Blocos'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('botao_novo_bloco'),
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo bloco'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<List<UnitModel>>(
            stream: _units,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Erro ao carregar blocos: ${snapshot.error}');
                return _CenteredMessage(
                  icon: Icons.cloud_off_outlined,
                  text: 'Não foi possível carregar os blocos.',
                  action: TextButton(
                    key: const Key('botao_tentar_blocos'),
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }
              final units = snapshot.data;
              if (units == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (units.isEmpty) {
                return const _CenteredMessage(
                  icon: Icons.grid_view_rounded,
                  text:
                      'Nenhum bloco cadastrado.\n'
                      'Toque em "Novo bloco" para começar.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder:
                    (_, index) => _UnitCard(
                      unit: units[index],
                      onEdit: () => _openForm(unit: units[index]),
                      onToggleActive: () => _toggleActive(units[index]),
                    ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final address = unit.address;
    return Material(
      key: Key('card_bloco_${unit.id}'),
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
                Icons.grid_view_rounded,
                color: unit.active ? AppColors.primary : AppColors.inactive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            unit.active
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                    if (address != null && address.isNotEmpty)
                      Text(
                        address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (!unit.active)
                      Text(
                        'Desativado',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: Key('botao_ativar_bloco_${unit.id}'),
                tooltip: unit.active ? 'Desativar bloco' : 'Reativar bloco',
                onPressed: onToggleActive,
                icon: Icon(
                  unit.active ? Icons.toggle_on : Icons.toggle_off_outlined,
                  size: 32,
                  color: unit.active ? AppColors.primary : AppColors.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitFormResult {
  final String name;
  final String? address;

  const _UnitFormResult(this.name, this.address);
}

class _UnitFormDialog extends StatefulWidget {
  final UnitModel? unit;

  const _UnitFormDialog({this.unit});

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.unit?.name ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.unit?.address ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = _address.text.trim();
    Navigator.pop(
      context,
      _UnitFormResult(_name.text.trim(), address.isEmpty ? null : address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.unit == null ? 'Novo bloco' : 'Editar bloco'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('campo_nome_bloco'),
              controller: _name,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator:
                  (value) =>
                      (value ?? '').trim().isEmpty
                          ? 'Informe o nome do bloco.'
                          : null,
            ),
            TextFormField(
              key: const Key('campo_endereco_bloco'),
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Endereço (opcional)',
              ),
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
          key: const Key('botao_salvar_bloco'),
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
              style: GoogleFonts.inter(
                fontSize: 14,
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
