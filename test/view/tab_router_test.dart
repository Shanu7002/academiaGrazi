import 'package:academiagrazi/view/tab_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late void Function(FlutterErrorDetails)? previousFlutterError;

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
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

    expect(find.text('Painel do Aluno'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Iniciar treino'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    expect(find.text('Treino do dia'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('volta para a Home ao selecionar Início durante um treino', (
    tester,
  ) async {
    ignorePlaceholderImageError();
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

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

    expect(find.text('Painel do Aluno'), findsOneWidget);
    expect(find.text('Treino do dia'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('alterna entre as páginas sem remover a NavigationBar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

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
