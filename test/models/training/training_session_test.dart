import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan publishedPlan() => TrainingPlan(
  id: 'ficha-1',
  studentId: 'aluno-1',
  instructorId: 'prof-1',
  name: 'Ficha A/B',
  version: 2,
  status: TrainingPlanStatus.published,
  weeklySchedule: const {1: 'treino-a'},
  routines: [
    TrainingRoutine(
      id: 'treino-a',
      letter: 'A',
      name: 'Treino A',
      focus: 'Pernas',
      estimatedMinutes: 40,
      exercises: [
        TrainingExercise(
          id: 'item-1',
          catalogExerciseId: 'c1',
          name: 'Agachamento',
          muscleGroup: 'Pernas',
          sets: 3,
          repetitions: 12,
          restSeconds: 60,
          targetLoadKg: 20,
        ),
      ],
    ),
  ],
);

void main() {
  final begin = DateTime.utc(2026, 11, 6, 15);

  TrainingSession newSession() {
    final plan = publishedPlan();
    return TrainingSession.fromRoutine(
      sessionId: 'sessao-1',
      plan: plan,
      routine: plan.routines.first,
      startedAt: begin,
    );
  }

  test('cria sessao com snapshot e series inicialmente pendentes', () {
    final session = newSession();
    expect(session.planVersion, 2);
    expect(session.totalSets, 3);
    expect(session.completedSets, 0);
    expect(session.exercises.single.suggestedLoadKg, 20);
    expect(session.exercises.single.sets.first.loadKg, isNull);
    expect(session.status, TrainingSessionStatus.inProgress);
  });

  test('registra carga, permite desfazer e calcula progresso', () {
    final session = newSession()
        .updateSet(
          exerciseItemId: 'item-1',
          setNumber: 1,
          completed: true,
          loadKg: 22.5,
        )
        .updateSet(
          exerciseItemId: 'item-1',
          setNumber: 2,
          completed: true,
          loadKg: 25,
        );
    expect(session.completedSets, 2);
    expect(session.completedExercises, 0);
    expect(session.exercises.single.sets.first.loadKg, 22.5);
    expect(
      session
          .updateSet(exerciseItemId: 'item-1', setNumber: 2, completed: false)
          .completedSets,
      1,
    );
  });

  test('serializa e restaura status, horario e valores executados', () {
    final session = newSession()
        .markWarmup(true)
        .updateSet(
          exerciseItemId: 'item-1',
          setNumber: 1,
          completed: true,
          loadKg: 20,
        );
    final restored = TrainingSession.fromMap(session.toMap(), session.id);
    expect(restored.startedAt, begin);
    expect(restored.warmupDone, isTrue);
    expect(restored.completedSets, 1);
    expect(restored.exercises.single.sets.first.loadKg, 20);
  });

  test('nao finaliza sem serie realizada ou horario valido', () {
    expect(
      () => newSession().finishAt(begin.add(const Duration(minutes: 5))),
      throwsStateError,
    );
    final session = newSession().updateSet(
      exerciseItemId: 'item-1',
      setNumber: 1,
      completed: true,
    );
    expect(
      () => session.finishAt(begin.subtract(const Duration(minutes: 1))),
      throwsStateError,
    );
  });

  test('sessao finalizada preserva historico e nao aceita edicao', () {
    final session = newSession()
        .updateSet(
          exerciseItemId: 'item-1',
          setNumber: 1,
          completed: true,
          loadKg: 25,
        )
        .finishAt(begin.add(const Duration(minutes: 25)));
    expect(session.status, TrainingSessionStatus.finished);
    expect(session.finishedAt, begin.add(const Duration(minutes: 25)));
    expect(
      () => session.updateSet(
        exerciseItemId: 'item-1',
        setNumber: 1,
        completed: false,
      ),
      throwsStateError,
    );
    expect(() => session.markWarmup(true), throwsStateError);
    expect(
      TrainingSession.fromMap(session.toMap(), session.id).finishedAt,
      session.finishedAt,
    );
  });

  test('recusa indices, carga e exercicio invalidos', () {
    final session = newSession();
    expect(
      () => session.updateSet(
        exerciseItemId: 'item-1',
        setNumber: 8,
        completed: true,
      ),
      throwsRangeError,
    );
    expect(
      () => session.updateSet(
        exerciseItemId: 'item-1',
        setNumber: 1,
        completed: true,
        loadKg: -1,
      ),
      throwsArgumentError,
    );
    expect(
      () => session.updateSet(
        exerciseItemId: 'outro',
        setNumber: 1,
        completed: true,
      ),
      throwsStateError,
    );
  });
}
