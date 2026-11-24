import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/aluno_home_view.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';
import 'package:academiagrazi/view/user/aluno_treino_em_casa_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User])
import 'aluno_home_view_test.mocks.dart';

// Segunda, 02/11/2026, 10:00: dia do Treino A.
final _monday = DateTime(2026, 11, 2, 10);

TrainingRoutine _routine(String id, String name, String focus) =>
    TrainingRoutine(
      id: id,
      letter: id.substring(id.length - 1).toUpperCase(),
      name: name,
      focus: focus,
      estimatedMinutes: 40,
      exercises: const [
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
    );

TrainingPlan _plan() => TrainingPlan(
  id: 'ficha-1',
  studentId: 'aluno-1',
  instructorId: 'prof-1',
  name: 'Ficha semanal',
  version: 1,
  status: TrainingPlanStatus.published,
  weeklySchedule: const {DateTime.monday: 'treino-a'},
  routines: [_routine('treino-a', 'Treino A', 'Pernas e glúteos')],
);

TrainingSession _session(
  String id,
  DateTime finishedAt, {
  TrainingSessionStatus status = TrainingSessionStatus.finished,
}) => TrainingSession(
  id: id,
  studentId: 'aluno-1',
  instructorId: 'prof-1',
  planId: 'ficha-1',
  planVersion: 1,
  routineId: 'treino-a',
  routineName: 'Treino A',
  status: status,
  startedAt: finishedAt.subtract(const Duration(minutes: 40)).toUtc(),
  finishedAt:
      status == TrainingSessionStatus.finished ? finishedAt.toUtc() : null,
  warmupDone: true,
  exercises: const [],
);

PhysicalEvaluation _evaluation(DateTime date, double weightKg) =>
    PhysicalEvaluation(
      date: date,
      instructorId: 'prof-1',
      sex: BiologicalSex.female,
      age: 30,
      weightKg: weightKg,
      heightCm: 165,
      skinfolds: const Skinfolds(
        chest: 10,
        midaxillary: 10,
        triceps: 10,
        subscapular: 10,
        abdominal: 10,
        suprailiac: 10,
        thigh: 10,
      ),
    );

void main() {
  late FakeFirebaseFirestore db;
  late DateTime now;

  DocumentRefs student() => DocumentRefs(db);

  setUp(() async {
    locator.reset();
    db = FakeFirebaseFirestore();
    now = _monday;
    final auth = MockFirebaseAuth();
    final user = MockUser();
    when(user.uid).thenReturn('aluno-1');
    when(auth.currentUser).thenReturn(user);

    final users = RegisterUserService(db: db);
    final plans = TrainingPlanService(db: db);
    locator.registerSingleton<FirebaseAuth>(auth);
    locator.registerSingleton<RegisterUserService>(users);
    locator.registerSingleton<TrainingPlanService>(plans);
    locator.registerSingleton<TrainingSessionService>(
      TrainingSessionService(db: db, planService: plans, clock: () => now),
    );
    locator.registerSingleton<HomeWorkoutService>(HomeWorkoutService(db: db));
    locator.registerSingleton<StudentTrainingViewDataService>(
      StudentTrainingViewDataService(
        planService: plans,
        userService: users,
        clock: () => now,
      ),
    );
    locator.registerSingleton<PhysicalEvaluationService>(
      PhysicalEvaluationService(db: db),
    );
    locator.registerSingleton<GymClassService>(GymClassService(db: db));

    await db.collection('users').doc('aluno-1').set({
      'type': 'user',
      'name': 'Ana Souza',
      'email': 'ana@example.com',
      'responsable': 'prof-1',
      'unitId': 'bloco-a',
    });
    await db.collection('users').doc('prof-1').set({
      'type': 'instructor',
      'name': 'Grazi Braz',
      'email': 'prof@example.com',
    });
  });

  tearDown(() => locator.reset());

  Future<void> pumpHome(
    WidgetTester tester, {
    VoidCallback? onOpenTrainings,
    VoidCallback? onOpenEvolution,
    VoidCallback? onOpenProfile,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AlunoHomeView(
          onOpenTrainings: onOpenTrainings,
          onOpenEvolution: onOpenEvolution,
          onOpenProfile: onOpenProfile,
          clock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem ficha mostra que o professor ainda vai montar o treino', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('texto_aguardando_treino')), findsOneWidget);
    expect(find.byKey(const Key('botao_iniciar_treino')), findsNothing);
    expect(find.text('Grazi Braz'), findsOneWidget);
    expect(find.text('0 semanas'), findsOneWidget);
    expect(
      find.text('Sua primeira avaliação física vai aparecer aqui.'),
      findsOneWidget,
    );
    expect(
      find.text('Sua unidade ainda não tem aulas na grade.'),
      findsOneWidget,
    );
  });

  testWidgets('com ficha mostra o treino do dia e abre a execução', (
    tester,
  ) async {
    await student().putActivePlan(_plan());
    await pumpHome(tester);

    expect(find.text('TREINO A'), findsOneWidget);
    expect(find.text('Pernas e glúteos'), findsOneWidget);
    expect(find.text('1 exercícios  •  40 min previstos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_iniciar_treino')));
    await tester.pumpAndSettle();
    expect(find.byType(AlunoSessaoTreinoView), findsOneWidget);
  });

  testWidgets('treino em andamento hoje oferece retomar', (tester) async {
    await student().putActivePlan(_plan());
    await student().putSession(
      _session('aberta', _monday, status: TrainingSessionStatus.inProgress),
    );
    await pumpHome(tester);

    expect(find.byKey(const Key('botao_retomar_treino')), findsOneWidget);
    expect(find.byKey(const Key('botao_iniciar_treino')), findsNothing);
  });

  testWidgets('treino de hoje finalizado aparece como concluído', (
    tester,
  ) async {
    await student().putActivePlan(_plan());
    await student().putSession(
      _session('feita', _monday.subtract(const Duration(hours: 1))),
    );
    await pumpHome(tester);

    expect(find.byKey(const Key('texto_treino_concluido')), findsOneWidget);
    expect(find.byKey(const Key('botao_iniciar_treino')), findsNothing);
    expect(find.text('1 semana'), findsOneWidget);
  });

  testWidgets('dia sem treino programado é dia de descanso', (tester) async {
    await student().putActivePlan(_plan());
    now = DateTime(2026, 11, 3, 10); // terça
    var openedTrainings = 0;
    await pumpHome(tester, onOpenTrainings: () => openedTrainings++);

    expect(find.byKey(const Key('texto_dia_descanso')), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_ver_treinos')));
    expect(openedTrainings, 1);
  });

  testWidgets('mostra sequência, variação de peso e próxima aula reais', (
    tester,
  ) async {
    await student().putSession(_session('s1', DateTime(2026, 10, 28, 18)));
    await student().putSession(_session('s2', DateTime(2026, 10, 21, 18)));
    await student().putEvaluation(_evaluation(DateTime(2026, 8, 1), 70));
    await student().putEvaluation(_evaluation(DateTime(2026, 10, 1), 68.2));
    await db
        .collection('gym_classes')
        .add(
          const GymClassModel(
            id: '',
            name: 'Pilates',
            unitId: 'bloco-a',
            weekday: DateTime.monday,
            startTime: '18:00',
            durationMinutes: 50,
            active: true,
          ).toJson(),
        );
    await db
        .collection('gym_classes')
        .add(
          const GymClassModel(
            id: '',
            name: 'Spinning',
            unitId: 'outro-bloco',
            weekday: DateTime.monday,
            startTime: '12:00',
            durationMinutes: 50,
            active: true,
          ).toJson(),
        );
    await pumpHome(tester);

    expect(find.text('2 semanas'), findsOneWidget);
    expect(find.text('Você está on fire!'), findsOneWidget);
    expect(find.text('-1,8 kg'), findsOneWidget);
    expect(find.text('PILATES'), findsOneWidget);
    expect(find.text('Hoje às 18:00'), findsOneWidget);
    expect(find.text('SPINNING'), findsNothing);
  });

  testWidgets('atalhos levam à saúde e à avaliação; aulas não aparece', (
    tester,
  ) async {
    var profile = 0;
    var evolution = 0;
    await pumpHome(
      tester,
      onOpenProfile: () => profile++,
      onOpenEvolution: () => evolution++,
    );

    expect(find.text('Aulas'), findsNothing);
    expect(find.byKey(const Key('botao_atalho_treino_em_casa')), findsNothing);
    await tester.tap(find.byKey(const Key('botao_atalho_saude')));
    await tester.tap(find.byKey(const Key('botao_atalho_avaliacao')));
    expect(profile, 1);
    expect(evolution, 1);
  });

  testWidgets('com treino em casa o atalho abre a lista de treinos em casa', (
    tester,
  ) async {
    await student().putHomeWorkout(
      HomeWorkoutPlan(
        studentId: 'aluno-1',
        instructorId: 'prof-1',
        version: 1,
        routines: [_routine('casa-a', 'Mobilidade', 'Alongamento')],
      ),
    );
    await pumpHome(tester);

    expect(find.byKey(const Key('botao_abrir_treino_em_casa')), findsOneWidget);
    await tester.tap(find.byKey(const Key('botao_atalho_treino_em_casa')));
    await tester.pumpAndSettle();
    expect(find.byType(AlunoTreinoEmCasaView), findsOneWidget);
  });
}

/// Grava os dados do aluno de teste nas mesmas coleções que o app lê.
class DocumentRefs {
  final FakeFirebaseFirestore db;

  DocumentRefs(this.db);

  DocumentReference<Map<String, dynamic>> get _student =>
      db.collection('users').doc('aluno-1');

  Future<void> putActivePlan(TrainingPlan plan) async {
    await _student.collection('trainingPlans').doc(plan.id).set(plan.toMap());
    await _student.collection('trainingState').doc('current').set({
      'activePlanId': plan.id,
      'instructorId': plan.instructorId,
    });
  }

  Future<void> putSession(TrainingSession session) => _student
      .collection('trainingSessions')
      .doc(session.id)
      .set(session.toMap());

  Future<void> putEvaluation(PhysicalEvaluation evaluation) =>
      _student.collection('evaluations').add(evaluation.toJson());

  Future<void> putHomeWorkout(HomeWorkoutPlan plan) =>
      _student.collection('homeWorkouts').doc('current').set(plan.toMap());
}
