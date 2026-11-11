import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late UnitService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = UnitService(db: db, clock: () => DateTime.utc(2026, 11, 11, 12));
  });

  test('cria a unidade com createdAt em UTC e sem espaços extras', () async {
    final id = await service.createUnit(name: '  Bloco A ', address: '  ');

    final doc = await db.collection('units').doc(id).get();
    expect(doc.data(), {
      'name': 'Bloco A',
      'active': true,
      'createdAt': '2026-11-11T12:00:00.000Z',
    });
  });

  test('recusa unidade sem nome', () {
    expect(() => service.createUnit(name: '   '), throwsArgumentError);
  });

  test('lista em ordem alfabética e esconde as desativadas', () async {
    final b = await service.createUnit(name: 'Bloco B');
    await service.createUnit(name: 'Bloco A');
    await service.createUnit(name: 'Bloco C');
    await service.setUnitActive(b, active: false);

    final ativas = await service.streamUnits().first;
    expect(ativas.map((u) => u.name), ['Bloco A', 'Bloco C']);

    final todas = await service.streamUnits(includeInactive: true).first;
    expect(todas.map((u) => u.name), ['Bloco A', 'Bloco B', 'Bloco C']);
  });

  test('editar não reescreve createdAt e remove endereço vazio', () async {
    final id = await service.createUnit(name: 'Bloco A', address: 'Rua 1');

    await service.updateUnit(id, name: 'Bloco Central', address: '');

    final data = (await db.collection('units').doc(id).get()).data()!;
    expect(data['name'], 'Bloco Central');
    expect(data.containsKey('address'), isFalse);
    expect(data['createdAt'], '2026-11-11T12:00:00.000Z');
  });
}
