import 'package:academiagrazi/view/user/aluno_painel_semanal_view.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra grade semanal e rotina sem criar sessao ao consultar', (tester) async {
    // Viewport maior para exercitar a navegacao sem toque fora da tela.
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var starts = 0;
    const routine = TreinoUi(
      id: 'a', letra: 'A', nome: 'Treino A', descricao: 'Pernas',
      duracaoMinutos: 40, quantidadeExercicios: 1, nivel: '', estrategia: '',
      principaisExercicios: '', seriesResumo: '3 séries',
      status: TreinoStatusUi.recomendado, statusTexto: '',
      exercicios: [ExercicioTreinoUi(
        id: 'item', nome: 'Agachamento', series: '3x12', carga: 'A definir',
        sets: 3, repetitions: 12, restSeconds: 60,
      )],
    );
    const data = AlunoTreinosUiData(
      alunoNome: 'Ana', semana: '02/11 a 08/11', professorNome: 'Grazi',
      ultimaAtualizacao: 'Versão 1', cicloNome: 'Ficha semanal',
      frequencia: '1x', frequenciaLegenda: 'por semana',
      duracaoMedia: '40 min', duracaoLegenda: 'média por treino',
      validade: 'Até nova ficha', validadeLegenda: '',
      programacaoSemanal: {1: 'a', 2: null},
      treinos: [routine], complementares: [], treinoDiaPorId: {},
    );
    await tester.pumpWidget(MaterialApp(home: AlunoPainelSemanalView(
      data: data, historico: const [], emAndamento: null,
      agora: DateTime(2026, 11, 2),
      onIniciarTreino: (_) => starts++, onHistorico: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aluno_dia_1')), findsOneWidget);
    expect(find.byKey(const Key('aluno_dia_2')), findsOneWidget);
    expect(find.byKey(const Key('aluno_painel_semanal')), findsOneWidget);
    // A semana e o ponto de entrada do aluno: abrir a ficha pelo dia programado.
    // Nao depende da posicao vertical dos cards na viewport do teste.
    expect(find.byKey(const Key('aluno_ver_ficha_a')), findsOneWidget);
    final diaProgramado = find.byKey(const Key('aluno_dia_1'));
    expect(diaProgramado.hitTestable(), findsOneWidget);
    await tester.tap(diaProgramado);
    await tester.pumpAndSettle();
    expect(find.textContaining('Agachamento'), findsOneWidget);
    expect(starts, 0);
    await tester.tap(find.byKey(const Key('aluno_ficha_iniciar')));
    await tester.pumpAndSettle();
    expect(starts, 1);
  });
}
