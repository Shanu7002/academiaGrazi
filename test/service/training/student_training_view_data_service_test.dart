import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingPlan _plan({
  String studentId = 'aluno-1',
  String instructorId = 'prof-1',
  TrainingPlanStatus status = TrainingPlanStatus.published,
}) => TrainingPlan(
  id: 'ficha-1',
  studentId: studentId,
  instructorId: instructorId,
  name: 'Ficha de novembro',
  version: 1,
  status: status,
  weeklySchedule: {DateTime.monday: 'treino-a', DateTime.tuesday: null},
  routines: [
    TrainingRoutine(
      id: 'treino-a',
      letter: 'A',
      name: 'Treino A - Pernas',
      focus: 'Pernas',
      estimatedMinutes: 40,
      exercises: [
        TrainingExercise(
          id: 'item-agachamento',
          catalogExerciseId: 'catalog-agachamento',
          name: 'Agachamento',
          muscleGroup: 'Pernas',
          sets: 3,
          repetitions: 12,
          restSeconds: 70,
          instructions: 'Postura reta',
          targetLoadKg: 12,
        ),
      ],
    ),
  ],
);

void main() {
  late FakeFirebaseFirestore db;
  late StudentTrainingViewDataService service;

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = StudentTrainingViewDataService(
      planService: TrainingPlanService(db: db),
      userService: RegisterUserService(db: db),
      clock: () => DateTime(2026, 11, 2), // segunda
    );
    await db.collection('users').doc('aluno-1').set({
      'type': 'user',
      'name': 'Ana',
      'email': 'ana@example.com',
      'responsable': 'prof-1',
    });
    await db.collection('users').doc('prof-1').set({
      'type': 'instructor',
      'name': 'Grazi',
      'email': 'prof@example.com',
    });
  });

  Future<void> putActivePlan(TrainingPlan plan) async {
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingPlans')
        .doc('ficha-1')
        .set(plan.toMap());
    await db
        .collection('users')
        .doc('aluno-1')
        .collection('trainingState')
        .doc('current')
        .set({'activePlanId': 'ficha-1', 'instructorId': 'prof-1'});
  }

  test('sem ficha publicada retorna estado vazio (null)', () async {
    expect(await service.getActiveUiData('aluno-1'), isNull);
  });

  test(
    'converte ficha real em Treino A recomendado e identifica professor',
    () async {
      await putActivePlan(_plan());
      final result = await service.getActiveUiData('aluno-1');
      expect(result, isNotNull);
      expect(result!.alunoNome, 'Ana');
      expect(result.professorNome, 'Grazi');
      expect(result.treinos.single.status, TreinoStatusUi.recomendado);
      expect(result.treinos.single.exercicios.single.series, '3x12');
      expect(result.treinoDiaPorId['treino-a']!.professorNome, 'Grazi');
    },
  );

  test('rascunho nunca aparece na aba do aluno', () async {
    await putActivePlan(_plan(status: TrainingPlanStatus.draft));
    expect(await service.getActiveUiData('aluno-1'), isNull);
  });

  test('bloqueia ficha de outro professor mesmo se houver ponteiro', () async {
    await putActivePlan(_plan(instructorId: 'prof-antigo'));
    await expectLater(
      service.getActiveUiData('aluno-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('reage quando nova ficha e publicada no Firestore', () async {
    final result = service
        .watchActiveUiData('aluno-1')
        .firstWhere((data) => data != null);
    await putActivePlan(_plan());
    final updated = await result.timeout(const Duration(seconds: 3));
    expect(updated!.treinos.single.letra, 'A');
  });

  test('nao permite consulta com id de aluno vazio', () {
    expect(() => service.getActiveUiData(''), throwsArgumentError);
    expect(() => service.watchActiveUiData(' '), throwsArgumentError);
  });
}
