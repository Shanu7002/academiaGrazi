import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Salva apenas a prescricao atual de casa. Historico das execucoes fica
/// em trainingSessions, junto aos treinos presenciais.
class HomeWorkoutService {
  final FirebaseFirestore _db;

  HomeWorkoutService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String studentId) =>
      _db.collection('users').doc(studentId).collection('homeWorkouts').doc('current');

  static void _validId(String id, String field) {
    if (id.trim().isEmpty || id.contains('/')) {
      throw ArgumentError.value(id, field, 'Identificador invalido.');
    }
  }

  Future<HomeWorkoutPlan?> getCurrent(String studentId) async {
    _validId(studentId, 'studentId');
    final snapshot = await _ref(studentId).get();
    final data = snapshot.data();
    if (data == null || data['status'] != 'published') return null;
    return HomeWorkoutPlan.fromMap(data);
  }

  Stream<HomeWorkoutPlan?> watchCurrent(String studentId) {
    _validId(studentId, 'studentId');
    return _ref(studentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null || data['status'] != 'published'
          ? null : HomeWorkoutPlan.fromMap(data);
    });
  }

  Future<HomeWorkoutPlan> publish({
    required String studentId,
    required String instructorId,
    required List<TrainingRoutine> routines,
  }) async {
    _validId(studentId, 'studentId');
    _validId(instructorId, 'instructorId');
    final studentRef = _db.collection('users').doc(studentId);
    final currentRef = _ref(studentId);
    final copy = routines.map((item) => TrainingRoutine.fromMap(item.toMap()))
        .toList(growable: false);
    final preliminary = HomeWorkoutPlan(studentId: studentId,
      instructorId: instructorId, version: 1, routines: copy);
    preliminary.validate();
    return _db.runTransaction((tx) async {
      final student = await tx.get(studentRef);
      final previous = await tx.get(currentRef);
      if (student.data()?['type'] != 'user' ||
          student.data()?['responsable'] != instructorId) {
        throw StateError('O aluno nao esta vinculado a este professor.');
      }
      final old = previous.data();
      if (old != null && old['instructorId'] != instructorId) {
        throw StateError('Esta prescricao pertence a outro professor.');
      }
      final version = old == null ? 1 : ((old['version'] as num?)?.toInt() ?? 0) + 1;
      final published = HomeWorkoutPlan(studentId: studentId,
        instructorId: instructorId, version: version, routines: copy);
      published.validate();
      tx.set(currentRef, {...published.toMap(),
        'updatedAt': FieldValue.serverTimestamp()});
      return published;
    });
  }

  /// Remove apenas a prescricao atual. Sessoes ja finalizadas nao sao apagadas.
  Future<void> remove({required String studentId, required String instructorId}) async {
    _validId(studentId, 'studentId');
    _validId(instructorId, 'instructorId');
    final studentRef = _db.collection('users').doc(studentId);
    final currentRef = _ref(studentId);
    await _db.runTransaction((tx) async {
      final student = await tx.get(studentRef);
      final current = await tx.get(currentRef);
      if (student.data()?['type'] != 'user' ||
          student.data()?['responsable'] != instructorId) {
        throw StateError('O aluno nao esta vinculado a este professor.');
      }
      if (current.exists) {
        if (current.data()?['instructorId'] != instructorId) {
          throw StateError('Prescricao de outro professor.');
        }
        tx.delete(currentRef);
      }
    });
  }
}
