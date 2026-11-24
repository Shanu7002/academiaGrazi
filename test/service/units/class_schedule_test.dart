import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/service/units/class_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

GymClassModel _class(
  String id,
  int weekday,
  String startTime, {
  bool active = true,
}) => GymClassModel(
  id: id,
  name: 'Aula $id',
  unitId: 'bloco-a',
  weekday: weekday,
  startTime: startTime,
  durationMinutes: 50,
  active: active,
);

void main() {
  // Quinta, 12/11/2026, 10:00.
  final now = DateTime(2026, 11, 12, 10);

  test('sem aulas ativas não há próxima aula', () {
    expect(nextGymClass(const [], now), isNull);
    expect(
      nextGymClass([
        _class('inativa', DateTime.friday, '08:00', active: false),
      ], now),
      isNull,
    );
  });

  test('escolhe a aula de hoje que ainda vai começar', () {
    final next = nextGymClass([
      _class('sexta', DateTime.friday, '07:00'),
      _class('hoje-tarde', DateTime.thursday, '18:00'),
      _class('hoje-cedo', DateTime.thursday, '08:00'),
    ], now);
    expect(next!.gymClass.id, 'hoje-tarde');
    expect(next.startsAt, DateTime(2026, 11, 12, 18));
  });

  test('aula começando agora já está acontecendo e não conta', () {
    final next = nextGymClass([
      _class('agora', DateTime.thursday, '10:00'),
      _class('sexta', DateTime.friday, '07:00'),
    ], now);
    expect(next!.gymClass.id, 'sexta');
    expect(next.startsAt, DateTime(2026, 11, 13, 7));
  });

  test('vira a semana quando as aulas da semana já passaram', () {
    final next = nextGymClass([
      _class('segunda', DateTime.monday, '19:00'),
      _class('hoje-cedo', DateTime.thursday, '07:00'),
    ], now);
    expect(next!.gymClass.id, 'segunda');
    expect(next.startsAt, DateTime(2026, 11, 16, 19));
  });

  test('aula única de hoje já passada volta na semana seguinte', () {
    final next = nextGymClass([
      _class('hoje', DateTime.thursday, '07:00'),
    ], now);
    expect(next!.startsAt, DateTime(2026, 11, 19, 7));
  });
}
