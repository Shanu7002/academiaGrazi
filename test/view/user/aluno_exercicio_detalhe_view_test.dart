import 'package:academiagrazi/view/user/aluno_exercicio_detalhe_view.dart';
import 'package:academiagrazi/view/user/mocks/treinos_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrirTela(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: AlunoExercicioDetalheView(
          data: TreinosMockData.agachamentoDetalhe,
        ),
      ),
    );
  }

  testWidgets('concluir série avança para a próxima série', (tester) async {
    await abrirTela(tester);

    expect(find.text('CONCLUIR SÉRIE 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('concluir_serie')));
    await tester.pump();

    expect(find.text('CONCLUIR SÉRIE 2'), findsOneWidget);
  });

  testWidgets('renderiza os dados recebidos do exercício', (tester) async {
    await abrirTela(tester);

    expect(find.text('Agachamento livre'), findsWidgets);
    expect(find.text('75s'), findsOneWidget);
  });

  testWidgets('mostra a imagem do exercício no lugar do player de vídeo', (
    tester,
  ) async {
    await abrirTela(tester);

    expect(find.byKey(const Key('imagem_exercicio_detalhe')), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });

  testWidgets('tocar na imagem abre os detalhes do exercício', (tester) async {
    await abrirTela(tester);

    await tester.tap(find.byKey(const Key('imagem_exercicio_detalhe')));
    await tester.pumpAndSettle();

    final detalhes = find.byKey(const Key('detalhes_exercicio'));
    expect(detalhes, findsOneWidget);
    expect(
      find.descendant(
        of: detalhes,
        matching: find.textContaining('Mantenha as costas retas'),
      ),
      findsOneWidget,
    );
  });
}
