import 'package:academiagrazi/view/user/aluno_treino_dia_view.dart';
import 'package:academiagrazi/view/user/aluno_treinos_view.dart';
import 'package:academiagrazi/view/user/mocks/treinos_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'abre o treino do dia com os dados do treino selecionado',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlunoTreinosView(
            data: TreinosMockData.alunoTreinos,
          ),
        ),
      );

      final iniciarTreino = find.byKey(
        const Key('treino_iniciar_treino-a'),
      );

      await tester.ensureVisible(iniciarTreino);
      await tester.tap(iniciarTreino);
      await tester.pumpAndSettle();

      expect(find.byType(AlunoTreinoDiaView), findsOneWidget);

      final view = tester.widget<AlunoTreinoDiaView>(
        find.byType(AlunoTreinoDiaView),
      );

      expect(view.data.treino.id, 'treino-a');
      expect(view.data.professorNome, 'Prof. Marcos');
    },
  );
}
