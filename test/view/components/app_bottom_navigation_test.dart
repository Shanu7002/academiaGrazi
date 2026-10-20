import 'package:academiagrazi/view/components/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final perfil in ['aluno', 'professor']) {
    testWidgets('barra inferior exibe quatro abas e funciona para $perfil', (
      tester,
    ) async {
      int abaSelecionada = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, atualizarEstado) {
              return Scaffold(
                bottomNavigationBar: AppBottomNavigation(
                  keyPrefix: perfil,
                  selectedIndex: abaSelecionada,
                  onDestinationSelected: (indice) {
                    atualizarEstado(() {
                      abaSelecionada = indice;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Verifica se existe apenas uma barra.
      expect(find.byType(AppBottomNavigation), findsOneWidget);

      expect(find.byType(NavigationBar), findsOneWidget);

      // Verifica os quatro destinos.
      expect(find.byKey(Key('${perfil}_tab_inicio')), findsOneWidget);

      expect(find.byKey(Key('${perfil}_tab_treinos')), findsOneWidget);

      expect(find.byKey(Key('${perfil}_tab_evolucao')), findsOneWidget);

      expect(find.byKey(Key('${perfil}_tab_perfil')), findsOneWidget);

      // Seleciona a aba Treinos.
      await tester.tap(find.byKey(Key('${perfil}_tab_treinos')));

      await tester.pumpAndSettle();

      // A seleção precisa ter sido atualizada.
      expect(abaSelecionada, 1);

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });
  }
}
