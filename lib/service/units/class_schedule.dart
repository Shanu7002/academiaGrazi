import 'package:academiagrazi/models/units/gym_class_model.dart';

/// Próxima aula da grade e a data e hora (locais) em que ela começa.
typedef UpcomingGymClass = ({GymClassModel gymClass, DateTime startsAt});

/// Primeira aula ativa da grade semanal a começar depois de [now] (horário
/// local da academia), virando a semana se preciso (domingo → segunda).
///
/// Uma aula que começa exatamente em [now] já está acontecendo e não conta.
/// Aulas inativas ou inválidas são ignoradas; sem aula, devolve null.
UpcomingGymClass? nextGymClass(Iterable<GymClassModel> classes, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  UpcomingGymClass? next;
  for (final gymClass in classes) {
    if (!gymClass.active || !gymClass.isValid) continue;
    var days = (gymClass.weekday - now.weekday) % DateTime.daysPerWeek;
    var startsAt = _at(today, days, gymClass.startMinutes);
    if (!startsAt.isAfter(now)) {
      days += DateTime.daysPerWeek;
      startsAt = _at(today, days, gymClass.startMinutes);
    }
    if (next == null || startsAt.isBefore(next.startsAt)) {
      next = (gymClass: gymClass, startsAt: startsAt);
    }
  }
  return next;
}

// Soma dias pelo calendário (não por 24 h), para não errar o horário em
// mudanças de horário de verão.
DateTime _at(DateTime day, int plusDays, int minuteOfDay) => DateTime(
  day.year,
  day.month,
  day.day + plusDays,
  minuteOfDay ~/ 60,
  minuteOfDay % 60,
);
