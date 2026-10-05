import 'package:academiagrazi/view/user/aluno_exercicio_detalhe_view.dart';
import 'package:academiagrazi/view/user/mocks/treinos_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'concluir série avança para a próxima série',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlunoExercicioDetalheView(
            data: TreinosMockData.agachamentoDetalhe,
          ),
        ),
      );

      expect(
        find.text('CONCLUIR SÉRIE 1'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('concluir_serie')),
      );
      await tester.pump();

      expect(
        find.text('CONCLUIR SÉRIE 2'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renderiza os dados recebidos do exercício',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlunoExercicioDetalheView(
            data: TreinosMockData.agachamentoDetalhe,
          ),
        ),
      );

      expect(
        find.text('Agachamento livre'),
        findsWidgets,
      );
      expect(find.text('75s'), findsOneWidget);
      expect(find.text('01:45'), findsOneWidget);
    },
  );
}
