import 'package:academiagrazi/view/user/aluno_ficha_rotina_view.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ficha exibe aquecimento somente se professor configurou', (tester) async {
    const routine = TreinoUi(
      id: 'a', letra: 'A', nome: 'Treino A', descricao: '',
      warmupInstructions: 'Faça 5 minutos de caminhada leve.',
      duracaoMinutos: 40, quantidadeExercicios: 0,
      nivel: '', estrategia: '', principaisExercicios: '', seriesResumo: '',
      status: TreinoStatusUi.programado, statusTexto: '', exercicios: [],
    );
    await tester.pumpWidget(MaterialApp(home: AlunoFichaRotinaView(
      treino: routine, professorNome: 'Grazi', onIniciar: _noop,
      podeIniciar: false,
    )));
    await tester.pumpAndSettle();
    expect(find.text('AQUECIMENTO PRESCRITO'), findsOneWidget);
    expect(find.text('Faça 5 minutos de caminhada leve.'), findsOneWidget);
    expect(find.byKey(const Key('aluno_ficha_iniciar')), findsNothing);
  });
}

void _noop() {}
