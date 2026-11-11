import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  InstructorShiftModel turno({
    int weekday = DateTime.monday,
    String startTime = '07:00',
    String endTime = '11:30',
    String instructorId = 'prof-1',
    String unitId = 'unidade-1',
  }) => InstructorShiftModel(
    id: 't1',
    instructorId: instructorId,
    unitId: unitId,
    weekday: weekday,
    startTime: startTime,
    endTime: endTime,
  );

  test('converte HH:mm em minutos e recusa horários inválidos', () {
    expect(InstructorShiftModel.minutesOf('00:00'), 0);
    expect(InstructorShiftModel.minutesOf('07:30'), 450);
    expect(InstructorShiftModel.minutesOf('23:59'), 1439);
    expect(InstructorShiftModel.minutesOf('24:00'), isNull);
    expect(InstructorShiftModel.minutesOf('7:30'), isNull);
    expect(InstructorShiftModel.minutesOf('07:60'), isNull);
  });

  test('valida dia da semana, horários e vínculos', () {
    expect(turno().isValid, isTrue);
    expect(turno(weekday: 0).isValid, isFalse);
    expect(turno(weekday: 8).isValid, isFalse);
    expect(turno(startTime: '11:30').isValid, isFalse);
    expect(turno(endTime: '25:00').isValid, isFalse);
    expect(turno(instructorId: '').isValid, isFalse);
    expect(turno(unitId: '').isValid, isFalse);
  });

  test('ida e volta pelo JSON preserva os campos', () {
    final original = InstructorShiftModel(
      id: 't1',
      instructorId: 'prof-1',
      unitId: 'unidade-1',
      weekday: DateTime.friday,
      startTime: '14:00',
      endTime: '18:00',
      createdAt: DateTime.utc(2026, 11, 11, 12),
    );

    final json = original.toJson();
    expect(json['createdAt'], '2026-11-11T12:00:00.000Z');

    final lido = InstructorShiftModel.fromJson(json, 't1');
    expect(lido.instructorId, 'prof-1');
    expect(lido.unitId, 'unidade-1');
    expect(lido.weekday, DateTime.friday);
    expect(lido.startTime, '14:00');
    expect(lido.endTime, '18:00');
    expect(lido.createdAt, DateTime.utc(2026, 11, 11, 12));
  });

  test('documento incompleto vira turno inválido em vez de erro', () {
    final lido = InstructorShiftModel.fromJson(const {}, 'x');
    expect(lido.isValid, isFalse);
    expect(lido.createdAt, isNull);
    expect(lido.toJson().containsKey('createdAt'), isFalse);
  });
}
