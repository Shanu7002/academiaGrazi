import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlunoProfileView()));
  }

  testWidgets('exibe o resumo do aluno e as seções de acompanhamento', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('GRAZI BRAZ'), findsOneWidget);
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('ana.lima@exemplo.com'), findsOneWidget);
    expect(find.text('ACOMPANHAMENTO PROFISSIONAL'), findsOneWidget);
    expect(find.text('Prof. Marcos'), findsOneWidget);
    expect(find.text('SAÚDE E FICHA CLÍNICA'), findsOneWidget);
    expect(find.text('Hipertensão controlada'), findsOneWidget);
  });

  testWidgets('exibe plano e preferências ao navegar pelo conteúdo', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.scrollUntilVisible(
      find.text('PREFERÊNCIAS & AJUSTES'),
      500,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('PLANO E MENSALIDADE'), findsOneWidget);
    expect(find.text('Plano Conexão Semestral'), findsOneWidget);
    expect(find.text('Matrícula\n#GB-2023-0482'), findsOneWidget);
    expect(find.text('PREFERÊNCIAS & AJUSTES'), findsOneWidget);
    expect(find.text('Lembrete diário de treino'), findsOneWidget);
    expect(find.text('Avisos do Prof. Marcos'), findsOneWidget);
    expect(find.text('Privacidade & Termos'), findsOneWidget);
  });
}
