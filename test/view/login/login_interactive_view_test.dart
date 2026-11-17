import 'dart:async';

import 'package:academiagrazi/controller/users/login.dart';
import 'package:academiagrazi/controller/users/register_user.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/view/login/login_scene.dart';
import 'package:academiagrazi/view/login_view.dart';
import 'package:academiagrazi/view/user/self_register_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Usa os mocks já gerados para os testes originais de autenticação.
import '../login_view_test.mocks.dart';

void main() {
  late MockLoginController login;

  setUp(() async {
    await locator.reset();
    login = MockLoginController();
    locator.registerSingleton<LoginController>(login);
    locator.registerSingleton<RegisterUserController>(
      MockRegisterUserController(),
    );
  });

  tearDown(() async {
    await locator.reset();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    bool autoRotate = false,
    Size size = const Size(430, 1300),
    bool reduceMotion = false,
    double textScale = 1,
    double keyboardHeight = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduceMotion,
                textScaler: TextScaler.linear(textScale),
                viewInsets: EdgeInsets.only(bottom: keyboardHeight),
              ),
              child: child!,
            ),
        home: LoginView(autoRotate: autoRotate),
      ),
    );
    await tester.pump();
  }

  bool selected(WidgetTester tester, TrainingMode mode) =>
      tester
          .widget<Semantics>(find.byKey(ValueKey('modo_login_${mode.name}')))
          .properties
          .selected!;

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Future<void> enterCredentials(WidgetTester tester) async {
    final email = find.byKey(const Key('campo_email_login'));
    final password = find.byKey(const Key('campo_senha_login'));
    await tester.ensureVisible(email);
    await tester.enterText(email, 'aluno@exemplo.com');
    await tester.ensureVisible(password);
    await tester.enterText(password, 'senha123');
  }

  Future<void> tapLogin(WidgetTester tester) async {
    final button = find.byKey(const Key('botao_entrar_login'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('inicia presencial com logo e duas imagens locais', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(selected(tester, TrainingMode.presencial), isTrue);
    expect(find.byKey(const Key('logo_login')), findsOneWidget);
    final sources = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName);
    expect(sources, contains(LoginPresentation.presencial.imageAsset));
    expect(sources, contains(LoginPresentation.home.imageAsset));
    expect(find.byType(TextField), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('alterna automaticamente a cada cinco segundos', (tester) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await tester.pump(const Duration(seconds: 4));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(selected(tester, TrainingMode.home), isTrue);
      await tester.pump(const Duration(seconds: 5));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('troca manual conserva email, senha e posição do formulário', (
    tester,
  ) async {
    await pumpLogin(tester);
    await enterCredentials(tester);
    final emailField = tester.widget<TextField>(
      find.byKey(const Key('campo_email_login')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('campo_senha_login')),
    );
    final emailController = emailField.controller;
    final passwordController = passwordField.controller;
    await tester.ensureVisible(find.text('Treino em casa'));
    await tester.pump();
    final before = tester.getRect(find.byKey(const Key('login_formulario')));
    await tester.tap(find.text('Treino em casa'));
    await tester.pump(LoginPresentation.transition);
    await tester.pump();
    expect(selected(tester, TrainingMode.home), isTrue);
    expect(emailController!.text, 'aluno@exemplo.com');
    expect(passwordController!.text, 'senha123');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('campo_email_login')))
          .controller,
      same(emailController),
    );
    expect(tester.getRect(find.byKey(const Key('login_formulario'))), before);
    verifyZeroInteractions(login);
    await unmount(tester);
  });

  testWidgets('foco no email suspende a rotação mesmo sem digitar', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await tester.tap(find.byKey(const Key('campo_email_login')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 25));
      expect(selected(tester, TrainingMode.presencial), isTrue);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('foco na senha suspende a rotação e mantém o texto', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await enterCredentials(tester);
      await tester.pump(const Duration(seconds: 25));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('campo_senha_login')))
            .controller!
            .text,
        'senha123',
      );
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('retoma após oito segundos sem foco nem interação', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await tester.tap(find.byKey(const Key('campo_email_login')));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 7));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(selected(tester, TrainingMode.home), isTrue);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('troca manual reinicia a espera de oito segundos', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await tester.tap(find.text('Treino em casa'));
      await tester.pump();
      expect(selected(tester, TrainingMode.home), isTrue);
      await tester.pump(const Duration(seconds: 7));
      expect(selected(tester, TrainingMode.home), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(selected(tester, TrainingMode.presencial), isTrue);
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('não exibe pausa nem legenda extra abaixo do seletor', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    expect(find.text('conexão e movimento'), findsNothing);
    expect(find.byKey(const Key('botao_pausar_cenarios')), findsNothing);
    expect(find.text('Presencial'), findsOneWidget);
    expect(find.text('Treino em casa'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('redução de movimento desliga rotação mas permite troca manual', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true, reduceMotion: true);
    try {
      await tester.pump(const Duration(seconds: 20));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      expect(find.byKey(const Key('botao_pausar_cenarios')), findsNothing);
      await tester.tap(find.text('Treino em casa'));
      await tester.pump();
      expect(selected(tester, TrainingMode.home), isTrue);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('fundo_login_home')),
            )
            .duration,
        Duration.zero,
      );
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('aplicativo em segundo plano não fica alternando imagens', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      // Ordem de estados válida para WidgetsBinding / AppLifecycleListener.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 25));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 8));
      expect(selected(tester, TrainingMode.home), isTrue);
    } finally {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      }
      if (tester.binding.lifecycleState == AppLifecycleState.inactive) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      }
      await unmount(tester);
    }
  });

  testWidgets('dispose cancela o timer sem chamar setState depois da saída', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    await unmount(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('volta do cadastro preserva credenciais e retoma a rotação', (
    tester,
  ) async {
    await pumpLogin(tester, autoRotate: true);
    try {
      await enterCredentials(tester);
      await tester.ensureVisible(find.text('Criar minha conta'));
      await tester.tap(find.text('Criar minha conta'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SelfRegisterView), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      Navigator.of(tester.element(find.byType(SelfRegisterView))).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LoginView), findsOneWidget);
      expect(selected(tester, TrainingMode.presencial), isTrue);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('campo_email_login')))
            .controller!
            .text,
        'aluno@exemplo.com',
      );
    } finally {
      await unmount(tester);
    }
  });

  testWidgets('submissão em andamento impede requisições duplicadas', (
    tester,
  ) async {
    final completer = Completer<UserModel?>();
    when(
      login.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
    ).thenAnswer((_) => completer.future);
    await pumpLogin(tester, autoRotate: true);
    try {
      await enterCredentials(tester);
      await tapLogin(tester);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('botao_entrar_login')),
      );
      expect(button.onPressed, isNull);
      await tester.pump(const Duration(seconds: 15));
      expect(selected(tester, TrainingMode.presencial), isTrue);
      verify(
        login.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
      ).called(1);
      completer.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('botao_entrar_login')))
            .onPressed,
        isNotNull,
      );
    } finally {
      if (!completer.isCompleted) completer.complete(null);
      await unmount(tester);
    }
  });

  testWidgets('exceção inesperada no login mostra mensagem e libera o botão', (
    tester,
  ) async {
    when(
      login.loginUser(email: 'aluno@exemplo.com', password: 'senha123'),
    ).thenThrow(StateError('falha simulada'));
    await pumpLogin(tester);
    await enterCredentials(tester);
    await tapLogin(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Não conseguimos entrar agora. Tente novamente.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('botao_entrar_login')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('recuperação trata exceção sem deixar formulário bloqueado', (
    tester,
  ) async {
    when(
      login.resetPassword(email: 'aluno@exemplo.com'),
    ).thenThrow(StateError('falha simulada'));
    await pumpLogin(tester);
    await enterCredentials(tester);
    await tester.ensureVisible(find.text('Esqueci minha senha'));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(
        'Não conseguimos processar a solicitação agora. Verifique o e-mail.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('layout ${size.width}x${size.height} sem overflow', (
      tester,
    ) async {
      await pumpLogin(tester, size: size);
      expect(tester.takeException(), isNull);
      final width =
          tester.getSize(find.byKey(const Key('login_area_responsiva'))).width;
      expect(width, lessThanOrEqualTo(LoginPresentation.maxWidth));
      await tester.ensureVisible(
        find.byKey(const Key('botao_recuperar_senha_login')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('teclado aberto não esconde definitivamente as ações', (
    tester,
  ) async {
    await pumpLogin(tester, size: const Size(390, 844), keyboardHeight: 320);
    await enterCredentials(tester);
    await tester.ensureVisible(find.byKey(const Key('botao_entrar_login')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('botao_entrar_login')).hitTestable(),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('texto ampliado mantém rolagem e controles sem overflow', (
    tester,
  ) async {
    await pumpLogin(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const Key('botao_recuperar_senha_login')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
