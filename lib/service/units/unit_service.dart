import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidades da academia (`units`). Só o admin grava; qualquer usuário
/// autenticado lê (ver `firestore.rules`).
class UnitService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  UnitService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _units =>
      _db.collection('units');

  /// Unidades em ordem alfabética. As desativadas só aparecem com
  /// [includeInactive] (tela de gestão do admin).
  Stream<List<UnitModel>> streamUnits({bool includeInactive = false}) {
    return _units.orderBy('name').snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => UnitModel.fromJson(doc.data(), doc.id))
              .where((unit) => includeInactive || unit.active)
              .toList(),
    );
  }

  /// Cria a unidade e devolve o id do documento.
  Future<String> createUnit({required String name, String? address}) async {
    final unit = UnitModel(
      id: '',
      name: _requireName(name),
      address: _clean(address),
      createdAt: _clock(),
    );
    final reference = await _units.add(unit.toJson());
    return reference.id;
  }

  /// Altera nome e endereço; `createdAt` não é reescrito.
  Future<void> updateUnit(
    String unitId, {
    required String name,
    String? address,
  }) {
    final cleanAddress = _clean(address);
    return _units.doc(unitId).update({
      'name': _requireName(name),
      'address': cleanAddress ?? FieldValue.delete(),
    });
  }

  /// Exclusão lógica: a unidade deixa de aparecer, mas continua
  /// referenciada por alunos e turnos.
  Future<void> setUnitActive(String unitId, {required bool active}) {
    return _units.doc(unitId).update({'active': active});
  }

  static String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Unit name is required');
    }
    return trimmed;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
