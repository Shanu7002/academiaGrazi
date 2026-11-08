import 'package:academiagrazi/controller/teachers/training_plan_composer.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rotina antiga sem aquecimento continua compativel', () {
    final old = TrainingRoutine.fromMap({
      'id': 'a', 'letter': 'A', 'name': 'Treino A', 'focus': '',
      'estimatedMinutes': 45, 'exercises': <Map<String, dynamic>>[],
    });
    expect(old.warmupInstructions, isEmpty);
  });

  test('professor edita aquecimento e ele persiste no rascunho', () {
    final c = TrainingPlanComposer(studentId: 'a', instructorId: 'p', name: 'Ficha');
    final id = c.addRoutine(letter: 'A', name: 'Treino A',
      warmupInstructions: '5 minutos de caminhada leve');
    c.addExercise(id, const TrainingExercise(id: '1', catalogExerciseId: 'c1',
      name: 'Agachamento', muscleGroup: 'Pernas', sets: 3,
      repetitions: 12, restSeconds: 60));
    expect(c.buildDraft().routines.single.warmupInstructions, '5 minutos de caminhada leve');
    c.updateRoutine(routineId: id, warmupInstructions: 'Mobilidade de quadril');
    final map = c.buildDraft().routines.single.toMap();
    expect(TrainingRoutine.fromMap(map).warmupInstructions, 'Mobilidade de quadril');
    c.addExercise(id, const TrainingExercise(id: '2', catalogExerciseId: 'c2',
      name: 'Abdominal', muscleGroup: 'Abdômen', sets: 2,
      repetitions: 10, restSeconds: 30));
    expect(c.routine(id).warmupInstructions, 'Mobilidade de quadril');
    c.updateRoutine(routineId: id, warmupInstructions: '');
    expect(c.routine(id).warmupInstructions, isEmpty);
  });
}
