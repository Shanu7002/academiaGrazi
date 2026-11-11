import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GymClassModel aula({
    String name = 'Spinning',
    String unitId = 'blocoA',
    int weekday = DateTime.monday,
    String startTime = '19:00',
    int durationMinutes = 60,
    int? capacity = 30,
  }) => GymClassModel(
    id: 'a1',
    name: name,
    unitId: unitId,
    weekday: weekday,
    startTime: startTime,
    durationMinutes: durationMinutes,
    capacity: capacity,
  );

  test('valida nome, bloco, dia, horário, duração e vagas', () {
    expect(aula().isValid, isTrue);
    expect(aula(capacity: null).isValid, isTrue);
    expect(aula(name: '  ').isValid, isFalse);
    expect(aula(unitId: '').isValid, isFalse);
    expect(aula(weekday: 0).isValid, isFalse);
    expect(aula(startTime: '7:00').isValid, isFalse);
    expect(aula(durationMinutes: 0).isValid, isFalse);
    expect(aula(capacity: 0).isValid, isFalse);
  });

  test('ida e volta pelo JSON preserva os campos', () {
    final original = GymClassModel(
      id: 'a1',
      name: 'Pilates',
      unitId: 'blocoA',
      instructorId: 'prof1',
      weekday: DateTime.thursday,
      startTime: '08:30',
      durationMinutes: 50,
      capacity: 12,
      createdAt: DateTime.utc(2026, 11, 11, 12),
    );

    final json = original.toJson();
    expect(json['createdAt'], '2026-11-11T12:00:00.000Z');
    expect(json['active'], isTrue);

    final lida = GymClassModel.fromJson(json, 'a1');
    expect(lida.name, 'Pilates');
    expect(lida.instructorId, 'prof1');
    expect(lida.weekday, DateTime.thursday);
    expect(lida.startTime, '08:30');
    expect(lida.startMinutes, 510);
    expect(lida.durationMinutes, 50);
    expect(lida.capacity, 12);
    expect(lida.createdAt, DateTime.utc(2026, 11, 11, 12));
  });

  test('campos opcionais ausentes não são gravados', () {
    final json = aula(capacity: null).toJson();
    expect(json.containsKey('capacity'), isFalse);
    expect(json.containsKey('instructorId'), isFalse);
    expect(json.containsKey('createdAt'), isFalse);
  });

  test('documento incompleto vira aula inválida em vez de erro', () {
    final lida = GymClassModel.fromJson(const {}, 'x');
    expect(lida.isValid, isFalse);
    expect(lida.active, isTrue);
  });
}
