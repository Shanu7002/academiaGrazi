import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome editorial em portugues nao significa orientacao traduzida', () {
    const item = ExerciseCatalogEntry(
      id: 'repdb-01',
      name: 'Agachamento na barra',
      muscleGroup: 'Legs',
      instructions: 'Stand straight and bend your knees.',
      imageUrl: 'https://example.com/01.jpg',
      source: 'repdb-free',
      language: 'en',
      nameReviewStatus: 'editorial_pending_review',
    );
    expect(StudentExercisePresentation.name('Barbell squat', item),
        'Agachamento na barra');
    expect(StudentExercisePresentation.portugueseInstructions(
      'Stand straight and bend your knees.', item), isNull);
    expect(StudentExercisePresentation.image(null, item),
        'https://example.com/01.jpg');
  });

  test('instrucao em portugues aprovada para exibicao nao depende de nome', () {
    const item = ExerciseCatalogEntry(
      id: 'a', name: 'Abdominal com roda', muscleGroup: 'Abs',
      instructions: 'Ajoelhe-se e mantenha o abdômen contraído.',
      language: 'pt-BR', source: 'repdb-free',
    );
    expect(StudentExercisePresentation.portugueseInstructions('', item),
      'Ajoelhe-se e mantenha o abdômen contraído.');
    expect(StudentExercisePresentation.muscleGroup('Abs'), 'Abdômen');
  });

  test('imagem invalida nao e enviada ao Image.network', () {
    expect(StudentExercisePresentation.image('http://example.com/a.jpg', null), isNull);
    expect(StudentExercisePresentation.image('', null), isNull);
  });
}
