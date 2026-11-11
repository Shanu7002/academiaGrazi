import 'package:academiagrazi/view/user/aluno_painel_semanal_view.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('domingo sem treino exibe descanso e nao oferece iniciar', (tester) async {
    const routine = TreinoUi(
      id: 'a', letra: 'A', nome: 'Treino A', descricao: '',
      duracaoMinutos: 45, quantidadeExercicios: 1,
      nivel: '', estrategia: '', principaisExercicios: '', seriesResumo: '',
      status: TreinoStatusUi.programado, statusTexto: '',
      exercicios: <ExercicioTreinoUi>[],
    );
    const data = AlunoTreinosUiData(
      alunoNome: 'Ana', planId: 'p', programacaoSemanal: {1: 'a', 7: null},
      semana: '02/11 a 08/11', professorNome: 'Grazi', ultimaAtualizacao: 'Versao 1',
      cicloNome: 'Ficha', frequencia: '1x', frequenciaLegenda: '',
      duracaoMedia: '45 min', duracaoLegenda: '',
      validade: '', validadeLegenda: '', treinos: [routine],
      complementares: [], treinoDiaPorId: {},
    );
    var started = false;
    await tester.pumpWidget(MaterialApp(home: AlunoPainelSemanalView(
      data: data, historico: const [], emAndamento: null,
      agora: DateTime(2026, 11, 8),
      onIniciarTreino: (_) => started = true, onHistorico: () {},
    )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('aluno_dia_descanso')), 170,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30,
    );
    expect(find.byKey(const Key('aluno_dia_descanso')), findsOneWidget);
    expect(find.byKey(const Key('aluno_iniciar_treino_hoje')), findsNothing);
    final verFicha = find.byKey(const Key('aluno_ver_ficha_a'));
    await tester.scrollUntilVisible(verFicha, 260,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.tap(verFicha);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aluno_ficha_iniciar')), findsNothing);
    expect(started, isFalse);
  });
}
