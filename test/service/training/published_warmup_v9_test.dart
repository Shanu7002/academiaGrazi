import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aquecimento e recuperado da ficha publicada original', () async {
    final db = FakeFirebaseFirestore();
    final service = TrainingPlanService(db: db);
    const routine = TrainingRoutine(
      id: 'treino-a', letter: 'A', name: 'Treino A', focus: 'Pernas',
      warmupInstructions: 'Caminhe 5 minutos em ritmo leve.',
      estimatedMinutes: 40, exercises: [
        TrainingExercise(
          id: '1', catalogExerciseId: 'catalog-1', name: 'Agachamento',
          muscleGroup: 'Pernas', sets: 3, repetitions: 12, restSeconds: 60,
        ),
      ],
    );
    final plan = TrainingPlan(
      id: 'ficha-1', studentId: 'aluno', instructorId: 'prof', name: 'Ficha',
      version: 1, status: TrainingPlanStatus.published,
      routines: const [routine], weeklySchedule: const {1: 'treino-a', 7: null},
    );
    await db.collection('users').doc('aluno')
        .collection('trainingPlans').doc('ficha-1').set(plan.toMap());
    final read = await service.getPublishedPlanById('aluno', 'ficha-1');
    expect(read?.routines.single.warmupInstructions,
      'Caminhe 5 minutos em ritmo leve.');
    expect(await service.getPublishedPlanById('aluno', 'inexistente'), isNull);
  });
}
