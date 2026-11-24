import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late GymClassService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = GymClassService(
      db: db,
      clock: () => DateTime.utc(2026, 11, 11, 12),
    );
  });

  GymClassModel aula({
    String id = '',
    String name = 'Spinning',
    String unitId = 'blocoA',
    String? instructorId,
    int weekday = DateTime.monday,
    String startTime = '19:00',
    int? capacity,
  }) => GymClassModel(
    id: id,
    name: name,
    unitId: unitId,
    instructorId: instructorId,
    weekday: weekday,
    startTime: startTime,
    durationMinutes: 60,
    capacity: capacity,
  );

  test('grava a aula no formato do schema', () async {
    final id = await service.createClass(
      aula(name: ' Spinning ', instructorId: 'prof1', capacity: 30),
    );

    final doc = await db.collection('gym_classes').doc(id).get();
    expect(doc.data(), {
      'name': 'Spinning',
      'unitId': 'blocoA',
      'instructorId': 'prof1',
      'weekday': 1,
      'startTime': '19:00',
      'durationMinutes': 60,
      'capacity': 30,
      'active': true,
      'createdAt': '2026-11-11T12:00:00.000Z',
    });
  });

  test('recusa aula inválida', () {
    expect(() => service.createClass(aula(name: '')), throwsArgumentError);
    expect(
      () => service.updateClass(aula(id: 'x', startTime: '25:00')),
      throwsArgumentError,
    );
  });

  test('lista por dia e horário, filtra bloco e retiradas', () async {
    await service.createClass(aula(weekday: DateTime.wednesday));
    await service.createClass(aula(name: 'Pilates', startTime: '07:00'));
    await service.createClass(aula(name: 'Yoga', unitId: 'blocoB'));
    final retirada = await service.createClass(
      aula(name: 'Zumba', startTime: '20:00'),
    );
    await service.setClassActive(retirada, active: false);

    final ativas = await service.streamClasses().first;
    expect(ativas.map((a) => '${a.weekday} ${a.startTime} ${a.name}'), [
      '1 07:00 Pilates',
      '1 19:00 Yoga',
      '3 19:00 Spinning',
    ]);

    final doBlocoA = await service.streamClasses(unitId: 'blocoA').first;
    expect(doBlocoA.map((a) => a.name), ['Pilates', 'Spinning']);

    final todas = await service.streamClasses(includeInactive: true).first;
    expect(todas.map((a) => a.name), contains('Zumba'));
  });

  test(
    'editar não reescreve createdAt nem active e remove opcionais',
    () async {
      final id = await service.createClass(
        aula(instructorId: 'prof1', capacity: 30),
      );
      await service.setClassActive(id, active: false);

      await service.updateClass(aula(id: id, name: 'Spinning Pro'));

      final data = (await db.collection('gym_classes').doc(id).get()).data()!;
      expect(data['name'], 'Spinning Pro');
      expect(data['active'], isFalse);
      expect(data['createdAt'], '2026-11-11T12:00:00.000Z');
      expect(data.containsKey('instructorId'), isFalse);
      expect(data.containsKey('capacity'), isFalse);
    },
  );
}
