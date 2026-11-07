import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan sampleDraft(String instructorId) => TrainingPlan(
  id: '',
  studentId: 'aluno-1',
  instructorId: instructorId,
  name: 'Ficha A/B',
  version: 1,
  status: TrainingPlanStatus.draft,
  weeklySchedule: {1: 'treino-a', 2: null, 3: 'treino-a'},
  routines: [
    TrainingRoutine(
      id: 'treino-a',
      letter: 'A',
      name: 'Treino A',
      focus: 'Pernas',
      estimatedMinutes: 45,
      exercises: [
        TrainingExercise(
          id: 'item-1',
          catalogExerciseId: 'catalog-1',
          name: 'Agachamento',
          muscleGroup: 'Pernas',
          sets: 3,
          repetitions: 12,
          restSeconds: 60,
        ),
      ],
    ),
  ],
);

void main() {
  late FakeFirebaseFirestore firestore;
  late TrainingPlanService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = TrainingPlanService(db: firestore);
    await firestore.collection('users').doc('aluno-1').set({
      'type': 'user',
      'responsable': 'prof-1',
      'name': 'Aluno',
    });
  });

  test('cria rascunho vinculado e publica para o aluno', () async {
    expect(await service.getActivePlan('aluno-1'), isNull);
    final id = await service.createDraft(sampleDraft('prof-1'));
    expect(id, isNotEmpty);
    expect(await service.getActivePlan('aluno-1'), isNull);

    await service.publishDraft(
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      planId: id,
    );
    final active = await service.getActivePlan('aluno-1');
    expect(active, isNotNull);
    expect(active!.id, id);
    expect(active.status, TrainingPlanStatus.published);
    expect(active.weeklySchedule[1], 'treino-a');
  });

  test('impede que professor nao vinculado crie ficha', () async {
    await expectLater(
      service.createDraft(sampleDraft('prof-errado')),
      throwsStateError,
    );
  });

  test('impede republicar ou editar ficha ja publicada', () async {
    final id = await service.createDraft(sampleDraft('prof-1'));
    await service.publishDraft(
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      planId: id,
    );
    await expectLater(
      service.saveDraft(sampleDraft('prof-1').copyWith(id: id)),
      throwsStateError,
    );
    await expectLater(
      service.publishDraft(
        studentId: 'aluno-1',
        instructorId: 'prof-1',
        planId: id,
      ),
      throwsStateError,
    );
  });

  test('salva edicao de rascunho e incrementa versao', () async {
    final id = await service.createDraft(sampleDraft('prof-1'));
    await service.saveDraft(sampleDraft('prof-1').copyWith(id: id));
    final doc =
        await firestore
            .collection('users')
            .doc('aluno-1')
            .collection('trainingPlans')
            .doc(id)
            .get();
    expect(doc.data()?['version'], 2);
  });

  test('nao publica ficha com calendario invalido', () async {
    final draft = TrainingPlan(
      id: '',
      studentId: 'aluno-1',
      instructorId: 'prof-1',
      name: 'Invalida',
      version: 1,
      status: TrainingPlanStatus.draft,
      weeklySchedule: {1: 'nao-existe'},
      routines: sampleDraft('prof-1').routines,
    );
    final id = await service.createDraft(draft);
    await expectLater(
      service.publishDraft(
        studentId: 'aluno-1',
        instructorId: 'prof-1',
        planId: id,
      ),
      throwsStateError,
    );
  });
}
