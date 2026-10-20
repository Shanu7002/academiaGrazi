import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o título recebido e a cor padrão', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: CustomAppBar(title: 'Montagem de treino')),
      ),
    );

    expect(find.text('MONTAGEM DE TREINO'), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.backgroundColor, AppColors.surface);

    // Não deve apresentar seta na página inicial.
    expect(find.byKey(const Key('appbar_voltar')), findsNothing);
  });

  testWidgets('respeita cor e ações personalizadas', (tester) async {
    bool acaoExecutada = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: CustomAppBar(
            title: 'Perfil',
            backgroundColor: Colors.amber,
            actions: [
              IconButton(
                key: const Key('acao_personalizada'),
                icon: const Icon(Icons.check),
                onPressed: () {
                  acaoExecutada = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.backgroundColor, Colors.amber);

    expect(find.text('PERFIL'), findsOneWidget);

    // A ação personalizada substitui o sino padrão.
    expect(find.byKey(const Key('appbar_notificacoes')), findsNothing);

    await tester.tap(find.byKey(const Key('acao_personalizada')));

    expect(acaoExecutada, isTrue);
  });

  testWidgets('mostra o botão voltar quando existe rota anterior', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => const Scaffold(
                              appBar: CustomAppBar(title: 'Detalhes'),
                              body: Center(child: Text('Página de detalhes')),
                            ),
                      ),
                    );
                  },
                  child: const Text('Abrir detalhes'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalhes'));

    await tester.pumpAndSettle();

    expect(find.text('DETALHES'), findsOneWidget);

    expect(find.byKey(const Key('appbar_voltar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appbar_voltar')));

    await tester.pumpAndSettle();

    expect(find.text('Abrir detalhes'), findsOneWidget);
  });
}
