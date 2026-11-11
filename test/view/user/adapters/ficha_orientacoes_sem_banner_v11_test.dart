import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/view/user/adapters/training_plan_ui_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sem foto de capa: preserva miniatura de exercicio e orientacao em PT-BR', () {
    final plan = TrainingPlan(
      id: 'ficha', studentId: 'aluno', instructorId: 'prof',
      name: 'Ficha semanal', version: 1,
      status: TrainingPlanStatus.published,
      weeklySchedule: const {1: 'a', 7: null},
      routines: [TrainingRoutine(
        id: 'a', letter: 'A', name: 'Treino A', focus: 'Pernas',
        // Foto herdada de versoes anteriores NAO pode virar banner.
        imageUrl: 'https://example.com/foto-antiga-de-treino.jpg',
        estimatedMinutes: 45, exercises: [TrainingExercise(
          id: 'item', catalogExerciseId: 'repdb-squat', name: 'Squat',
          muscleGroup: 'Legs', sets: 3, repetitions: 12,
          restSeconds: 60, instructions: 'Stand with your feet apart.',
        )],
      )],
    );
    const item = ExerciseCatalogEntry(
      id: 'repdb-squat', name: 'Agachamento', muscleGroup: 'Legs',
      instructions: 'Stand with your feet apart.',
      instructionsPtBrDraft: 'Fique em pé com os pés afastados.',
      source: 'repdb-free', language: 'en',
      imageUrl: 'https://example.com/exercicio.jpg',
      nameReviewStatus: 'editorial_pending_review',
    );
    final ui = TrainingPlanUiMapper.fromPlan(
      plan, studentName: 'Aluno Teste', instructorName: 'Grazi',
      now: DateTime(2026, 11, 2),
      catalog: const {'repdb-squat': item},
    );
    final treino = ui.treinos.single;
    expect(treino.imageUrl, isNull);
    expect(treino.exercicios.single.imageUrl,
        'https://example.com/exercicio.jpg');
    expect(treino.exercicios.single.nome, 'Agachamento');
    expect(treino.exercicios.single.instructions,
        'Fique em pé com os pés afastados.');
    expect(treino.exercicios.single.instructionsAutoTranslated, true);
    expect(ui.programacaoSemanal[7], isNull);
  });
}
