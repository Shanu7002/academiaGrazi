import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ida e volta pelo JSON preserva os campos', () {
    final original = UnitModel(
      id: 'u1',
      name: 'Bloco A',
      address: 'Rua 1, 100',
      createdAt: DateTime.utc(2026, 11, 11, 12),
    );

    final json = original.toJson();
    expect(json, {
      'name': 'Bloco A',
      'address': 'Rua 1, 100',
      'active': true,
      'createdAt': '2026-11-11T12:00:00.000Z',
    });

    final lida = UnitModel.fromJson(json, 'u1');
    expect(lida.id, 'u1');
    expect(lida.name, 'Bloco A');
    expect(lida.address, 'Rua 1, 100');
    expect(lida.active, isTrue);
    expect(lida.createdAt, DateTime.utc(2026, 11, 11, 12));
  });

  test('sem endereço e sem createdAt não grava os campos', () {
    const unidade = UnitModel(id: 'u1', name: 'Bloco B', active: false);
    expect(unidade.toJson(), {'name': 'Bloco B', 'active': false});
  });

  test('documento sem active é considerado ativo', () {
    final lida = UnitModel.fromJson(const {'name': 'Bloco C'}, 'u3');
    expect(lida.active, isTrue);
    expect(lida.address, isNull);
    expect(lida.createdAt, isNull);
  });
}
