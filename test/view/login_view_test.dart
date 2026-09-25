import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/login_view.dart';
import 'package:academiagrazi/view/tab_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LoginController])
import 'login_view_test.mocks.dart';

void main() {
  Future<void> pumpLogin(
    WidgetTester tester,
    MockLoginController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
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
    final controller = MockLoginController();
    when(
      controller.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
    ).thenAnswer(
      (_) async =>
          UserModel(id: 'user-1', name: 'Aluno', email: 'aluno@exemplo.com'),
    );

    await pumpLogin(tester, controller);
    await submitLogin(tester);

    expect(find.byType(LoginView), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Painel do Aluno'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(MainShell))).canPop(),
      isFalse,
    );
    verify(
      controller.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
    ).called(1);
  });

  testWidgets('mostra erro quando o login não retorna usuário', (tester) async {
    final controller = MockLoginController();
    when(
      controller.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
    ).thenAnswer((_) async => null);

    await pumpLogin(tester, controller);
    await submitLogin(tester);

    expect(find.text('Falha ao entrar. Tente novamente.'), findsOneWidget);
  });

  testWidgets('valida campos vazios e permite alternar a senha', (
    tester,
  ) async {
    final controller = MockLoginController();
    await pumpLogin(tester, controller);

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
      controller.loginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });
}
