import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/service/users/register.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/login_view.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';

@GenerateMocks([
  LoginController,
  RegisterUserController,
  RegisterInstructorController,
  RegisterService,
  FirebaseAuth,
])
import 'login_view_test.mocks.dart';

void main() {
  late MockLoginController mockLoginController;
  late MockRegisterUserController mockRegisterUserController;
  late MockRegisterInstructorController mockRegisterInstructorController;
  late MockRegisterService mockUserService;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockLoginController = MockLoginController();
    mockRegisterUserController = MockRegisterUserController();
    mockRegisterInstructorController = MockRegisterInstructorController();
    mockUserService = MockRegisterService();
    mockAuth = MockFirebaseAuth();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          loginController: mockLoginController,
          registerUserController: mockRegisterUserController,
          registerInstructorController: mockRegisterInstructorController,
          userService: mockUserService,
          authInstance: mockAuth,
        ),
      ),
    );
  }

  Future<void> submitLogin(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'aluno@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
  }

  testWidgets('substitui o login pela MainShell após login de aluno', (
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

    await pumpLogin(tester);
    await submitLogin(tester);

    expect(find.byType(LoginView), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Grazi Braz'), findsOneWidget);
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

  testWidgets('mostra erro quando o login não retorna usuário', (tester) async {
    when(
      mockLoginController.loginUser(
        email: 'aluno@exemplo.com',
        password: 'senha123',
      ),
    ).thenAnswer((_) async => null);

    await pumpLogin(tester);
    await submitLogin(tester);

    expect(find.text('Falha ao entrar. Tente novamente.'), findsOneWidget);
  });

  testWidgets('valida campos vazios e permite alternar a senha', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(find.text('Preencha todos os campos.'), findsOneWidget);

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();

    verifyNever(
      mockLoginController.loginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });

  testWidgets('abre o auto cadastro público pelo login', (tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.byKey(const Key('createAccountButton')));
    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pumpAndSettle();

    expect(find.byType(SelfRegisterView), findsOneWidget);
    expect(find.text('CONTA & ACESSO'), findsOneWidget);
  });
}
