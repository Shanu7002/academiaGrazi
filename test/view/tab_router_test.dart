import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:academiagrazi/view/tab_router.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register.dart';

@GenerateMocks([RegisterService, FirebaseAuth, User])
import 'tab_router_test.mocks.dart';

void main() {
  late MockRegisterService mockUserService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockFirebaseUser;
  late void Function(FlutterErrorDetails)? previousFlutterError;

  setUp(() {
    mockUserService = MockRegisterService();
    mockAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();

    when(mockFirebaseUser.uid).thenReturn('uid_test');
    when(mockAuth.currentUser).thenReturn(mockFirebaseUser);

    when(mockUserService.getUserById(any)).thenAnswer(
      (_) async => UserModel(
        id: 'uid_test',
        name: 'Test User',
        email: 'test@bigtech.com',
      ),
    );
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

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userService: mockUserService, authInstance: mockAuth),
      ),
    );

    expect(find.text('Grazi Braz'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('botao_iniciar_treino')),
      500,
      scrollable: find.byType(Scrollable),
    );

    await tester.tap(find.byKey(const Key('botao_iniciar_treino')));

    await tester.pumpAndSettle();

    expect(find.text('Treino do dia'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('volta para a Home ao selecionar Início durante um treino', (
    tester,
  ) async {
    ignorePlaceholderImageError();

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userService: mockUserService, authInstance: mockAuth),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Iniciar treino'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    expect(find.text('Grazi Braz'), findsOneWidget);
    expect(find.text('Treino do dia'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('alterna entre as páginas sem remover a NavigationBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(userService: mockUserService, authInstance: mockAuth),
      ),
    );

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
}
