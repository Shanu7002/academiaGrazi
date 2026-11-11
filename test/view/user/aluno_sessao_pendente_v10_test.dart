import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/view/user/aluno_painel_semanal_view.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const treino = TreinoUi(
    id: 'a', letra: 'A', nome: 'Treino A', descricao: '',
    duracaoMinutos: 45, quantidadeExercicios: 1,
    nivel: '', estrategia: '', principaisExercicios: '', seriesResumo: '',
    status: TreinoStatusUi.programado, statusTexto: '',
    exercicios: <ExercicioTreinoUi>[],
  );
  const descanso = AlunoTreinosUiData(
    alunoNome: 'Aluna', planId: 'ficha',
    programacaoSemanal: {1: 'a', 7: null},
    semana: '02/11 a 08/11', professorNome: 'Grazi',
    ultimaAtualizacao: 'Versao 1', cicloNome: 'Ficha',
    frequencia: '1x', frequenciaLegenda: '',
    duracaoMedia: '45 min', duracaoLegenda: '',
    validade: '', validadeLegenda: '',
    treinos: [treino], complementares: [], treinoDiaPorId: {},
  );

  TrainingSession sessao({
    required String id,
    required TrainingSessionStatus status,
    required DateTime inicio,
    DateTime? fim,
  }) => TrainingSession(
    id: id, studentId: 'aluna', instructorId: 'prof',
    planId: 'ficha', planVersion: 1, routineId: 'a',
    routineName: 'Treino A', status: status,
    startedAt: inicio, finishedAt: fim,
    warmupDone: false, exercises: const [],
  );

  Future<void> abrirDia(WidgetTester tester, Key key) async {
    await tester.scrollUntilVisible(find.byKey(key), 190,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
    await tester.pumpAndSettle();
  }

  testWidgets('domingo e descanso mesmo com pendencia de treino teste', (tester) async {
    final pendente = sessao(id: 'teste-antigo',
      status: TrainingSessionStatus.inProgress,
      inicio: DateTime(2026, 11, 7, 11));
    final concluido = sessao(id: 'realizado-domingo',
      status: TrainingSessionStatus.finished,
      inicio: DateTime(2026, 11, 8, 8),
      fim: DateTime(2026, 11, 8, 8, 35));
    var started = false;
    await tester.pumpWidget(MaterialApp(home: AlunoPainelSemanalView(
      data: descanso, historico: [concluido], emAndamento: pendente,
      agora: DateTime(2026, 11, 8, 15),
      onIniciarTreino: (_) => started = true, onHistorico: () {},
    )));
    await abrirDia(tester, const Key('aluno_dia_descanso'));
    expect(find.text('HOJE É DIA DE DESCANSO'), findsOneWidget);
    expect(find.byKey(const Key('aluno_retomar_treino')), findsNothing);
    expect(find.byKey(const Key('aluno_iniciar_treino_hoje')), findsNothing);
    expect(find.text('Treino registrado hoje'), findsOneWidget);
    expect(started, isFalse);
  });

  testWidgets('pendencia iniciada hoje no treino programado permite retomar', (tester) async {
    final pendente = sessao(id: 'em-progresso',
      status: TrainingSessionStatus.inProgress,
      inicio: DateTime(2026, 11, 2, 9));
    var selected = '';
    await tester.pumpWidget(MaterialApp(home: AlunoPainelSemanalView(
      data: descanso, historico: const [], emAndamento: pendente,
      agora: DateTime(2026, 11, 2, 10),
      onIniciarTreino: (id) => selected = id, onHistorico: () {},
    )));
    await abrirDia(tester, const Key('aluno_retomar_treino'));
    expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);
    await tester.tap(find.byKey(const Key('aluno_retomar_treino')));
    await tester.pumpAndSettle();
    expect(selected, 'a');
  });

  testWidgets('treino ja concluido hoje nao oferece iniciar novamente', (tester) async {
    final concluido = sessao(id: 'finalizado',
      status: TrainingSessionStatus.finished,
      inicio: DateTime(2026, 11, 2, 9),
      fim: DateTime(2026, 11, 2, 9, 40));
    await tester.pumpWidget(MaterialApp(home: AlunoPainelSemanalView(
      data: descanso, historico: [concluido], emAndamento: null,
      agora: DateTime(2026, 11, 2, 10),
      onIniciarTreino: (_) {}, onHistorico: () {},
    )));
    await abrirDia(tester, const Key('aluno_treino_concluido_hoje'));
    expect(find.text('TREINO DE HOJE CONCLUÍDO'), findsOneWidget);
    expect(find.byKey(const Key('aluno_iniciar_treino_hoje')), findsNothing);
    await abrirDia(tester, const Key('aluno_ver_ficha_a'));
    await tester.tap(find.byKey(const Key('aluno_ver_ficha_a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aluno_ficha_iniciar')), findsNothing);
  });
}
