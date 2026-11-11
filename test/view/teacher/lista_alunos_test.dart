import 'package:academiagrazi/view/teacher/lista_alunos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza os cards de aluno ativo e inativo', (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ListaAlunosView()));
    await tester.pumpAndSettle();

    expect(find.byType(CardAluno), findsNWidgets(2));
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('Inativo'), findsOneWidget);
  });
}
