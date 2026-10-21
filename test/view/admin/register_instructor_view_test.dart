import 'package:academiagrazi/controller/users/register_instructor.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  RegisterInstructorController,
  RegisterUserService,
  FirebaseAuth,
  User,
])
import 'register_instructor_view_test.mocks.dart';

void main() {
  late MockRegisterInstructorController mockController;
  late MockRegisterUserService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockFirebaseUser;

  final admin = UserModel(
    id: 'admin_1',
    name: 'Grazi',
    email: 'admin@grazi.com',
    type: UserType.admin,
  );

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;

    mockController = MockRegisterInstructorController();
    mockUserService = MockRegisterUserService();
    mockAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();

    locator.registerSingleton<RegisterInstructorController>(mockController);
    locator.registerSingleton<RegisterUserService>(mockUserService);
    locator.registerSingleton<FirebaseAuth>(mockAuth);

    when(mockFirebaseUser.uid).thenReturn('admin_1');
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockUserService.getUserById('admin_1')).thenAnswer((_) async => admin);
  });

  tearDown(() => locator.reset());

  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Marina Souza',
    String email = 'marina@email.com',
    String password = '123456',
    String confirm = '123456',
  }) async {
    await tester.enterText(find.byKey(const Key('campo_nome_professor')), name);
    await tester.enterText(
      find.byKey(const Key('campo_email_professor')),
      email,
    );
    await tester.enterText(
      find.byKey(const Key('campo_senha_professor')),
      password,
    );
    await tester.enterText(
      find.byKey(const Key('campo_confirmar_senha_professor')),
      confirm,
    );
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.byKey(const Key('botao_cadastrar_professor'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('mostra textos voltados ao cadastro do professor', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterInstructorView()));

    expect(find.text('CADASTRAR PROFESSOR'), findsWidgets);
    expect(find.text('Dados do professor'), findsOneWidget);
    expect(find.text('Já tenho cadastro'), findsNothing);
  });

  testWidgets('valida os campos antes de cadastrar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterInstructorView()));

    await fillForm(
      tester,
      name: '',
      email: 'email-invalido',
      password: '123',
      confirm: '321',
    );
    await submit(tester);

    expect(find.text('Informe o nome do professor.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('As senhas não são iguais.'), findsOneWidget);
    verifyNever(
      mockController.registerInstructor(
        currentUser: anyNamed('currentUser'),
        email: anyNamed('email'),
        name: anyNamed('name'),
        password: anyNamed('password'),
        passwordCheck: anyNamed('passwordCheck'),
      ),
    );
  });

  testWidgets('cadastra o professor e permite cadastrar outro', (tester) async {
    when(
      mockController.registerInstructor(
        currentUser: anyNamed('currentUser'),
        email: anyNamed('email'),
        name: anyNamed('name'),
        password: anyNamed('password'),
        passwordCheck: anyNamed('passwordCheck'),
      ),
    ).thenAnswer((_) async => InstructorRegistrationResult.success);

    await tester.pumpWidget(const MaterialApp(home: RegisterInstructorView()));

    await fillForm(tester);
    await submit(tester);

    verify(
      mockController.registerInstructor(
        currentUser: admin,
        email: 'marina@email.com',
        name: 'Marina Souza',
        password: '123456',
        passwordCheck: '123456',
      ),
    ).called(1);
    expect(find.text('Professor cadastrado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_cadastrar_outro')));
    await tester.pumpAndSettle();

    expect(find.text('Professor cadastrado'), findsNothing);
    expect(find.text('Marina Souza'), findsNothing);
  });

  testWidgets('avisa quando o cadastro falha', (tester) async {
    when(
      mockController.registerInstructor(
        currentUser: anyNamed('currentUser'),
        email: anyNamed('email'),
        name: anyNamed('name'),
        password: anyNamed('password'),
        passwordCheck: anyNamed('passwordCheck'),
      ),
    ).thenAnswer((_) async => InstructorRegistrationResult.emailInUse);

    await tester.pumpWidget(const MaterialApp(home: RegisterInstructorView()));

    await fillForm(tester);
    await submit(tester);

    expect(find.text('Já existe uma conta com esse e-mail.'), findsOneWidget);
    expect(find.text('Professor cadastrado'), findsNothing);
  });
}
