import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Grade de aulas (`gym_classes`). Só o admin grava; qualquer usuário
/// autenticado lê (ver `firestore.rules`).
class GymClassService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  GymClassService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection('gym_classes');

  /// Aulas em ordem de dia da semana e horário. As retiradas da grade só
  /// aparecem com [includeInactive]; [unitId] filtra por bloco.
  Stream<List<GymClassModel>> streamClasses({
    String? unitId,
    bool includeInactive = false,
  }) {
    final query =
        unitId == null ? _classes : _classes.where('unitId', isEqualTo: unitId);
    return query.snapshots().map((snapshot) {
      final classes =
          snapshot.docs
              .map((doc) => GymClassModel.fromJson(doc.data(), doc.id))
              .where((item) => item.isValid)
              .where((item) => includeInactive || item.active)
              .toList();
      // Ordenado no app para não exigir índice composto.
      classes.sort(
        (a, b) =>
            a.weekday != b.weekday
                ? a.weekday.compareTo(b.weekday)
                : a.startMinutes.compareTo(b.startMinutes),
      );
      return classes;
    });
  }

  /// Cria a aula e devolve o id do documento.
  Future<String> createClass(GymClassModel gymClass) async {
    final item = GymClassModel(
      id: '',
      name: gymClass.name.trim(),
      unitId: gymClass.unitId,
      instructorId: gymClass.instructorId,
      weekday: gymClass.weekday,
      startTime: gymClass.startTime,
      durationMinutes: gymClass.durationMinutes,
      capacity: gymClass.capacity,
      createdAt: _clock(),
    );
    _requireValid(item);
    final reference = await _classes.add(item.toJson());
    return reference.id;
  }

  /// Altera os dados da aula; `active` e `createdAt` não são tocados.
  Future<void> updateClass(GymClassModel gymClass) {
    _requireValid(gymClass);
    return _classes.doc(gymClass.id).update({
      'name': gymClass.name.trim(),
      'unitId': gymClass.unitId,
      'instructorId': gymClass.instructorId ?? FieldValue.delete(),
      'weekday': gymClass.weekday,
      'startTime': gymClass.startTime,
      'durationMinutes': gymClass.durationMinutes,
      'capacity': gymClass.capacity ?? FieldValue.delete(),
    });
  }

  /// Exclusão lógica: a aula sai da grade, mas o documento continua.
  Future<void> setClassActive(String classId, {required bool active}) {
    return _classes.doc(classId).update({'active': active});
  }

  static void _requireValid(GymClassModel gymClass) {
    if (!gymClass.isValid) {
      throw ArgumentError('Invalid class: check name, unit, day and time');
    }
  }
}
