import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/view/user/adapters/training_plan_ui_mapper.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan plan({TrainingPlanStatus status = TrainingPlanStatus.published}) =>
    TrainingPlan(
      id: 'ficha-1',
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      name: 'Ficha de novembro',
      version: 2,
      status: status,
      weeklySchedule: {1: 'a', 2: null, 4: 'b', 5: 'a'},
      routines: [
        TrainingRoutine(
          id: 'a',
          letter: 'A',
          name: 'Treino A - Pernas',
          focus: 'Pernas',
          estimatedMinutes: 40,
          exercises: [
            TrainingExercise(
              id: 'item-1',
              catalogExerciseId: 'catalog-agachamento',
              name: 'Agachamento',
              muscleGroup: 'Pernas',
              sets: 3,
              repetitions: 12,
              restSeconds: 75,
              instructions: 'Mantenha a postura.',
              targetLoadKg: 10.5,
              imageUrl: 'https://example.com/agachamento.jpg',
            ),
          ],
        ),
        TrainingRoutine(
          id: 'b',
          letter: 'B',
          name: 'Treino B - Superior',
          focus: 'Superior',
          estimatedMinutes: 50,
          exercises: [
            TrainingExercise(
              id: 'item-2',
              catalogExerciseId: 'catalog-supino',
              name: 'Supino',
              muscleGroup: 'Peito',
              sets: 4,
              repetitions: 10,
              restSeconds: 60,
            ),
          ],
        ),
      ],
    );

void main() {
  test('segunda recomenda A, conserva series, carga e orientacoes', () {
    final mapped = TrainingPlanUiMapper.fromPlan(
      plan(),
      studentName: 'Ana',
      instructorName: 'Prof. Grazi',
      now: DateTime(2026, 11, 2), // segunda-feira
    );
    expect(mapped.alunoNome, 'Ana');
    expect(mapped.frequencia, '3x');
    expect(mapped.duracaoMedia, '45 min');
    expect(mapped.treinos.first.status, TreinoStatusUi.recomendado);
    expect(mapped.treinos.last.status, TreinoStatusUi.programado);
    expect(mapped.treinos.first.exercicios.single.series, '3x12');
    expect(mapped.treinos.first.exercicios.single.carga, '10.5 kg');
    final detail = mapped.treinoDiaPorId['a']!;
    expect(detail.professorNome, 'Prof. Grazi');
    expect(detail.exercicioDetalhePorId['item-1']?.descanso, '75s');
    expect(
      detail.exercicioDetalhePorId['item-1']?.orientacoes,
      'Mantenha a postura.',
    );
  });

  test('descanso nao inventa treino concluido nem recomendado', () {
    final mapped = TrainingPlanUiMapper.fromPlan(
      plan(),
      studentName: 'Ana',
      instructorName: 'Prof. Grazi',
      now: DateTime(2026, 11, 3), // terca-feira
    );
    expect(
      mapped.treinos.every((e) => e.status == TreinoStatusUi.programado),
      isTrue,
    );
  });

  test('quinta recomenda B sem marcar como concluido', () {
    final mapped = TrainingPlanUiMapper.fromPlan(
      plan(),
      studentName: 'Ana',
      instructorName: 'Prof. Grazi',
      now: DateTime(2026, 11, 5), // quinta-feira
    );
    expect(mapped.treinos.last.status, TreinoStatusUi.recomendado);
    expect(
      mapped.treinos.any((e) => e.status == TreinoStatusUi.concluido),
      isFalse,
    );
    expect(mapped.treinos.last.exercicios.single.carga, 'A definir');
  });

  test('nao mostra um rascunho como ficha do aluno', () {
    expect(
      () => TrainingPlanUiMapper.fromPlan(
        plan(status: TrainingPlanStatus.draft),
        studentName: 'Ana',
        instructorName: 'Prof. Grazi',
      ),
      throwsStateError,
    );
  });
}
