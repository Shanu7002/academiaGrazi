import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Acesso a fichas do aluno. A autorizacao final fica em firestore.rules.
///
/// Uma ficha publicada e tratada como imutavel: para alterar uma prescricao,
/// crie outra ficha/versao e publique-a. O ponteiro `trainingState/current`
/// determina qual prescricao o aluno ve como ativa.
class TrainingPlanService {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  TrainingPlanService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  DocumentReference<Map<String, dynamic>> _studentRef(String studentId) =>
      _db.collection('users').doc(studentId);

  CollectionReference<Map<String, dynamic>> _plans(String studentId) =>
      _studentRef(studentId).collection('trainingPlans');

  DocumentReference<Map<String, dynamic>> _current(String studentId) =>
      _studentRef(studentId).collection('trainingState').doc('current');

  void _verifyLinkedStudent(Map<String, dynamic>? data, String instructorId) {
    if (data == null ||
        data['type'] != 'user' ||
        data['responsable'] != instructorId) {
      throw StateError('Aluno nao esta vinculado a este professor.');
    }
  }

  Future<String> createDraft(TrainingPlan draft) async {
    if (draft.status != TrainingPlanStatus.draft ||
        draft.studentId.isEmpty ||
        draft.instructorId.isEmpty ||
        draft.name.trim().isEmpty) {
      throw StateError('Rascunho invalido.');
    }

    final student = await _studentRef(draft.studentId).get();
    _verifyLinkedStudent(student.data(), draft.instructorId);

    final ref = _plans(draft.studentId).doc();
    await ref.set({
      ...draft.copyWith(id: ref.id, version: 1).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Lista rascunhos deste aluno, sem misturar fichas de outros professores.
  /// Esta consulta nao precisa de indice composto.
  Future<List<TrainingPlan>> getDraftsForStudent({
    required String studentId,
    required String instructorId,
  }) async {
    if (studentId.trim().isEmpty || instructorId.trim().isEmpty) {
      throw ArgumentError('Aluno e professor obrigatorios.');
    }
    final student = await _studentRef(studentId).get();
    _verifyLinkedStudent(student.data(), instructorId);

    final snapshot =
        await _plans(
          studentId,
        ).where('status', isEqualTo: TrainingPlanStatus.draft.name).get();
    return snapshot.docs
        .map((doc) => TrainingPlan.fromMap(doc.data(), doc.id))
        .where(
          (plan) =>
              plan.studentId == studentId &&
              plan.instructorId == instructorId &&
              plan.status == TrainingPlanStatus.draft,
        )
        .toList(growable: false);
  }

  /// Salva edicoes apenas enquanto a ficha ainda for rascunho.
  Future<void> saveDraft(TrainingPlan draft) async {
    if (draft.id.isEmpty || draft.status != TrainingPlanStatus.draft) {
      throw StateError('Somente rascunhos podem ser alterados.');
    }
    final studentRef = _studentRef(draft.studentId);
    final planRef = _plans(draft.studentId).doc(draft.id);

    await _db.runTransaction((transaction) async {
      final student = await transaction.get(studentRef);
      final current = await transaction.get(planRef);
      _verifyLinkedStudent(student.data(), draft.instructorId);
      if (!current.exists || current.data() == null) {
        throw StateError('Rascunho nao encontrado.');
      }
      final saved = TrainingPlan.fromMap(current.data()!, current.id);
      if (saved.status != TrainingPlanStatus.draft ||
          saved.instructorId != draft.instructorId ||
          saved.studentId != draft.studentId) {
        throw StateError('Esta ficha nao pode mais ser editada.');
      }
      transaction.update(planRef, {
        ...draft.copyWith(version: saved.version + 1).toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Publica de forma atomica a ficha e o ponteiro para a ficha ativa.
  Future<void> publishDraft({
    required String studentId,
    required String instructorId,
    required String planId,
  }) async {
    if (studentId.isEmpty || instructorId.isEmpty || planId.isEmpty) {
      throw ArgumentError('Identificadores obrigatorios.');
    }
    final studentRef = _studentRef(studentId);
    final planRef = _plans(studentId).doc(planId);
    final currentRef = _current(studentId);

    await _db.runTransaction((transaction) async {
      // Todas as leituras precedem as escritas nesta transacao.
      final student = await transaction.get(studentRef);
      final plan = await transaction.get(planRef);
      _verifyLinkedStudent(student.data(), instructorId);
      if (!plan.exists || plan.data() == null) {
        throw StateError('Ficha nao encontrada.');
      }
      final saved = TrainingPlan.fromMap(plan.data()!, plan.id);
      if (saved.instructorId != instructorId ||
          saved.studentId != studentId ||
          saved.status != TrainingPlanStatus.draft) {
        throw StateError(
          'Ficha nao pertence ao professor ou ja foi publicada.',
        );
      }
      saved.validateForPublication();

      transaction.update(planRef, {
        'status': TrainingPlanStatus.published.name,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(currentRef, {
        'activePlanId': planId,
        'instructorId': instructorId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Carrega somente a ficha apontada por `trainingState/current`.
  Future<TrainingPlan?> getActivePlan(String studentId) async {
    final current = await _current(studentId).get();
    final id = current.data()?['activePlanId'];
    if (id is! String || id.isEmpty) return null;
    final plan = await _plans(studentId).doc(id).get();
    final data = plan.data();
    if (data == null) return null;
    final parsed = TrainingPlan.fromMap(data, plan.id);
    return parsed.status == TrainingPlanStatus.published ? parsed : null;
  }

  /// Acompanhamento do ponteiro da ficha ativa: nova publicacao gera emissao.
  Stream<TrainingPlan?> watchActivePlan(String studentId) =>
      _current(studentId).snapshots().asyncMap((_) => getActivePlan(studentId));
}
