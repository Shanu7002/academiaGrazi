import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/login_view.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LoginController])
import 'login_view_test.mocks.dart';

void main() {
  late MockLoginController controller;

  setUp(() {
    controller = MockLoginController();
  });

  testWidgets('redireciona usuário comum para a tela de perfil', (
    tester,
  ) async {
    when(
      controller.loginUser(email: 'ana@exemplo.com', password: 'senha123'),
    ).thenAnswer(
      (_) async =>
          UserModel(id: 'user-1', name: 'Ana Lima', email: 'ana@exemplo.com'),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'ana@exemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.byType(AlunoProfileView), findsOneWidget);
    expect(find.text('GRAZI BRAZ'), findsOneWidget);
    verify(
      controller.loginUser(email: 'ana@exemplo.com', password: 'senha123'),
    ).called(1);
  });

  testWidgets('valida campos obrigatórios antes de chamar o controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
    );

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Preencha todos os campos.'), findsOneWidget);
    verifyNever(
      controller.loginUser(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });
}
