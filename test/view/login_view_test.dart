import 'package:academiagrazi/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:academiagrazi/service/users/register_user.dart';

import 'package:academiagrazi/view/login_view.dart';

@GenerateMocks([
  LoginController,
  FirebaseAuth,
  RegisterUserService,
  RegisterUserController,
  RegisterInstructorController,
])
import 'login_view_test.mocks.dart';

void main() {
  late MockLoginController mockLoginController;
  late MockFirebaseAuth mockAuth;
  late MockRegisterUserService mockRegisterUserService;
  late MockRegisterUserController mockRegisterUserController;
  late MockRegisterInstructorController mockRegisterInstructorController;

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;

    mockLoginController = MockLoginController();
    mockAuth = MockFirebaseAuth();
    mockRegisterUserService = MockRegisterUserService();
    mockRegisterUserController = MockRegisterUserController();
    mockRegisterInstructorController = MockRegisterInstructorController();

    locator.registerSingleton<LoginController>(mockLoginController);
    locator.registerSingleton<FirebaseAuth>(mockAuth);
    locator.registerSingleton<RegisterUserService>(mockRegisterUserService);
    locator.registerSingleton<RegisterUserController>(
      mockRegisterUserController,
    );
    locator.registerSingleton<RegisterInstructorController>(
      mockRegisterInstructorController,
    );
  });

  tearDown(() {
    locator.reset();
  });

  Future<void> pumpLoginView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    addTearDown(() => tester.view.resetPhysicalSize());
  }

  Future<void> submitLogin(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'aluno@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha123');

    final loginButton = find.text('Entrar');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  testWidgets('Substitui a LandingPage pela MainShell após login de aluno', (
    tester,
  ) async {
    when(
      mockLoginController.loginUser(
        email: 'aluno@exemplo.com',
        password: 'senha123',
      ),
    ).thenAnswer(
      (_) async => UserModel(
        id: 'user-1',
        name: 'Aluno',
        email: 'aluno@exemplo.com',
        responsable: 'test',
        type: UserType.user,
      ),
    );

    await pumpLoginView(tester);
    await submitLogin(tester);

    expect(find.byType(LoginView), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);

    expect(
      Navigator.of(tester.element(find.byType(MainShell))).canPop(),
      isFalse,
    );

    verify(
      mockLoginController.loginUser(
        email: 'aluno@exemplo.com',
        password: 'senha123',
      ),
    ).called(1);
  });

  testWidgets('Mostra snackbar de erro quando o login retorna nulo', (
    tester,
  ) async {
    when(
      mockLoginController.loginUser(
        email: 'aluno@exemplo.com',
        password: 'senha123',
      ),
    ).thenAnswer((_) async => null);

    await pumpLoginView(tester);
    await submitLogin(tester);

    expect(find.text('Falha ao entrar. Tente novamente.'), findsOneWidget);
  });

  testWidgets(
    'Valida campos vazios e permite alternar a visibilidade da senha',
    (tester) async {
      await pumpLoginView(tester);

      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Preencha todos os campos.'), findsOneWidget);

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      verifyZeroInteractions(mockLoginController);
    },
  );

  testWidgets(
    'Abre o auto cadastro público através do botão Criar minha conta',
    (tester) async {
      await pumpLoginView(tester);

      final createAccountButton = find.text('Criar minha conta');
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(find.byType(SelfRegisterView), findsOneWidget);
    },
  );

  testWidgets(
    'Alterna o modo de treino acionando rebuild da máquina de estados',
    (tester) async {
      await pumpLoginView(tester);

      expect(find.text('Presencial'), findsOneWidget);
      expect(find.text('Treino em casa'), findsOneWidget);

      await tester.tap(find.text('Treino em casa'));
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Valida fluxo de recuperação de palavra-passe com campo vazio', (
    tester,
  ) async {
    await pumpLoginView(tester);

    final forgotPasswordText = find.text('Esqueci minha senha');

    await tester.scrollUntilVisible(
      forgotPasswordText,
      -50.0,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(forgotPasswordText);

    await tester.pumpAndSettle();

    expect(
      find.text('Informe seu e-mail no campo acima para recuperar a senha.'),
      findsOneWidget,
    );

    verifyZeroInteractions(mockLoginController);
  });

  testWidgets('Aciona recuperação de palavra-passe com sucesso', (
    tester,
  ) async {
    when(
      mockLoginController.resetPassword(email: 'aluno@exemplo.com'),
    ).thenAnswer((_) async => true);

    await pumpLoginView(tester);

    await tester.enterText(find.byType(TextField).at(0), 'aluno@exemplo.com');

    final forgotPasswordText = find.text('Esqueci minha senha');

    await tester.scrollUntilVisible(
      forgotPasswordText,
      -50.0,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(forgotPasswordText);
    await tester.pumpAndSettle();

    expect(
      find.text('Um link de recuperação foi enviado para seu e-mail.'),
      findsOneWidget,
    );

    verify(
      mockLoginController.resetPassword(email: 'aluno@exemplo.com'),
    ).called(1);
  });

  testWidgets('Exibe erro ao falhar na recuperação de palavra-passe', (
    tester,
  ) async {
    when(
      mockLoginController.resetPassword(email: 'invalido@exemplo.com'),
    ).thenAnswer((_) async => false);

    await pumpLoginView(tester);

    await tester.enterText(
      find.byType(TextField).at(0),
      'invalido@exemplo.com',
    );

    final forgotPasswordText = find.text('Esqueci minha senha');

    await tester.scrollUntilVisible(
      forgotPasswordText,
      -50.0,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(forgotPasswordText);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível processar a solicitação. Verifique o e-mail.',
      ),
      findsOneWidget,
    );

    verify(
      mockLoginController.resetPassword(email: 'invalido@exemplo.com'),
    ).called(1);
  });
}
