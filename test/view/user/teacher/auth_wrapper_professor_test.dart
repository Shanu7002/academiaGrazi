import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/auth_wrapper.dart';
import 'package:academiagrazi/view/user/teacher/professor_area_view.dart';
import 'package:academiagrazi/view/user/teacher/professor_dashboard_view.dart';
import 'package:academiagrazi/view/user/teacher/professor_montagem_treino_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _UsuarioFake extends Fake implements User {
  @override
  String get uid => 'uid-professor';
}

class _AuthFake extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(_UsuarioFake());
}

class _RegisterUserServiceFake extends Fake implements RegisterUserService {
  @override
  Future<UserType> getUserRole(String uid) async {
    if (uid != 'uid-professor') throw StateError('UID incorreto');
    return UserType.instructor;
  }
}

void main() {
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<FirebaseAuth>(_AuthFake());
    locator.registerSingleton<RegisterUserService>(_RegisterUserServiceFake());
  });

  tearDown(() async => locator.reset());

  Future<void> abrirArea(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AuthWrapper()));
    await tester.pumpAndSettle();
  }

  testWidgets('instrutor abre Inicio com hotbar fixa de quatro abas', (
    tester,
  ) async {
    await abrirArea(tester);

    expect(find.byType(ProfessorAreaView), findsOneWidget);
    expect(find.byType(ProfessorDashboardView), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.byKey(const Key('professor_bottom_navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('professor_tab_inicio')), findsOneWidget);
    expect(find.byKey(const Key('professor_tab_treinos')), findsOneWidget);
    expect(find.byKey(const Key('professor_tab_evolucao')), findsOneWidget);
    expect(find.byKey(const Key('professor_tab_perfil')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('Treinos abre montagem e voltar retorna ao Inicio', (
    tester,
  ) async {
    await abrirArea(tester);
    await tester.tap(find.byKey(const Key('professor_tab_treinos')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfessorMontagemTreinoView), findsOneWidget);
    expect(find.text('Editando: Ana Lima'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(find.byKey(const Key('voltar_ao_dashboard')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfessorDashboardView), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Evolucao e Perfil mantem hotbar disponivel', (tester) async {
    await abrirArea(tester);

    await tester.tap(find.byKey(const Key('professor_tab_evolucao')));
    await tester.pumpAndSettle();
    expect(find.text('Tela em desenvolvimento'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.tap(find.byKey(const Key('professor_tab_perfil')));
    await tester.pumpAndSettle();
    expect(find.text('Tela em desenvolvimento'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });

  testWidgets('ao trocar de aba, mantem selecao de aluno na montagem', (
    tester,
  ) async {
    await abrirArea(tester);
    await tester.tap(find.byKey(const Key('professor_tab_treinos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('selecionar_aluno')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beatriz Souza'));
    await tester.pumpAndSettle();
    expect(find.text('Editando: Beatriz Souza'), findsOneWidget);

    await tester.tap(find.byKey(const Key('professor_tab_inicio')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('professor_tab_treinos')));
    await tester.pumpAndSettle();
    expect(find.text('Editando: Beatriz Souza'), findsOneWidget);
  });
}
