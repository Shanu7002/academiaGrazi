import 'package:academiagrazi/view/tab_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre a nova tela de perfil pela aba Perfil', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Menu()));

    expect(find.text('Painel do Aluno'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('GRAZI BRAZ'), findsOneWidget);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('SAÚDE E FICHA CLÍNICA'), findsOneWidget);
  });
}
