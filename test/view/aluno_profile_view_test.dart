import 'package:academiagrazi/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:academiagrazi/controller/users/update_data.dart';

import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:academiagrazi/view/preferences_service.dart';

@GenerateMocks([
  RegisterUserService,
  UpdateDataController,
  PreferencesService,
  FirebaseAuth,
  User,
])
import 'aluno_profile_view_test.mocks.dart';

void main() {
  late MockUpdateDataController mockUpdateDataController;
  late MockRegisterUserService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockFirebaseUser;
  late MockPreferencesService mockPreferencesService;

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;

    mockUpdateDataController = MockUpdateDataController();
    mockUserService = MockRegisterUserService();
    mockAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();
    mockPreferencesService = MockPreferencesService();

    locator.registerSingleton<RegisterUserService>(mockUserService);
    locator.registerSingleton<UpdateDataController>(mockUpdateDataController);
    locator.registerSingleton<FirebaseAuth>(mockAuth);
    locator.registerSingleton<PreferencesService>(mockPreferencesService);

    when(mockPreferencesService.dailyReminder).thenReturn(false);
    when(mockPreferencesService.professorNotices).thenReturn(true);
  });

  testWidgets('AlunoProfileView renders user data properly', (
    WidgetTester tester,
  ) async {
    when(mockFirebaseUser.uid).thenReturn("uid_123");
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);

    final testUserModel = UserModel(
      id: 'uid_123',
      name: 'Test',
      email: 'test@example.com',
      responsable: 'resp_456',
    );

    final testResponsableModel = UserModel(
      id: 'resp_456',
      name: 'Prof. Marcos',
      email: 'marcos@example.com',
    );

    when(
      mockUserService.getUserById("uid_123"),
    ).thenAnswer((_) async => testUserModel);
    when(
      mockUserService.getResponsableData("resp_456"),
    ).thenAnswer((_) async => testResponsableModel);

    await tester.pumpWidget(MaterialApp(home: AlunoProfileView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    verify(mockAuth.currentUser).called(1);
    verify(mockUserService.getUserById('uid_123')).called(1);
  });

  testWidgets(
    'Deve habilitar a edição e chamar updateHealthProfile ao salvar a ficha de saúde',
    (WidgetTester tester) async {
      when(mockFirebaseUser.uid).thenReturn("uid_123");
      when(mockAuth.currentUser).thenReturn(mockFirebaseUser);

      final testUserModel = UserModel(
        id: 'uid_123',
        name: 'Test',
        email: 'test@example.com',
      );

      when(
        mockUserService.getUserById("uid_123"),
      ).thenAnswer((_) async => testUserModel);
      when(mockUserService.getResponsableData(any)).thenAnswer(
        (_) async =>
            UserModel(id: 'resp', name: 'Resp', email: 'resp@test.com'),
      );

      when(
        mockUpdateDataController.updateHealthProfile(
          userId: 'uid_123',
          conditions: ['Nenhuma dor'],
          restrictions: ['Não possuo'],
          notes: '',
        ),
      ).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(const MaterialApp(home: AlunoProfileView()));
      await tester.pumpAndSettle();

      final updateButton = find.text('ATUALIZAR FICHA DE SAÚDE');
      expect(updateButton, findsOneWidget);

      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      final saveButton = find.text('SALVAR ALTERAÇÕES');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(
        mockUpdateDataController.updateHealthProfile(
          userId: 'uid_123',
          conditions: ['Nenhuma dor'],
          restrictions: ['Não possuo'],
          notes: '',
        ),
      ).called(1);
    },
  );

  Future<void> pumpProfileFor(WidgetTester tester, UserModel user) async {
    tester.view.physicalSize = const Size(430, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(mockFirebaseUser.uid).thenReturn(user.id);
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockUserService.getUserById(user.id)).thenAnswer((_) async => user);

    await tester.pumpWidget(MaterialApp(home: AlunoProfileView()));
    await tester.pumpAndSettle();
  }

  testWidgets('admin não vê professor, ficha clínica, emergência nem plano', (
    WidgetTester tester,
  ) async {
    await pumpProfileFor(
      tester,
      UserModel(
        id: 'admin_1',
        name: 'Grazi',
        email: 'admin@grazi.com',
        type: UserType.admin,
      ),
    );

    expect(find.text('Grazi'), findsOneWidget);
    expect(find.text('ACOMPANHAMENTO PROFISSIONAL'), findsNothing);
    expect(find.text('SAÚDE E FICHA CLÍNICA'), findsNothing);
    expect(find.text('CONTATO DE EMERGÊNCIA'), findsNothing);
    expect(find.text('PLANO E MENSALIDADE'), findsNothing);
    expect(find.text('Plano Presencial + App'), findsNothing);
    expect(find.text('Seus dados e preferências'), findsOneWidget);
    expect(find.text('PREFERÊNCIAS & AJUSTES'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('aluno continua vendo as seções de acompanhamento', (
    WidgetTester tester,
  ) async {
    await pumpProfileFor(
      tester,
      UserModel(id: 'aluno_1', name: 'Aluno', email: 'aluno@grazi.com'),
    );

    expect(find.text('ACOMPANHAMENTO PROFISSIONAL'), findsOneWidget);
    expect(find.text('SAÚDE E FICHA CLÍNICA'), findsOneWidget);
    expect(find.text('CONTATO DE EMERGÊNCIA'), findsOneWidget);
    expect(find.text('PLANO E MENSALIDADE'), findsOneWidget);
    expect(find.text('Plano Presencial + App'), findsOneWidget);
    expect(find.text('Seus dados, saúde e preferências'), findsOneWidget);
  });
}
