import 'dart:async';

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/users/profile_photo.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
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
    locator.registerSingleton<ProfilePhotoService>(
      ProfilePhotoService(cloudName: '', uploadPreset: ''),
    );

    when(mockPreferencesService.dailyReminder).thenReturn(false);
    when(mockPreferencesService.professorNotices).thenReturn(true);
  });

  Future<void> pumpProfileWith(WidgetTester tester, UserModel user) async {
    when(mockFirebaseUser.uid).thenReturn(user.id);
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);
    // O stub genérico (professor) vem antes: no Mockito o último vence.
    when(mockUserService.getUserById(any)).thenAnswer(
      (_) async => UserModel(id: 'resp', name: 'Resp', email: 'r@test.com'),
    );
    when(mockUserService.getUserById(user.id)).thenAnswer((_) async => user);

    await tester.pumpWidget(const MaterialApp(home: AlunoProfileView()));
    await tester.pumpAndSettle();
  }

  testWidgets('Avatar mostra o ícone padrão quando não há foto', (
    WidgetTester tester,
  ) async {
    await pumpProfileWith(
      tester,
      UserModel(id: 'uid_123', name: 'Test', email: 'test@example.com'),
    );

    final avatar = find.byKey(const Key('profile_avatar'));
    expect(avatar, findsOneWidget);
    expect(
      find.descendant(of: avatar, matching: find.byIcon(Icons.person)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('profile_edit_photo')), findsOneWidget);
  });

  testWidgets('Avatar carrega a miniatura do Cloudinary quando há foto', (
    WidgetTester tester,
  ) async {
    await pumpProfileWith(
      tester,
      UserModel(
        id: 'uid_123',
        name: 'Test',
        email: 'test@example.com',
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/a.jpg',
      ),
    );

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('profile_avatar')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as NetworkImage).url,
      'https://res.cloudinary.com/demo/image/upload/'
      'c_fill,g_face,w_160,h_160,q_auto,f_auto/a.jpg',
    );
  });

  testWidgets('Card do professor mostra a foto salva do professor', (
    WidgetTester tester,
  ) async {
    when(mockUserService.getUserById('resp_456')).thenAnswer(
      (_) async => UserModel(
        id: 'resp_456',
        name: 'Prof. Marcos',
        email: 'marcos@example.com',
        type: UserType.instructor,
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/prof.jpg',
      ),
    );
    final aluno = UserModel(
      id: 'uid_123',
      name: 'Test',
      email: 'test@example.com',
      responsable: 'resp_456',
    );
    when(mockFirebaseUser.uid).thenReturn(aluno.id);
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockUserService.getUserById(aluno.id)).thenAnswer((_) async => aluno);

    await tester.pumpWidget(const MaterialApp(home: AlunoProfileView()));
    await tester.pumpAndSettle();

    expect(find.text('Prof. Marcos'), findsOneWidget);
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('responsable_avatar')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (image.image as NetworkImage).url,
      'https://res.cloudinary.com/demo/image/upload/'
      'c_fill,g_face,w_88,h_88,q_auto,f_auto/prof.jpg',
    );
  });

  testWidgets('Cabeçalho mostra a foto do usuário logado e atualiza ao vivo', (
    WidgetTester tester,
  ) async {
    final controller = StreamController<UserModel?>();
    addTearDown(controller.close);
    when(
      mockUserService.watchUserById('uid_123'),
    ).thenAnswer((_) => controller.stream);

    await pumpProfileWith(
      tester,
      UserModel(id: 'uid_123', name: 'Test', email: 'test@example.com'),
    );

    final appBarAvatar = find.byKey(const Key('appbar_user_avatar'));
    expect(appBarAvatar, findsOneWidget);
    expect(
      find.descendant(of: appBarAvatar, matching: find.byType(Image)),
      findsNothing,
    );

    controller.add(
      UserModel(
        id: 'uid_123',
        name: 'Test',
        email: 'test@example.com',
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/eu.jpg',
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.descendant(of: appBarAvatar, matching: find.byType(Image)),
    );
    expect(
      (image.image as NetworkImage).url,
      'https://res.cloudinary.com/demo/image/upload/'
      'c_fill,g_face,w_80,h_80,q_auto,f_auto/eu.jpg',
    );
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
      mockUserService.getUserById("resp_456"),
    ).thenAnswer((_) async => testResponsableModel);

    await tester.pumpWidget(MaterialApp(home: AlunoProfileView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    // O cabeçalho também lê o usuário logado para mostrar a foto.
    verify(mockAuth.currentUser).called(greaterThanOrEqualTo(1));
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

      when(mockUserService.getUserById(any)).thenAnswer(
        (_) async =>
            UserModel(id: 'resp', name: 'Resp', email: 'resp@test.com'),
      );
      when(
        mockUserService.getUserById("uid_123"),
      ).thenAnswer((_) async => testUserModel);

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

  group('falhas e contato de emergência |', () {
    // Com a fonte de teste (Ahem), mais larga que a Inter, os rótulos do
    // dropdown de parentesco transbordam; com a fonte real não.
    void ignorarTransbordamentoDaFonteDeTeste() {
      final anterior = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        anterior?.call(details);
      };
      addTearDown(() => FlutterError.onError = anterior);
    }

    final aluno = UserModel(
      id: 'uid_123',
      name: 'Test',
      email: 'test@example.com',
    );

    testWidgets('mostra erro quando salvar a ficha de saúde falha', (
      tester,
    ) async {
      when(
        mockUpdateDataController.updateHealthProfile(
          userId: anyNamed('userId'),
          conditions: anyNamed('conditions'),
          restrictions: anyNamed('restrictions'),
          notes: anyNamed('notes'),
        ),
      ).thenThrow(Exception('offline'));
      await pumpProfileFor(tester, aluno);

      await tester.tap(find.text('ATUALIZAR FICHA DE SAÚDE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR ALTERAÇÕES'));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao salvar. Tente novamente.'), findsOneWidget);
    });

    testWidgets('salva o contato de emergência e confirma', (tester) async {
      ignorarTransbordamentoDaFonteDeTeste();
      when(
        mockUpdateDataController.updateEmergencyContact(
          userId: anyNamed('userId'),
          name: anyNamed('name'),
          phone: anyNamed('phone'),
          relationship: anyNamed('relationship'),
        ),
      ).thenAnswer((_) async {});
      await pumpProfileFor(tester, aluno);
      // A fonte de teste (Ahem) é mais larga que a real: o formulário de
      // contato transborda em 430 px só no teste.
      tester.view.physicalSize = const Size(900, 4000);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ATUALIZAR CONTATO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR CONTATO'));
      await tester.pumpAndSettle();

      expect(find.text('Contato salvo com sucesso!'), findsOneWidget);
    });

    testWidgets('mostra erro quando salvar o contato de emergência falha', (
      tester,
    ) async {
      ignorarTransbordamentoDaFonteDeTeste();
      when(
        mockUpdateDataController.updateEmergencyContact(
          userId: anyNamed('userId'),
          name: anyNamed('name'),
          phone: anyNamed('phone'),
          relationship: anyNamed('relationship'),
        ),
      ).thenThrow(Exception('offline'));
      await pumpProfileFor(tester, aluno);
      // A fonte de teste (Ahem) é mais larga que a real: o formulário de
      // contato transborda em 430 px só no teste.
      tester.view.physicalSize = const Size(900, 4000);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ATUALIZAR CONTATO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR CONTATO'));
      await tester.pumpAndSettle();

      expect(
        find.text('Falha ao salvar contato. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('sair da conta não quebra a tela quando o signOut falha', (
      tester,
    ) async {
      when(mockAuth.signOut()).thenThrow(Exception('offline'));
      await pumpProfileFor(tester, aluno);

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      verify(mockAuth.signOut()).called(1);
      expect(tester.takeException(), isNull);
    });
  });

  group('card de bloco', () {
    testWidgets('aluno sem bloco mostra "Sem bloco definido"', (tester) async {
      await pumpProfileWith(
        tester,
        UserModel(
          id: 'aluno_1',
          name: 'Aluno',
          email: 'a@test.com',
          responsable: 'resp',
          modality: StudentModality.remote,
        ),
      );

      final card = find.byKey(const Key('card_bloco_turno'));
      expect(
        find.descendant(of: card, matching: find.text('Sem bloco definido')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Remoto (treina em casa)'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('aluno com bloco mostra o nome do bloco', (tester) async {
      final db = FakeFirebaseFirestore();
      final unidades = UnitService(db: db);
      locator.registerSingleton<UnitService>(unidades);
      final bloco = await unidades.createUnit(name: 'Bloco Sul');

      await pumpProfileWith(
        tester,
        UserModel(
          id: 'aluno_1',
          name: 'Aluno',
          email: 'a@test.com',
          responsable: 'resp',
          unitId: bloco,
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('card_bloco_turno')),
          matching: find.text('Bloco Sul'),
        ),
        findsOneWidget,
      );
    });
  });
}
