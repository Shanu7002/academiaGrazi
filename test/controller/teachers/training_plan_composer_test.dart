import 'package:academiagrazi/controller/teachers/training_plan_composer.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingExercise exercise(String id) => TrainingExercise(
  id: id,
  catalogExerciseId: 'catalog-$id',
  name: 'Exercicio $id',
  muscleGroup: 'Pernas',
  sets: 3,
  repetitions: 12,
  restSeconds: 60,
);

TrainingPlanComposer composer() => TrainingPlanComposer(
  studentId: 'aluno-1',
  instructorId: 'prof-1',
  name: 'Ficha novembro',
);

void main() {
  test('cria A/B por aluno com calendario e dias de descanso', () {
    final edit = composer();
    final a = edit.addRoutine(letter: 'a', name: 'Treino A');
    final b = edit.addRoutine(letter: 'b', name: 'Treino B');
    edit.addExercise(a, exercise('e1'));
    edit.addExercise(b, exercise('e2'));
    edit.assignDay(DateTime.monday, a);
    edit.assignDay(DateTime.tuesday, b);
    edit.assignDay(DateTime.wednesday, null);

    final draft = edit.buildReadyToPublish();
    expect(draft.status, TrainingPlanStatus.draft);
    expect(draft.routines.map((e) => e.letter), ['A', 'B']);
    expect(draft.weeklySchedule[DateTime.tuesday], b);
    expect(draft.weeklySchedule[DateTime.wednesday], isNull);
  });

  test('impede treino duplicado ou letra invalida', () {
    final edit = composer();
    edit.addRoutine(letter: 'A', name: 'Pernas');
    expect(() => edit.addRoutine(letter: 'a', name: 'Outro'), throwsStateError);
    expect(
      () => edit.addRoutine(letter: 'AB', name: 'Invalido'),
      throwsArgumentError,
    );
  });

  test('retirar treino limpa sua programacao e exige nova distribuicao', () {
    final edit = composer();
    final a = edit.addRoutine(letter: 'A', name: 'Pernas');
    edit.addExercise(a, exercise('e1'));
    edit.assignDay(1, a);
    edit.removeRoutine(a);
    expect(edit.weeklySchedule[1], isNull);
    expect(edit.buildReadyToPublish, throwsStateError);
  });

  test('nao deixa agendar treino inexistente nem dia 8', () {
    final edit = composer();
    expect(() => edit.assignDay(1, 'nao-existe'), throwsStateError);
    expect(() => edit.assignDay(8, null), throwsArgumentError);
  });

  test('adiciona, atualiza, reordena e remove exercicios', () {
    final edit = composer();
    final a = edit.addRoutine(letter: 'A', name: 'Pernas');
    edit.addExercise(a, exercise('um'));
    edit.addExercise(a, exercise('dois'));
    expect(() => edit.addExercise(a, exercise('um')), throwsStateError);
    edit.moveExercise(a, 0, 1);
    expect(edit.routine(a).exercises.map((e) => e.id), ['dois', 'um']);
    edit.updateExercise(
      a,
      TrainingExercise(
        id: 'um',
        catalogExerciseId: 'catalog-um',
        name: 'Agachamento',
        muscleGroup: 'Pernas',
        sets: 4,
        repetitions: 10,
        restSeconds: 90,
      ),
    );
    expect(edit.routine(a).exercises.last.sets, 4);
    edit.removeExercise(a, 'dois');
    expect(edit.routine(a).exercises.single.id, 'um');
  });

  test('restaura rascunho, mas recusa editar uma ficha publicada', () {
    final edit = composer();
    final a = edit.addRoutine(letter: 'A', name: 'Pernas');
    edit.addExercise(a, exercise('e1'));
    edit.assignDay(1, a);
    final draft = edit.buildDraft();
    final restored = TrainingPlanComposer.fromDraft(draft);
    expect(restored.buildReadyToPublish().routines.single.id, a);
    final published = draft.copyWith(status: TrainingPlanStatus.published);
    expect(() => TrainingPlanComposer.fromDraft(published), throwsStateError);
  });

  test('rascunho resultante nao muda apos continuar editando', () {
    final edit = composer();
    final a = edit.addRoutine(letter: 'A', name: 'Pernas');
    edit.addExercise(a, exercise('e1'));
    final snapshot = edit.buildDraft();
    edit.addExercise(a, exercise('e2'));
    expect(snapshot.routines.single.exercises.length, 1);
    expect(edit.buildDraft().routines.single.exercises.length, 2);
  });
}
