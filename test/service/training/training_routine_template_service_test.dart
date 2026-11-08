import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/training_routine_template_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('treino salvo pode ser reutilizado depois', () async {
    final db = FakeFirebaseFirestore();
    final service = TrainingRoutineTemplateService(db: db);
    await service.save(
      teacherId: 'prof-1',
      studentId: 'aluno-1',
      routine: const TrainingRoutine(
        id: 'treino-a',
        letter: 'A',
        name: 'Treino A',
        focus: 'Peito',
        estimatedMinutes: 45,
        exercises: [],
        imageUrl: 'https://example.org/capa.webp',
      ),
    );
    final results = await service.list('prof-1');
    expect(results, hasLength(1));
    expect(results.first.routine.imageUrl, 'https://example.org/capa.webp');
  });
}
