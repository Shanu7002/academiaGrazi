import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late InstructorShiftService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = InstructorShiftService(
      db: db,
      clock: () => DateTime.utc(2026, 11, 11, 12),
    );
  });

  Future<String> adicionar({
    String instructorId = 'prof-1',
    int weekday = DateTime.monday,
    String startTime = '07:00',
    String endTime = '11:00',
  }) {
    return service.addShift(
      instructorId: instructorId,
      unitId: 'unidade-1',
      weekday: weekday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  test('grava o turno no formato do schema', () async {
    final id = await adicionar();

    final doc = await db.collection('instructorShifts').doc(id).get();
    expect(doc.data(), {
      'instructorId': 'prof-1',
      'unitId': 'unidade-1',
      'weekday': 1,
      'startTime': '07:00',
      'endTime': '11:00',
      'createdAt': '2026-11-11T12:00:00.000Z',
    });
  });

  test('recusa turno com início depois do fim ou dia inválido', () {
    expect(() => adicionar(startTime: '12:00'), throwsArgumentError);
    expect(() => adicionar(weekday: 8), throwsArgumentError);
  });

  test('lista só os turnos do professor, por dia e horário', () async {
    await adicionar(weekday: DateTime.wednesday, startTime: '08:00');
    await adicionar(startTime: '14:00', endTime: '18:00');
    await adicionar();
    await adicionar(instructorId: 'prof-2');

    final turnos = await service.streamShiftsForInstructor('prof-1').first;
    expect(
      turnos.map((t) => '${t.weekday} ${t.startTime}'),
      ['1 07:00', '1 14:00', '3 08:00'],
    );
  });

  test('remove o turno', () async {
    final id = await adicionar();

    await service.deleteShift(id);

    expect(await service.streamShiftsForInstructor('prof-1').first, isEmpty);
  });
}
