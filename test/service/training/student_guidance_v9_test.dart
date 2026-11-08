import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fromRepdb = ExerciseCatalogEntry(
    id: 'repdb-1', name: 'Agachamento', muscleGroup: 'Pernas',
    instructions: 'Stand upright. Keep your back straight.',
    instructionsPtBrDraft: 'Fique em pé e mantenha as costas alinhadas.',
    source: 'repdb-free', language: 'en',
  );

  test('orientacao do professor em portugues prevalece sobre o catalogo', () {
    final result = StudentExercisePresentation.guidance(
      'Mantenha o tronco firme durante o movimento.', fromRepdb);
    expect(result.text, 'Mantenha o tronco firme durante o movimento.');
    expect(result.automaticTranslation, false);
  });

  test('texto automatico aparece em portugues com aviso de revisao', () {
    final result = StudentExercisePresentation.guidance(
      'Stand upright and bend your knees.', fromRepdb);
    expect(result.text, 'Fique em pé e mantenha as costas alinhadas.');
    expect(result.automaticTranslation, true);
  });

  test('sem traducao nao mostra orientacao em ingles', () {
    const noDraft = ExerciseCatalogEntry(
      id: 'x', name: 'Agachamento', muscleGroup: 'Pernas',
      instructions: 'Stand upright and bend your knees.',
      source: 'repdb-free', language: 'en',
    );
    expect(StudentExercisePresentation.guidance(
        'Stand upright and bend your knees.', noDraft).text, isNull);
  });
}
