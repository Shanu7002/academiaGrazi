import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelos de treino por professor para reutilizar com outros alunos.
/// Nao publica uma ficha para nenhum aluno.
class RoutineTemplateRecord {
  final String id;
  final String studentId;
  final TrainingRoutine routine;

  const RoutineTemplateRecord({
    required this.id,
    required this.studentId,
    required this.routine,
  });
}

class TrainingRoutineTemplateService {
  final FirebaseFirestore _db;

  TrainingRoutineTemplateService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String teacherId) =>
      _db.collection('users').doc(teacherId).collection('routineTemplates');

  /// Chave estavel por aluno+letra: salva sem duplicar e pode ser reusada.
  Future<void> save({
    required String teacherId,
    required String studentId,
    required TrainingRoutine routine,
  }) async {
    if (teacherId.isEmpty || studentId.isEmpty) {
      throw ArgumentError('Professor e aluno obrigatorios.');
    }
    final ref = _collection(teacherId).doc('${studentId}_${routine.id}');
    await ref.set({
      'teacherId': teacherId,
      'studentId': studentId,
      'name': routine.name,
      'nameNormalized': routine.name.toLowerCase(),
      'routine': routine.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<RoutineTemplateRecord>> list(String teacherId) async {
    if (teacherId.isEmpty) return const [];
    final docs = await _collection(teacherId).limit(80).get();
    final templates =
        docs.docs.map((doc) {
          final data = doc.data();
          return RoutineTemplateRecord(
            id: doc.id,
            studentId: (data['studentId'] as String?) ?? '',
            routine: TrainingRoutine.fromMap(
              Map<String, dynamic>.from(data['routine'] as Map),
            ),
          );
        }).toList();
    templates.sort((a, b) => a.routine.name.compareTo(b.routine.name));
    return templates;
  }
}
