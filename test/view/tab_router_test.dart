import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:academiagrazi/view/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:academiagrazi/controller/users/update_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/view/tab_router.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';

@GenerateMocks([
  RegisterUserService,
  UpdateDataController,
  PreferencesService,
  FirebaseAuth,
  User,
])
import 'tab_router_test.mocks.dart';

void main() {
  late MockUpdateDataController mockUpdateDataController;
  late MockPreferencesService mockPreferencesService;
  late MockRegisterUserService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockFirebaseUser;
  late void Function(FlutterErrorDetails)? previousFlutterError;

  /// Ficha com o Treino A em todos os dias, para a Home sempre ter o treino
  /// do dia, qualquer que seja a data em que o teste roda.
  Future<void> registerTrainingServices() async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('uid_test').set({
      'type': 'user',
      'name': 'Test User',
      'email': 'test@bigtech.com',
      'responsable': 'prof-1',
    });
    final plan = TrainingPlan(
      id: 'ficha-1',
      studentId: 'uid_test',
      instructorId: 'prof-1',
      name: 'Ficha semanal',
      version: 1,
      status: TrainingPlanStatus.published,
      weeklySchedule: {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          day: 'treino-a',
      },
      routines: [
        TrainingRoutine(
          id: 'treino-a',
          letter: 'A',
          name: 'Treino A',
          focus: 'Pernas',
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
        ),
      ],
    );
    final student = db.collection('users').doc('uid_test');
    await student.collection('trainingPlans').doc(plan.id).set(plan.toMap());
    await student.collection('trainingState').doc('current').set({
      'activePlanId': plan.id,
      'instructorId': plan.instructorId,
    });

    final plans = TrainingPlanService(db: db);
    locator.registerSingleton<TrainingPlanService>(plans);
    locator.registerSingleton<TrainingSessionService>(
      TrainingSessionService(db: db, planService: plans),
    );
    locator.registerSingleton<HomeWorkoutService>(HomeWorkoutService(db: db));
    locator.registerSingleton<StudentTrainingViewDataService>(
      StudentTrainingViewDataService(
        planService: plans,
        userService: RegisterUserService(db: db),
      ),
    );
    locator.registerSingleton<GymClassService>(GymClassService(db: db));
  }

  setUp(() async {
    await locator.reset();
    locator.allowReassignment = true;

    mockUserService = MockRegisterUserService();
    mockPreferencesService = MockPreferencesService();
    mockAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();
    mockUpdateDataController = MockUpdateDataController();

    locator.registerSingleton<UpdateDataController>(mockUpdateDataController);
    locator.registerSingleton<RegisterUserService>(mockUserService);
    locator.registerSingleton<FirebaseAuth>(mockAuth);
    locator.registerSingleton<PreferencesService>(mockPreferencesService);
    locator.registerSingleton<ProfilePhotoService>(
      ProfilePhotoService(cloudName: '', uploadPreset: ''),
    );
    locator.registerSingleton<PhysicalEvaluationService>(
      PhysicalEvaluationService(db: FakeFirebaseFirestore()),
    );

    when(mockFirebaseUser.uid).thenReturn('uid_test');
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockPreferencesService.dailyReminder).thenReturn(false);
    when(mockPreferencesService.professorNotices).thenReturn(true);

    await registerTrainingServices();
    when(mockUserService.watchUserById(any)).thenAnswer(
      (_) => Stream.value(
        UserModel(
          id: 'uid_test',
          name: 'Test User',
          email: 'test@bigtech.com',
          responsable: 'prof-1',
        ),
      ),
    );

    when(mockUserService.getUserById(any)).thenAnswer(
      (_) async => UserModel(
        id: 'uid_test',
        name: 'Test User',
        email: 'test@bigtech.com',
      ),
    );
  });

  tearDown(() {
    locator.reset();
  });

  void ignorePlaceholderImageError() {
    previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      previousFlutterError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousFlutterError);
  }

  testWidgets('mantém a NavigationBar ao abrir um treino na Home', (
    tester,
  ) async {
    ignorePlaceholderImageError();

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    expect(find.text('GRAZI BRAZ'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('botao_iniciar_treino')));

    await tester.tap(find.byKey(const Key('botao_iniciar_treino')));

    await tester.pumpAndSettle();

    expect(find.byType(AlunoSessaoTreinoView), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('volta para a Home ao selecionar Início durante um treino', (
    tester,
  ) async {
    ignorePlaceholderImageError();

    await tester.pumpWidget(MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('botao_iniciar_treino')));

    await tester.tap(find.byKey(const Key('botao_iniciar_treino')));

    await tester.pumpAndSettle();
    expect(find.byType(AlunoSessaoTreinoView), findsOneWidget);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    expect(find.byType(AlunoSessaoTreinoView), findsNothing);
    expect(find.text('GRAZI BRAZ'), findsOneWidget);
    expect(find.text('TREINO DO DIA'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('alterna entre as páginas sem remover a NavigationBar', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: MainShell()));

    await tester.tap(find.text('Treinos'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.text('Evolução'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('admin vê Equipe no lugar de Evolução', (tester) async {
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: FakeFirebaseFirestore()),
    );
    locator.registerSingleton<AdminStudentService>(
      AdminStudentService(db: FakeFirebaseFirestore()),
    );

    await tester.pumpWidget(const MaterialApp(home: MainShell(isAdmin: true)));
    await tester.pumpAndSettle();

    expect(find.text('Evolução'), findsNothing);
    expect(find.text('VISÃO GERAL / Hoje'), findsOneWidget);

    await tester.tap(find.text('Equipe').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('EQUIPE / Carga dos professores'), findsOneWidget);
  });

  testWidgets('admin vê Alunos no lugar de Treinos', (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('a1').set({
      'name': 'Ana Lima',
      'email': 'ana@test.com',
      'type': 'user',
    });
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: db),
    );
    locator.registerSingleton<AdminStudentService>(AdminStudentService(db: db));

    await tester.pumpWidget(const MaterialApp(home: MainShell(isAdmin: true)));
    await tester.pumpAndSettle();

    expect(find.text('Treinos'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin_tab_alunos')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('Ana Lima'), findsOneWidget);
  });
}
