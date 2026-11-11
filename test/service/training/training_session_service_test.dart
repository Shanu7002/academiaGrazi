import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan _plan() => TrainingPlan(
  id: 'ficha-1',
  studentId: 'aluno-1',
  instructorId: 'prof-1',
  name: 'Ficha semanal',
  version: 3,
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
          catalogExerciseId: 'exercicio-1',
          name: 'Agachamento',
          muscleGroup: 'Pernas',
          sets: 3,
          repetitions: 12,
          restSeconds: 60,
        ),
      ],
    ),
    TrainingRoutine(
      id: 'treino-b',
      letter: 'B',
      name: 'Treino B',
      focus: 'Costas',
      estimatedMinutes: 35,
      exercises: [
        TrainingExercise(
          id: 'item-2',
          catalogExerciseId: 'exercicio-2',
          name: 'Remada',
          muscleGroup: 'Costas',
          sets: 2,
          repetitions: 10,
          restSeconds: 60,
        ),
      ],
    ),
  ],
);

void main() {
  late FakeFirebaseFirestore db;
  late TrainingSessionService service;
  final start = DateTime.utc(2026, 11, 6, 15);
  var currentTime = start;

  setUp(() async {
    db = FakeFirebaseFirestore();
    currentTime = start;
    service = TrainingSessionService(
      db: db,
      planService: TrainingPlanService(db: db),
      clock: () => currentTime,
    );
    await db.collection('users').doc('aluno-1').set({
      'type': 'user',
      'name': 'Ana',
      'responsable': 'prof-1',
    });
    final plan = _plan();
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingPlans')
        .doc(plan.id)
        .set(plan.toMap());
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingState')
        .doc('current')
        .set({'activePlanId': plan.id, 'instructorId': plan.instructorId});
  });

  test('inicia uma sessao somente de ficha ativa publicada', () async {
    final created = await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-1',
    );
    expect(created.planVersion, 3);
    expect(created.status, TrainingSessionStatus.inProgress);
    expect(created.totalSets, 3);
    expect(
      (await service.getSession('aluno-1', 'sessao-1'))?.planId,
      'ficha-1',
    );
  });

  test('retoma sessao aberta sem criar documento duplicado', () async {
    await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-1',
    );
    final reopened = await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-2',
    );
    expect(reopened.id, 'sessao-1');
    final docs =
        await db
            .collection('users')
            .doc('aluno-1')
            .collection('trainingSessions')
            .get();
    expect(docs.docs.length, 1);
  });

  test('nao permite iniciar outro treino com sessao pendente', () async {
    await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-1',
    );
    await expectLater(
      service.startSession(
        studentId: 'aluno-1',
        planId: 'ficha-1',
        routineId: 'treino-b',
      ),
      throwsStateError,
    );
  });

  test('registra carga por serie, aquecimento e finaliza', () async {
    await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-1',
    );
    final marked = await service.recordSet(
      studentId: 'aluno-1',
      sessionId: 'sessao-1',
      exerciseItemId: 'item-1',
      setNumber: 1,
      completed: true,
      loadKg: 27.5,
    );
    expect(marked.completedSets, 1);
    expect(marked.exercises.single.sets.first.loadKg, 27.5);
    expect(
      (await service.setWarmup(
        studentId: 'aluno-1',
        sessionId: 'sessao-1',
        done: true,
      )).warmupDone,
      isTrue,
    );
    currentTime = start.add(const Duration(minutes: 32));
    final finished = await service.finishSession(
      studentId: 'aluno-1',
      sessionId: 'sessao-1',
    );
    expect(finished.status, TrainingSessionStatus.finished);
    expect(
      (await service.getSession('aluno-1', 'sessao-1'))?.finishedAt,
      currentTime,
    );
    expect(await service.getInProgress('aluno-1'), isNull);
    await expectLater(
      service.recordSet(
        studentId: 'aluno-1',
        sessionId: 'sessao-1',
        exerciseItemId: 'item-1',
        setNumber: 2,
        completed: true,
      ),
      throwsStateError,
    );
  });

  test('nao inicia treino de ficha inativa ou treino inexistente', () async {
    await expectLater(
      service.startSession(
        studentId: 'aluno-1',
        planId: 'outra',
        routineId: 'treino-a',
      ),
      throwsStateError,
    );
    await expectLater(
      service.startSession(
        studentId: 'aluno-1',
        planId: 'ficha-1',
        routineId: 'nao-existe',
      ),
      throwsStateError,
    );
  });

  test('retorna historico ordenado sem alterar a ficha publicada', () async {
    await service.startSession(
      studentId: 'aluno-1',
      planId: 'ficha-1',
      routineId: 'treino-a',
      sessionId: 'sessao-1',
    );
    await service.recordSet(
      studentId: 'aluno-1',
      sessionId: 'sessao-1',
      exerciseItemId: 'item-1',
      setNumber: 1,
      completed: true,
    );
    currentTime = start.add(const Duration(minutes: 20));
    await service.finishSession(studentId: 'aluno-1', sessionId: 'sessao-1');
    final history = await service.watchHistory('aluno-1').first;
    expect(history.length, 1);
    expect(history.single.id, 'sessao-1');
    final plan =
        await db
            .collection('users')
            .doc('aluno-1')
            .collection('trainingPlans')
            .doc('ficha-1')
            .get();
    expect(plan.data()?['status'], 'published');
  });
}
