import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const routine = TrainingRoutine(id: 'casa-a', letter: 'A',
    name: 'Mobilidade em casa', focus: 'Quadril',
    warmupInstructions: 'Caminhada leve', estimatedMinutes: 25,
    exercises: [TrainingExercise(id: 'item1',catalogExerciseId:'catalog-1',
      name:'Agachamento', muscleGroup:'Pernas', instructions:'Flexione os joelhos.',
      sets:3,repetitions:12,restSeconds:60)]);
  test('programa opcional serializa e restaura sem ficha presencial', () {
    const plan = HomeWorkoutPlan(studentId:'aluno',instructorId:'prof',
      version:1,routines:[routine]);
    plan.validate();
    final restored = HomeWorkoutPlan.fromMap(plan.toMap());
    expect(restored.version,1);
    expect(restored.routines.single.warmupInstructions,'Caminhada leve');
    expect(restored.routines.single.exercises.single.instructions,'Flexione os joelhos.');
    expect(restored.toMap()['status'],'published');
  });
  test('nao publica treino vazio', () {
    const bad = HomeWorkoutPlan(studentId:'aluno',instructorId:'prof',
      version:1,routines:[]);
    expect(bad.validate, throwsStateError);
  });
}
