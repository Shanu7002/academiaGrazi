import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:academiagrazi/service/units/shift_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

InstructorShiftModel turno(
  String id,
  int weekday,
  String startTime,
  String endTime,
) {
  return InstructorShiftModel(
    id: id,
    instructorId: 'prof-1',
    unitId: 'unidade-$id',
    weekday: weekday,
    startTime: startTime,
    endTime: endTime,
  );
}

void main() {
  // 2026-11-09 é uma segunda-feira; 2026-11-15, um domingo.
  final segundaManha = turno('seg-manha', DateTime.monday, '07:00', '11:00');
  final segundaTarde = turno('seg-tarde', DateTime.monday, '14:00', '18:00');
  final quarta = turno('quarta', DateTime.wednesday, '08:00', '12:00');
  final escala = [quarta, segundaTarde, segundaManha];

  test('dentro do turno devolve o atual e o próximo do mesmo dia', () {
    final agenda = currentAndNextShift(escala, DateTime(2026, 11, 9, 9, 30));

    expect(agenda.current?.id, 'seg-manha');
    expect(agenda.next?.id, 'seg-tarde');
    expect(agenda.nextStartsAt, DateTime(2026, 11, 9, 14));
  });

  test('entre turnos não há atual e o próximo é o seguinte da semana', () {
    final agenda = currentAndNextShift(escala, DateTime(2026, 11, 9, 19));

    expect(agenda.current, isNull);
    expect(agenda.next?.id, 'quarta');
    expect(agenda.nextStartsAt, DateTime(2026, 11, 11, 8));
  });

  test('no domingo o próximo turno vira a semana para segunda', () {
    final agenda = currentAndNextShift(escala, DateTime(2026, 11, 15, 20));

    expect(agenda.current, isNull);
    expect(agenda.next?.id, 'seg-manha');
    expect(agenda.nextStartsAt, DateTime(2026, 11, 16, 7));
  });

  test('turno de domingo é o atual e a segunda é o próximo', () {
    final domingo = turno('domingo', DateTime.sunday, '08:00', '12:00');
    final agenda = currentAndNextShift(
      [domingo, segundaManha],
      DateTime(2026, 11, 15, 10),
    );

    expect(agenda.current?.id, 'domingo');
    expect(agenda.next?.id, 'seg-manha');
    expect(agenda.nextStartsAt, DateTime(2026, 11, 16, 7));
  });

  test('sem escala não há turno atual nem próximo', () {
    final agenda = currentAndNextShift(const [], DateTime(2026, 11, 9, 9));

    expect(agenda.current, isNull);
    expect(agenda.next, isNull);
    expect(agenda.nextStartsAt, isNull);
  });

  test('o fim do turno não conta como dentro dele', () {
    final agenda = currentAndNextShift(escala, DateTime(2026, 11, 9, 11));

    expect(agenda.current, isNull);
    expect(agenda.next?.id, 'seg-tarde');
  });

  test('turno que começa agora é o atual; o próximo é outro', () {
    final agenda = currentAndNextShift(escala, DateTime(2026, 11, 9, 7));

    expect(agenda.current?.id, 'seg-manha');
    expect(agenda.next?.id, 'seg-tarde');
  });

  test('com um único turno, o próximo é ele mesmo na semana seguinte', () {
    final agenda = currentAndNextShift(
      [segundaManha],
      DateTime(2026, 11, 9, 8),
    );

    expect(agenda.current?.id, 'seg-manha');
    expect(agenda.next?.id, 'seg-manha');
    expect(agenda.nextStartsAt, DateTime(2026, 11, 16, 7));
  });

  test('com turnos sobrepostos, o atual é o que começou primeiro', () {
    final cedo = turno('cedo', DateTime.monday, '06:00', '10:00');
    final agenda = currentAndNextShift(
      [segundaManha, cedo],
      DateTime(2026, 11, 9, 8),
    );

    expect(agenda.current?.id, 'cedo');
  });

  test('ignora turnos inválidos', () {
    final invertido = turno('invertido', DateTime.monday, '12:00', '08:00');
    final agenda = currentAndNextShift(
      [invertido],
      DateTime(2026, 11, 9, 9),
    );

    expect(agenda.current, isNull);
    expect(agenda.next, isNull);
  });
}
