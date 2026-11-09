import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Avaliações físicas ficam em `users/{alunoId}/evaluations`.
class PhysicalEvaluationService {
  final FirebaseFirestore _db;

  // coverage:ignore-start
  PhysicalEvaluationService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> _evaluations(String studentId) =>
      _db.collection('users').doc(studentId).collection('evaluations');

  /// Avaliações do aluno, da mais antiga para a mais recente.
  Stream<List<PhysicalEvaluation>> streamEvaluations(String studentId) {
    return _evaluations(studentId)
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PhysicalEvaluation.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> addEvaluation(String studentId, PhysicalEvaluation evaluation) {
    return _evaluations(studentId).add(evaluation.toJson());
  }

  Future<void> deleteEvaluation(String studentId, String evaluationId) {
    return _evaluations(studentId).doc(evaluationId).delete();
  }
}
