import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Armazena a execucao do aluno separadamente da ficha publicada.
///
/// As regras do Firestore verificam a identidade do aluno. Este service
/// tambem valida o plano e os identificadores para evitar erros da UI.
class TrainingSessionService {
  final FirebaseFirestore _db;
  final TrainingPlanService _plans;
  final DateTime Function() _clock;

  // coverage:ignore-start
  TrainingSessionService({
    FirebaseFirestore? db,
    TrainingPlanService? planService,
    DateTime Function()? clock,
  }) : _db = db ?? FirebaseFirestore.instance,
       _plans = planService ?? TrainingPlanService(db: db),
       _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> _sessions(String studentId) =>
      _db.collection('users').doc(studentId).collection('trainingSessions');

  void _requireId(String value, String name) {
    if (value.trim().isEmpty || value.contains('/')) {
      throw ArgumentError.value(value, name, 'Identificador invalido.');
    }
  }

  /// Inicia o treino (ou recupera uma sessao ja aberta).
  ///
  /// [sessionId] opcional permite repetir uma requisicao sem criar uma
  /// segunda sessao. A interface tambem deve bloquear toques duplicados.
  Future<TrainingSession> startSession({
    required String studentId,
    required String planId,
    required String routineId,
    String? sessionId,
  }) async {
    _requireId(studentId, 'studentId');
    _requireId(planId, 'planId');
    _requireId(routineId, 'routineId');
    if (sessionId != null) _requireId(sessionId, 'sessionId');

    final active = await getInProgress(studentId);
    if (active != null) {
      if (active.planId == planId && active.routineId == routineId) {
        return active;
      }
      throw StateError('Finalize ou retome o treino em andamento.');
    }

    final plan = await _plans.getActivePlan(studentId);
    if (plan == null ||
        plan.status != TrainingPlanStatus.published ||
        plan.studentId != studentId ||
        plan.id != planId) {
      throw StateError('A ficha informada nao esta ativa para este aluno.');
    }
    final routines = plan.routines.where((routine) => routine.id == routineId);
    if (routines.isEmpty) {
      throw StateError('Treino nao pertence a ficha ativa.');
    }

    final reference =
        sessionId == null
            ? _sessions(studentId).doc()
            : _sessions(studentId).doc(sessionId);
    final proposed = TrainingSession.fromRoutine(
      sessionId: reference.id,
      plan: plan,
      routine: routines.first,
      startedAt: _clock(),
    );
    // Com o mesmo sessionId, chamadas concorrentes nao sobrescrevem a sessao.
    return _db.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists && existing.data() != null) {
        final saved = TrainingSession.fromMap(existing.data()!, existing.id);
        if (saved.studentId == studentId &&
            saved.planId == planId &&
            saved.routineId == routineId &&
            saved.status == TrainingSessionStatus.inProgress) {
          return saved;
        }
        throw StateError('Identificador de sessao ja utilizado.');
      }
      transaction.set(reference, {
        ...proposed.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return proposed;
    });
  }

  Future<TrainingSession?> getInProgress(String studentId) async {
    _requireId(studentId, 'studentId');
    final snapshot =
        await _sessions(studentId)
            .where('status', isEqualTo: TrainingSessionStatus.inProgress.name)
            .get();
    if (snapshot.docs.isEmpty) return null;
    final sessions =
        snapshot.docs
            .map((doc) => TrainingSession.fromMap(doc.data(), doc.id))
            .toList();
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions.first;
  }

  Future<TrainingSession?> getSession(
    String studentId,
    String sessionId,
  ) async {
    _requireId(studentId, 'studentId');
    _requireId(sessionId, 'sessionId');
    final snapshot = await _sessions(studentId).doc(sessionId).get();
    final data = snapshot.data();
    return data == null ? null : TrainingSession.fromMap(data, snapshot.id);
  }

  Future<TrainingSession> recordSet({
    required String studentId,
    required String sessionId,
    required String exerciseItemId,
    required int setNumber,
    required bool completed,
    double? loadKg,
  }) async {
    _requireId(studentId, 'studentId');
    _requireId(sessionId, 'sessionId');
    final reference = _sessions(studentId).doc(sessionId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null) throw StateError('Sessao nao encontrada.');
      final current = TrainingSession.fromMap(data, snapshot.id);
      if (current.studentId != studentId) {
        throw StateError('Sessao nao pertence ao aluno.');
      }
      final updated = current.updateSet(
        exerciseItemId: exerciseItemId,
        setNumber: setNumber,
        completed: completed,
        loadKg: loadKg,
      );
      transaction.update(reference, {
        'exercises':
            updated.exercises.map((exercise) => exercise.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return updated;
    });
  }

  Future<TrainingSession> setWarmup({
    required String studentId,
    required String sessionId,
    required bool done,
  }) async {
    _requireId(studentId, 'studentId');
    _requireId(sessionId, 'sessionId');
    final reference = _sessions(studentId).doc(sessionId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null) throw StateError('Sessao nao encontrada.');
      final current = TrainingSession.fromMap(data, snapshot.id);
      final updated = current.markWarmup(done);
      transaction.update(reference, {
        'warmupDone': updated.warmupDone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return updated;
    });
  }

  Future<TrainingSession> finishSession({
    required String studentId,
    required String sessionId,
  }) async {
    _requireId(studentId, 'studentId');
    _requireId(sessionId, 'sessionId');
    final reference = _sessions(studentId).doc(sessionId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null) throw StateError('Sessao nao encontrada.');
      final current = TrainingSession.fromMap(data, snapshot.id);
      final updated = current.finishAt(_clock());
      transaction.update(reference, {
        'status': TrainingSessionStatus.finished.name,
        'finishedAt': updated.finishedAt!.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return updated;
    });
  }

  /// Historico de sessoes do aluno. A regra de leitura permite ao professor
  /// vinculado acompanhar a execucao, sem permitir que a altere.
  Stream<List<TrainingSession>> watchHistory(String studentId) {
    _requireId(studentId, 'studentId');
    return _sessions(studentId)
        .where('status', isEqualTo: TrainingSessionStatus.finished.name)
        .snapshots()
        .map((snapshot) {
          final sessions =
              snapshot.docs
                  .map((doc) => TrainingSession.fromMap(doc.data(), doc.id))
                  .toList();
          sessions.sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));
          return sessions;
        });
  }
}
