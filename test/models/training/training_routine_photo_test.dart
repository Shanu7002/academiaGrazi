import 'package:academiagrazi/controller/teachers/training_plan_composer.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foto do treino persiste no mapa e apos reconstruir', () {
    const routine = TrainingRoutine(
      id: 'treino-a',
      letter: 'A',
      name: 'Treino A',
      focus: 'Pernas',
      imageUrl: 'https://example.org/treino-a.jpg',
      estimatedMinutes: 45,
      exercises: [],
    );
    final restored = TrainingRoutine.fromMap(routine.toMap());
    expect(restored.imageUrl, routine.imageUrl);
  });

  test('foto persiste ao editar rotina no compositor', () {
    final composer = TrainingPlanComposer(
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      name: 'Ficha semanal',
    );
    final id = composer.addRoutine(
      letter: 'A',
      name: 'Treino A',
      imageUrl: 'https://example.org/foto-a.jpg',
    );
    composer.updateRoutine(routineId: id, name: 'Treino A atualizado');
    expect(composer.routine(id).imageUrl, 'https://example.org/foto-a.jpg');
    expect(
      composer.buildDraft().routines.single.imageUrl,
      'https://example.org/foto-a.jpg',
    );
  });
}
