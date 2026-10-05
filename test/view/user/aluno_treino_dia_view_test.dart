import 'package:academiagrazi/view/user/aluno_exercicio_detalhe_view.dart';
import 'package:academiagrazi/view/user/aluno_treino_dia_view.dart';
import 'package:academiagrazi/view/user/mocks/treinos_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'abre detalhes do exercício tocado com os parâmetros corretos',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlunoTreinoDiaView(
            data: TreinosMockData.treinoADia,
          ),
        ),
      );

      final agachamento = find.byKey(
        const Key('exercicio_agachamento'),
      );

      await tester.ensureVisible(agachamento);
      await tester.tap(agachamento);
      await tester.pumpAndSettle();

      expect(
        find.byType(AlunoExercicioDetalheView),
        findsOneWidget,
      );

      final view = tester.widget<AlunoExercicioDetalheView>(
        find.byType(AlunoExercicioDetalheView),
      );

      expect(view.data.exercicio.id, 'agachamento');
      expect(view.data.descanso, '75s');
      expect(view.data.tempoVideo, '01:45');
    },
  );

  testWidgets(
    'continuar treino abre o primeiro exercício pendente',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlunoTreinoDiaView(
            data: TreinosMockData.treinoADia,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('continuar_treino')),
      );
      await tester.pumpAndSettle();

      final view = tester.widget<AlunoExercicioDetalheView>(
        find.byType(AlunoExercicioDetalheView),
      );

      expect(view.data.exercicio.id, 'afundo');
    },
  );
}
