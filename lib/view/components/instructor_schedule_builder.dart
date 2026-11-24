import 'dart:async';

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/shift_schedule.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/components/weekdays.dart';
import 'package:flutter/material.dart';

/// Escala do professor já resolvida para a tela.
class InstructorScheduleSnapshot {
  final bool loading;
  final bool hasError;
  final ShiftSchedule schedule;
  final Map<String, String> unitNames;
  final DateTime now;

  const InstructorScheduleSnapshot({
    required this.loading,
    required this.hasError,
    required this.schedule,
    required this.unitNames,
    required this.now,
  });

  String unitName(InstructorShiftModel shift) =>
      unitNames[shift.unitId] ?? 'Bloco removido';

  /// Linha do cabeçalho: "Bloco atual: Bloco A (07:00–11:00)".
  String get currentLabel {
    if (loading) return 'Carregando escala...';
    if (hasError) return 'Escala indisponível no momento';
    final current = schedule.current;
    if (current == null) return 'Sem turno agora';
    return 'Bloco atual: ${unitName(current)} '
        '(${current.startTime}–${current.endTime})';
  }

  /// Bloco do próximo turno, ou um aviso sem escala.
  String get nextUnitLabel {
    if (loading) return '...';
    if (hasError) return '--';
    final next = schedule.next;
    return next == null ? 'Sem escala' : unitName(next);
  }

  /// Quando começa o próximo turno: "Hoje às 14:00", "Amanhã às 07:00"…
  String get nextWhenLabel {
    if (loading || hasError) return '';
    final startsAt = schedule.nextStartsAt;
    return startsAt == null
        ? 'Nenhum turno cadastrado'
        : nextShiftWhen(startsAt, now);
  }
}

/// "Hoje às HH:mm", "Amanhã às HH:mm" ou o dia da semana ("Quarta às
/// HH:mm") para os próximos dias.
String nextShiftWhen(DateTime startsAt, DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  final time = '${two(startsAt.hour)}:${two(startsAt.minute)}';
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(startsAt.year, startsAt.month, startsAt.day);
  final days = day.difference(today).inDays;
  if (days == 0) return 'Hoje às $time';
  if (days == 1) return 'Amanhã às $time';
  return '${weekdayName(startsAt.weekday)} às $time';
}

/// Lê a escala do professor e os nomes dos blocos e recalcula o turno atual
/// a cada minuto. Sem os services no locator (testes isolados), mostra
/// "sem turno", como o `CustomAppBar` faz com a foto.
class InstructorScheduleBuilder extends StatefulWidget {
  final String? instructorId;
  final Widget Function(BuildContext context, InstructorScheduleSnapshot data)
  builder;

  /// Relógio injetável para testes.
  final DateTime Function() clock;

  const InstructorScheduleBuilder({
    super.key,
    required this.instructorId,
    required this.builder,
    this.clock = DateTime.now,
  });

  @override
  State<InstructorScheduleBuilder> createState() =>
      _InstructorScheduleBuilderState();
}

class _InstructorScheduleBuilderState extends State<InstructorScheduleBuilder> {
  Stream<List<InstructorShiftModel>>? _shifts;
  Stream<List<UnitModel>>? _units;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final id = widget.instructorId;
    if (id != null &&
        locator.isRegistered<InstructorShiftService>() &&
        locator.isRegistered<UnitService>()) {
      _shifts = locator<InstructorShiftService>().streamShiftsForInstructor(id);
      _units = locator<UnitService>().streamUnits(includeInactive: true);
    }
    // O turno atual muda com o relógio, não só com o banco.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UnitModel>>(
      stream: _units,
      builder: (context, unitsSnapshot) {
        return StreamBuilder<List<InstructorShiftModel>>(
          stream: _shifts,
          builder: (context, shiftsSnapshot) {
            final error = unitsSnapshot.error ?? shiftsSnapshot.error;
            if (error != null) {
              debugPrint('Erro ao carregar a escala: $error');
            }
            final available = _shifts != null;
            final now = widget.clock();
            return widget.builder(
              context,
              InstructorScheduleSnapshot(
                loading:
                    available &&
                    error == null &&
                    (shiftsSnapshot.data == null || unitsSnapshot.data == null),
                hasError: error != null,
                schedule: currentAndNextShift(
                  shiftsSnapshot.data ?? const [],
                  now,
                ),
                unitNames: {
                  for (final unit in unitsSnapshot.data ?? const <UnitModel>[])
                    unit.id: unit.name,
                },
                now: now,
              ),
            );
          },
        );
      },
    );
  }
}
