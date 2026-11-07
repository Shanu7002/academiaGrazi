import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan samplePlan({Map<int, String?>? schedule}) => TrainingPlan(
  id: 'plan-a',
  studentId: 'student-1',
  instructorId: 'teacher-1',
  name: 'Ficha novembro',
  version: 1,
  status: TrainingPlanStatus.draft,
  weeklySchedule: schedule ?? {1: 'routine-a', 2: null, 4: 'routine-a'},
  routines: [
    TrainingRoutine(
      id: 'routine-a',
      letter: 'A',
      name: 'Treino A',
      focus: 'Pernas',
      estimatedMinutes: 45,
      exercises: [
        TrainingExercise(
          id: 'item-1',
          catalogExerciseId: 'agachamento',
          name: 'Agachamento livre',
          muscleGroup: 'Pernas',
          sets: 3,
          repetitions: 12,
          restSeconds: 60,
          targetLoadKg: 10.5,
          imageUrl: 'https://example.com/exercicio.png',
        ),
      ],
    ),
  ],
);

void main() {
  test('serializa ficha, programacao, imagem e carga corretamente', () {
    final plan = samplePlan();
    final restored = TrainingPlan.fromMap(plan.toMap(), plan.id);
    expect(restored.studentId, 'student-1');
    expect(restored.weeklySchedule[2], isNull);
    expect(restored.weeklySchedule[4], 'routine-a');
    expect(restored.routines.single.exercises.single.targetLoadKg, 10.5);
    expect(
      restored.routines.single.exercises.single.imageUrl,
      'https://example.com/exercicio.png',
    );
    restored.validateForPublication();
  });

  test(
    'bloqueia publicacao quando o calendario aponta para treino inexistente',
    () {
      final plan = samplePlan(schedule: {1: 'nao-existe'});
      expect(plan.validateForPublication, throwsStateError);
    },
  );

  test('permite dias de descanso, mas exige ao menos um treino programado', () {
    final plan = samplePlan(schedule: {1: null, 2: null});
    expect(plan.validateForPublication, throwsStateError);
  });

  test('impede exercicio com numero de series invalido', () {
    final exercise = TrainingExercise(
      id: 'item',
      catalogExerciseId: 'catalog',
      name: 'Rosca direta',
      muscleGroup: 'Biceps',
      sets: 0,
      repetitions: 12,
      restSeconds: 60,
    );
    expect(exercise.validate, throwsStateError);
  });

  test('erro de status desconhecido nao e interpretado silenciosamente', () {
    final map = samplePlan().toMap()..['status'] = 'unknown';
    expect(() => TrainingPlan.fromMap(map, 'plan-a'), throwsFormatException);
  });
}
