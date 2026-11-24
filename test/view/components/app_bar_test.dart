import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _screen() => const Scaffold(appBar: CustomAppBar(title: 'Tela'));

void main() {
  final voltar = find.byKey(const Key('appbar_botao_voltar'));

  testWidgets('raiz da navegação não mostra a seta de voltar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: _screen()));

    expect(voltar, findsNothing);
  });

  testWidgets('tela empilhada mostra a seta e volta ao tocar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => TextButton(
                key: const Key('botao_abrir'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => _screen())),
                child: const Text('abrir'),
              ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('botao_abrir')));
    await tester.pumpAndSettle();
    expect(voltar, findsOneWidget);

    await tester.tap(voltar);
    await tester.pumpAndSettle();
    expect(find.text('TELA'), findsNothing);
  });
}
