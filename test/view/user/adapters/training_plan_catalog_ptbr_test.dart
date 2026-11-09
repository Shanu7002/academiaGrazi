import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/view/user/adapters/training_plan_ui_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ficha publicada exibe foto e nome editorial sem perder dias', () {
    final plan = TrainingPlan(
      id: 'ficha', studentId: 'aluno', instructorId: 'prof',
      name: 'Ciclo', version: 2, status: TrainingPlanStatus.published,
      weeklySchedule: const {1: 'a', 2: null, 3: 'a'},
      routines: [TrainingRoutine(
        id: 'a', letter: 'A', name: 'Treino A', focus: 'Pernas',
        estimatedMinutes: 40, exercises: [TrainingExercise(
          id: 'item', catalogExerciseId: 'repdb-1', name: 'Squat',
          muscleGroup: 'Legs', sets: 3, repetitions: 12, restSeconds: 70,
          instructions: 'Stand straight with your feet apart.',
        )],
      )],
    );
    const catalog = ExerciseCatalogEntry(
      id: 'repdb-1', name: 'Agachamento', muscleGroup: 'Legs',
      imageUrl: 'https://example.com/photo.jpg',
      language: 'en', source: 'repdb-free',
      nameReviewStatus: 'editorial_pending_review',
    );
    final ui = TrainingPlanUiMapper.fromPlan(
      plan, studentName: 'Ana', instructorName: 'Grazi',
      catalog: const {'repdb-1': catalog}, now: DateTime(2026, 11, 2),
    );
    expect(ui.programacaoSemanal[1], 'a');
    expect(ui.programacaoSemanal[2], isNull);
    expect(ui.treinos.single.exercicios.single.nome, 'Agachamento');
    expect(ui.treinos.single.exercicios.single.imageUrl,
      'https://example.com/photo.jpg');
    expect(ui.treinos.single.exercicios.single.instructions, isEmpty);
    expect(ui.treinos.single.exercicios.single.muscleGroup, 'Pernas');
  });
}
