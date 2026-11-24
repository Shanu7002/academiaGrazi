import 'package:academiagrazi/view/components/exercise_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrirDetalhes(
    WidgetTester tester, {
    String muscleGroup = '',
    String instructions = '',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  key: const Key('botao_abrir'),
                  onPressed:
                      () => showExerciseDetailsSheet(
                        context,
                        name: 'Supino reto',
                        muscleGroup: muscleGroup,
                        instructions: instructions,
                      ),
                  child: const Text('Abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('botao_abrir')));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra nome, grupo muscular traduzido e orientações', (
    tester,
  ) async {
    await abrirDetalhes(
      tester,
      muscleGroup: 'chest',
      instructions: 'Desça a barra até o peito.',
    );

    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('Peito'), findsOneWidget);
    expect(find.text('Desça a barra até o peito.'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
  });

  testWidgets('avisa quando não há orientações e omite o grupo vazio', (
    tester,
  ) async {
    await abrirDetalhes(tester);

    expect(
      find.text('Orientações de execução não cadastradas.'),
      findsOneWidget,
    );
    expect(find.text('Peito'), findsNothing);
  });

  testWidgets('fecha pelo botão Fechar', (tester) async {
    await abrirDetalhes(tester);

    await tester.tap(find.byKey(const Key('botao_fechar_detalhes_exercicio')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detalhes_exercicio')), findsNothing);
  });
}
