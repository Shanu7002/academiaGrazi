import 'package:academiagrazi/view/user/teacher/mocks/montagem_treino_mock_data.dart';
import 'package:academiagrazi/view/user/teacher/professor_montagem_treino_view.dart';
import 'package:academiagrazi/view/user/teacher/widgets/exercicio_montagem_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrirTela(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfessorMontagemTreinoView(
          data: MontagemTreinoProfessorMockData.inicial,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a montagem da Ana Lima com dois exercicios', (
    tester,
  ) async {
    await abrirTela(tester);
    expect(find.text('Montagem de Treino'), findsOneWidget);
    expect(find.text('Editando: Ana Lima'), findsOneWidget);
    expect(find.byType(ExercicioMontagemCard), findsNWidgets(2));
  });

  testWidgets('permite selecionar outro aluno da lista mock', (tester) async {
    await abrirTela(tester);
    await tester.tap(find.byKey(const Key('selecionar_aluno')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beatriz Souza'));
    await tester.pumpAndSettle();
    expect(find.text('Editando: Beatriz Souza'), findsOneWidget);
  });

  testWidgets('permite adicionar exercicio pelo catalogo', (tester) async {
    await abrirTela(tester);
    await tester.enterText(
      find.byKey(const Key('pesquisar_exercicio')),
      'Cadeira Extensora',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('catalogo-cadeira-extensora')));
    await tester.pumpAndSettle();
    expect(find.byType(ExercicioMontagemCard), findsNWidgets(3));
  });

  testWidgets('remove exercicio pelo botao do card', (tester) async {
    await abrirTela(tester);
    await tester.ensureVisible(
      find.byKey(const Key('remover-item-agachamento')),
    );
    await tester.tap(find.byKey(const Key('remover-item-agachamento')));
    await tester.pumpAndSettle();
    expect(find.byType(ExercicioMontagemCard), findsOneWidget);
  });

  testWidgets('atribuir ao aluno mostra apenas previa sem salvar', (
    tester,
  ) async {
    await abrirTela(tester);
    await tester.tap(find.byKey(const Key('atribuir_ao_aluno')));
    await tester.pumpAndSettle();
    expect(find.text('Conferência de atribuição'), findsOneWidget);
    expect(find.textContaining('Nenhum treino será salvo'), findsOneWidget);
  });
}
