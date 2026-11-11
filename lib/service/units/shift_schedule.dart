import 'package:academiagrazi/models/units/instructor_shift_model.dart';

/// Turno em que o professor está agora e o próximo a começar.
class ShiftSchedule {
  final InstructorShiftModel? current;
  final InstructorShiftModel? next;

  /// Data e hora (locais) em que [next] começa.
  final DateTime? nextStartsAt;

  const ShiftSchedule({this.current, this.next, this.nextStartsAt});
}

const int _minutesPerDay = 24 * 60;
const int _minutesPerWeek = 7 * _minutesPerDay;

int _minuteOfWeek(int weekday, int minuteOfDay) =>
    (weekday - DateTime.monday) * _minutesPerDay + minuteOfDay;

/// Turno atual e próximo da escala semanal, a partir de [now] (horário
/// local da academia, o mesmo dos turnos).
///
/// - **Atual:** o turno com início ≤ [now] < fim. Havendo sobreposição,
///   fica o que começou primeiro.
/// - **Próximo:** o primeiro turno a começar depois de [now], virando a
///   semana se preciso (domingo → segunda). Se a escala tem um único turno,
///   o próximo é ele mesmo na semana seguinte.
///
/// Turnos inválidos (ver [InstructorShiftModel.isValid]) são ignorados.
ShiftSchedule currentAndNextShift(
  Iterable<InstructorShiftModel> shifts,
  DateTime now,
) {
  final nowMinute = _minuteOfWeek(now.weekday, now.hour * 60 + now.minute);

  InstructorShiftModel? current;
  int? currentStart;
  InstructorShiftModel? next;
  int? nextDelta;

  for (final shift in shifts) {
    if (!shift.isValid) continue;
    final start = _minuteOfWeek(shift.weekday, shift.startMinutes);
    final end = _minuteOfWeek(shift.weekday, shift.endMinutes);

    if (start <= nowMinute &&
        nowMinute < end &&
        (currentStart == null || start < currentStart)) {
      current = shift;
      currentStart = start;
    }

    // Minutos até o próximo início; começar agora conta como semana que vem.
    var delta = (start - nowMinute) % _minutesPerWeek;
    if (delta == 0) delta = _minutesPerWeek;
    if (nextDelta == null || delta < nextDelta) {
      next = shift;
      nextDelta = delta;
    }
  }

  final startOfMinute = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  );
  return ShiftSchedule(
    current: current,
    next: next,
    nextStartsAt:
        nextDelta == null
            ? null
            : startOfMinute.add(Duration(minutes: nextDelta)),
  );
}
