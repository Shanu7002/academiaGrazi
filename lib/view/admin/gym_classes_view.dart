import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/widgets/weekdays.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Grade de aulas cadastrada pelo admin. Somente informativa: não há
/// reserva nem controle de lotação nesta versão.
class GymClassesView extends StatefulWidget {
  const GymClassesView({super.key});

  @override
  State<GymClassesView> createState() => _GymClassesViewState();
}

class _GymClassesViewState extends State<GymClassesView> {
  final GymClassService _classService = locator<GymClassService>();
  final UnitService _unitService = locator<UnitService>();
  final AdminDashboardService _dashboardService =
      locator<AdminDashboardService>();

  late Stream<List<UnitModel>> _units;
  late Stream<List<GymClassModel>> _classes;
  List<InstructorWorkload> _instructors = const [];

  @override
  void initState() {
    super.initState();
    _subscribe();
    _loadInstructors();
  }

  void _subscribe() {
    _units = _unitService.streamUnits(includeInactive: true);
    _classes = _classService.streamClasses(includeInactive: true);
  }

  void _reload() => setState(_subscribe);

  /// Professores para o campo opcional "Professor". Se falhar, o campo
  /// oferece só "Sem professor" e os nomes não aparecem nos cards.
  Future<void> _loadInstructors() async {
    try {
      final team = await _dashboardService.getTeamWorkload();
      team.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() => _instructors = team);
    } catch (error) {
      debugPrint('Erro ao carregar professores da grade: $error');
    }
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
      debugPrint('Erro ao salvar aula: $error');
      if (!mounted) return;
      _showMessage('Não foi possível salvar a aula. Tente novamente.');
    }
  }

  Future<void> _openForm(List<UnitModel> units, {GymClassModel? item}) async {
    final activeUnits = units.where((unit) => unit.active).toList();
    if (activeUnits.isEmpty) {
      _showMessage('Cadastre um bloco ativo antes de criar aulas.');
      return;
    }
    final result = await showDialog<GymClassModel>(
      context: context,
      builder:
          (_) => _GymClassFormDialog(
            item: item,
            units: activeUnits,
            instructors: _instructors,
          ),
    );
    if (result == null || !mounted) return;

    if (item == null) {
      await _save(() => _classService.createClass(result), 'Aula cadastrada.');
    } else {
      await _save(() => _classService.updateClass(result), 'Aula atualizada.');
    }
  }

  Future<void> _toggleActive(GymClassModel item) async {
    if (item.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text('Retirar ${item.name} da grade?'),
              content: const Text(
                'A aula deixa de aparecer para os alunos. Você pode '
                'reativá-la depois.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  key: const Key('botao_confirmar_desativar_aula'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Retirar'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _save(
      () => _classService.setClassActive(item.id, active: !item.active),
      item.active ? 'Aula retirada da grade.' : 'Aula reativada.',
    );
  }

  Widget _error() {
    return _CenteredMessage(
      icon: Icons.cloud_off_outlined,
      text: 'Não foi possível carregar a grade de aulas.',
      action: TextButton(
        key: const Key('botao_tentar_aulas'),
        onPressed: _reload,
        child: const Text('Tentar novamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UnitModel>>(
      stream: _units,
      builder: (context, unitsSnapshot) {
        final units = unitsSnapshot.data;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const CustomAppBar(title: 'Aulas'),
          floatingActionButton:
              units == null
                  ? null
                  : FloatingActionButton.extended(
                    key: const Key('botao_nova_aula'),
                    onPressed: () => _openForm(units),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova aula'),
                  ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: StreamBuilder<List<GymClassModel>>(
                stream: _classes,
                builder: (context, classesSnapshot) {
                  if (unitsSnapshot.hasError || classesSnapshot.hasError) {
                    debugPrint(
                      'Erro ao carregar a grade: '
                      '${unitsSnapshot.error ?? classesSnapshot.error}',
                    );
                    return _error();
                  }
                  final classes = classesSnapshot.data;
                  if (units == null || classes == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (classes.isEmpty) {
                    return const _CenteredMessage(
                      icon: Icons.calendar_month,
                      text:
                          'Nenhuma aula na grade.\n'
                          'Toque em "Nova aula" para começar.',
                    );
                  }
                  return _classList(units, classes);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _classList(List<UnitModel> units, List<GymClassModel> classes) {
    final unitNames = {for (final unit in units) unit.id: unit.name};
    final instructorNames = {
      for (final instructor in _instructors) instructor.id: instructor.name,
    };
    final children = <Widget>[];
    int? currentDay;
    for (final item in classes) {
      if (item.weekday != currentDay) {
        currentDay = item.weekday;
        children.add(
          Padding(
            padding: EdgeInsets.only(top: children.isEmpty ? 0 : 20, bottom: 8),
            child: Text(
              weekdayName(item.weekday).toUpperCase(),
              style: GoogleFonts.barlowCondensed(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ClassCard(
            item: item,
            unitName: unitNames[item.unitId],
            instructorName:
                item.instructorId == null
                    ? null
                    : instructorNames[item.instructorId],
            onEdit: () => _openForm(units, item: item),
            onToggleActive: () => _toggleActive(item),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: children,
    );
  }
}

class _ClassCard extends StatelessWidget {
  final GymClassModel item;
  final String? unitName;
  final String? instructorName;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _ClassCard({
    required this.item,
    required this.unitName,
    required this.instructorName,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      '${item.durationMinutes} min',
      if (unitName != null) unitName!,
      if (instructorName != null && instructorName!.isNotEmpty) instructorName!,
      if (item.capacity != null) '${item.capacity} vagas',
    ].join(' · ');

    return Material(
      key: Key('card_aula_${item.id}'),
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
              Text(
                item.startTime,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      item.active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            item.active
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      details,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!item.active)
                      Text(
                        'Fora da grade',
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
                key: Key('botao_ativar_aula_${item.id}'),
                tooltip: item.active ? 'Retirar da grade' : 'Reativar aula',
                onPressed: onToggleActive,
                icon: Icon(
                  item.active ? Icons.toggle_on : Icons.toggle_off_outlined,
                  size: 32,
                  color: item.active ? AppColors.primary : AppColors.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GymClassFormDialog extends StatefulWidget {
  final GymClassModel? item;
  final List<UnitModel> units;
  final List<InstructorWorkload> instructors;

  const _GymClassFormDialog({
    required this.item,
    required this.units,
    required this.instructors,
  });

  @override
  State<_GymClassFormDialog> createState() => _GymClassFormDialogState();
}

class _GymClassFormDialogState extends State<_GymClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final MaskTextInputFormatter _timeMask;
  late final TextEditingController _name;
  late final TextEditingController _time;
  late final TextEditingController _duration;
  late final TextEditingController _capacity;
  late String? _unitId;
  late String? _instructorId;
  late int _weekday;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _time = TextEditingController(text: item?.startTime ?? '');
    // A máscara precisa conhecer o horário já preenchido ao editar; sem
    // isso, digitar por cima embaralha os dígitos.
    _timeMask = MaskTextInputFormatter(
      mask: '##:##',
      initialText: item?.startTime,
    );
    _duration = TextEditingController(
      text: item == null ? '60' : '${item.durationMinutes}',
    );
    _capacity = TextEditingController(
      text: item?.capacity == null ? '' : '${item!.capacity}',
    );
    final unitIds = widget.units.map((unit) => unit.id).toSet();
    // Um bloco desativado não é oferecido: a aula precisa escolher outro.
    _unitId =
        item != null && unitIds.contains(item.unitId)
            ? item.unitId
            : (widget.units.length == 1 ? widget.units.first.id : null);
    final instructorIds = widget.instructors.map((i) => i.id).toSet();
    _instructorId =
        instructorIds.contains(item?.instructorId) ? item?.instructorId : null;
    _weekday = item?.weekday ?? DateTime.monday;
  }

  @override
  void dispose() {
    _name.dispose();
    _time.dispose();
    _duration.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final capacity = _capacity.text.trim();
    Navigator.pop(
      context,
      GymClassModel(
        id: widget.item?.id ?? '',
        name: _name.text.trim(),
        unitId: _unitId!,
        instructorId: _instructorId,
        weekday: _weekday,
        startTime: _time.text.trim(),
        durationMinutes: int.parse(_duration.text.trim()),
        capacity: capacity.isEmpty ? null : int.parse(capacity),
        active: widget.item?.active ?? true,
      ),
    );
  }

  static String? _positiveInt(String? value, {required bool required}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return required ? 'Obrigatório.' : null;
    final number = int.tryParse(text);
    return number == null || number <= 0
        ? 'Informe um número maior que 0.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Nova aula' : 'Editar aula'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('campo_nome_aula'),
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Modalidade (ex.: Spinning)',
                ),
                validator:
                    (value) =>
                        (value ?? '').trim().isEmpty
                            ? 'Informe a modalidade.'
                            : null,
              ),
              DropdownButtonFormField<String>(
                key: const Key('campo_bloco_aula'),
                initialValue: _unitId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bloco'),
                items: [
                  for (final unit in widget.units)
                    DropdownMenuItem(value: unit.id, child: Text(unit.name)),
                ],
                onChanged: (value) => setState(() => _unitId = value),
                validator: (value) => value == null ? 'Escolha o bloco.' : null,
              ),
              DropdownButtonFormField<String?>(
                key: const Key('campo_professor_aula'),
                initialValue: _instructorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Professor (opcional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sem professor'),
                  ),
                  for (final instructor in widget.instructors)
                    DropdownMenuItem<String?>(
                      value: instructor.id,
                      child: Text(instructor.name),
                    ),
                ],
                onChanged: (value) => setState(() => _instructorId = value),
              ),
              DropdownButtonFormField<int>(
                key: const Key('campo_dia_aula'),
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    DropdownMenuItem(value: day, child: Text(weekdayName(day))),
                ],
                onChanged:
                    (value) =>
                        setState(() => _weekday = value ?? DateTime.monday),
              ),
              TextFormField(
                key: const Key('campo_horario_aula'),
                controller: _time,
                keyboardType: TextInputType.number,
                inputFormatters: [_timeMask],
                decoration: const InputDecoration(
                  labelText: 'Início',
                  hintText: 'HH:mm',
                ),
                validator:
                    (value) =>
                        InstructorShiftModel.minutesOf((value ?? '').trim()) ==
                                null
                            ? 'Use o formato HH:mm (ex.: 19:00).'
                            : null,
              ),
              TextFormField(
                key: const Key('campo_duracao_aula'),
                controller: _duration,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos)',
                ),
                validator: (value) => _positiveInt(value, required: true),
              ),
              TextFormField(
                key: const Key('campo_vagas_aula'),
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Vagas (opcional, só informativo)',
                ),
                validator: (value) => _positiveInt(value, required: false),
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
          key: const Key('botao_salvar_aula'),
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
