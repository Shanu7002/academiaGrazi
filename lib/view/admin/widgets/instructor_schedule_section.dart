import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/shift_schedule.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/weekdays.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Texto de um turno, ex.: "Segunda · 07:00–11:00 · Bloco A".
String _describe(InstructorShiftModel shift, String? unitName) => [
  weekdayName(shift.weekday),
  '${shift.startTime}–${shift.endTime}',
  if (unitName != null) unitName,
].join(' · ');

/// Seção "Escala" dos detalhes do professor: o admin inclui e remove os
/// turnos (bloco, dia e horário). Turnos sobrepostos são recusados.
class InstructorScheduleSection extends StatefulWidget {
  final String instructorId;

  const InstructorScheduleSection({super.key, required this.instructorId});

  @override
  State<InstructorScheduleSection> createState() =>
      _InstructorScheduleSectionState();
}

class _InstructorScheduleSectionState extends State<InstructorScheduleSection> {
  final InstructorShiftService _shiftService =
      locator<InstructorShiftService>();
  final UnitService _unitService = locator<UnitService>();

  late Stream<List<InstructorShiftModel>> _shifts;
  late Stream<List<UnitModel>> _units;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _shifts = _shiftService.streamShiftsForInstructor(widget.instructorId);
    _units = _unitService.streamUnits(includeInactive: true);
  }

  void _reload() => setState(_subscribe);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add(
    List<InstructorShiftModel> shifts,
    List<UnitModel> units,
  ) async {
    final activeUnits = units.where((unit) => unit.active).toList();
    if (activeUnits.isEmpty) {
      _showMessage('Cadastre um bloco ativo antes de montar a escala.');
      return;
    }
    final unitNames = {for (final unit in units) unit.id: unit.name};
    final shift = await showDialog<InstructorShiftModel>(
      context: context,
      builder:
          (_) => _ShiftFormDialog(
            instructorId: widget.instructorId,
            units: activeUnits,
            existing: shifts,
            unitNames: unitNames,
          ),
    );
    if (shift == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await _shiftService.addShift(
        instructorId: shift.instructorId,
        unitId: shift.unitId,
        weekday: shift.weekday,
        startTime: shift.startTime,
        endTime: shift.endTime,
      );
      if (!mounted) return;
      _showMessage('Turno adicionado à escala.');
    } on ShiftOverlapException catch (error) {
      // Outro admin pode ter incluído um turno depois de o diálogo abrir.
      if (!mounted) return;
      _showMessage(
        'Este turno se sobrepõe a '
        '${_describe(error.conflict, unitNames[error.conflict.unitId])}.',
      );
    } catch (error) {
      debugPrint('Erro ao adicionar turno: $error');
      if (!mounted) return;
      _showMessage('Não foi possível adicionar o turno. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(InstructorShiftModel shift, String? unitName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Remover turno?'),
            content: Text(_describe(shift, unitName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('botao_confirmar_remover_turno'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await _shiftService.deleteShift(shift.id);
      if (!mounted) return;
      _showMessage('Turno removido da escala.');
    } catch (error) {
      debugPrint('Erro ao remover turno: $error');
      if (!mounted) return;
      _showMessage('Não foi possível remover o turno. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('secao_escala'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTranslucent),
      ),
      child: StreamBuilder<List<UnitModel>>(
        stream: _units,
        builder: (context, unitsSnapshot) {
          return StreamBuilder<List<InstructorShiftModel>>(
            stream: _shifts,
            builder: (context, shiftsSnapshot) {
              final error = unitsSnapshot.error ?? shiftsSnapshot.error;
              final units = unitsSnapshot.data;
              final shifts = shiftsSnapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Escala',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      if (units != null && shifts != null)
                        TextButton.icon(
                          key: const Key('botao_adicionar_turno'),
                          onPressed: _saving ? null : () => _add(shifts, units),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar turno'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (error != null)
                    _errorState(error)
                  else if (units == null || shifts == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (shifts.isEmpty)
                    Text(
                      'Nenhum turno na escala deste professor.',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.small,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (final shift in shifts)
                      _ShiftTile(
                        shift: shift,
                        unitName:
                            {for (final unit in units) unit.id: unit.name}[shift
                                .unitId],
                        onRemove:
                            _saving
                                ? null
                                : () => _remove(
                                  shift,
                                  units
                                      .where((u) => u.id == shift.unitId)
                                      .firstOrNull
                                      ?.name,
                                ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorState(Object error) {
    debugPrint('Erro ao carregar escala: $error');
    return Column(
      children: [
        Text(
          'Não foi possível carregar a escala.',
          style: GoogleFonts.barlowCondensed(
            fontSize: AppFontSize.small,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          key: const Key('botao_tentar_escala'),
          onPressed: _reload,
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final InstructorShiftModel shift;
  final String? unitName;
  final VoidCallback? onRemove;

  const _ShiftTile({
    required this.shift,
    required this.unitName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('turno_${shift.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weekdayName(shift.weekday)} · '
                  '${shift.startTime}–${shift.endTime}',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  unitName ?? 'Bloco removido',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('botao_remover_turno_${shift.id}'),
            tooltip: 'Remover turno',
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ShiftFormDialog extends StatefulWidget {
  final String instructorId;
  final List<UnitModel> units;
  final List<InstructorShiftModel> existing;
  final Map<String, String> unitNames;

  const _ShiftFormDialog({
    required this.instructorId,
    required this.units,
    required this.existing,
    required this.unitNames,
  });

  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _startMask = MaskTextInputFormatter(mask: '##:##');
  final _endMask = MaskTextInputFormatter(mask: '##:##');
  late String? _unitId =
      widget.units.length == 1 ? widget.units.first.id : null;
  int _weekday = DateTime.monday;
  String? _overlap;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  static String? _validTime(String? value) =>
      InstructorShiftModel.minutesOf((value ?? '').trim()) == null
          ? 'Use HH:mm (ex.: 07:00).'
          : null;

  void _submit() {
    setState(() => _overlap = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final shift = InstructorShiftModel(
      id: '',
      instructorId: widget.instructorId,
      unitId: _unitId!,
      weekday: _weekday,
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
    );
    final conflict = findOverlappingShift(widget.existing, shift);
    if (conflict != null) {
      setState(() {
        _overlap =
            'Este turno se sobrepõe a '
            '${_describe(conflict, widget.unitNames[conflict.unitId])}.';
      });
      return;
    }
    Navigator.pop(context, shift);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo turno'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('campo_bloco_turno'),
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
              DropdownButtonFormField<int>(
                key: const Key('campo_dia_turno'),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('campo_inicio_turno'),
                      controller: _start,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_startMask],
                      decoration: const InputDecoration(
                        labelText: 'Início',
                        hintText: 'HH:mm',
                      ),
                      validator: _validTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('campo_fim_turno'),
                      controller: _end,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_endMask],
                      decoration: const InputDecoration(
                        labelText: 'Fim',
                        hintText: 'HH:mm',
                      ),
                      validator: (value) {
                        final invalid = _validTime(value);
                        if (invalid != null) return invalid;
                        final start = InstructorShiftModel.minutesOf(
                          _start.text.trim(),
                        );
                        final end = InstructorShiftModel.minutesOf(
                          (value ?? '').trim(),
                        );
                        return start != null && end! <= start
                            ? 'O fim deve ser depois do início.'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              if (_overlap != null) ...[
                const SizedBox(height: 12),
                Text(
                  _overlap!,
                  key: const Key('erro_sobreposicao_turno'),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],
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
          key: const Key('botao_salvar_turno'),
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
