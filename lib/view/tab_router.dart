import 'package:academiagrazi/view/components/app_bottom_navigation.dart';
import 'package:academiagrazi/view/user/aluno_home_view.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:academiagrazi/view/user/aluno_treinos_view.dart';
import 'package:academiagrazi/view/user/mocks/treinos_mock_data.dart';
import 'package:academiagrazi/view/user/aluno_evolucao_view.dart';
import 'package:flutter/material.dart';

/// Navegação principal do aluno.
///
/// Utiliza a mesma barra visual do professor,
/// mas controla exclusivamente as telas do aluno.
class MainShell extends StatefulWidget {
  /// Tela exibida na aba Início. O admin usa a AdminHomeView.
  final Widget home;

  const MainShell({super.key, this.home = const AlunoHomeView()});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Navegadores independentes das abas Início e Treinos.
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _treinosNavigatorKey = GlobalKey<NavigatorState>();

  /// Controla a seleção das abas do aluno.
  ///
  /// Mantém o comportamento existente:
  /// tocar em Início ou Treinos retorna à primeira
  /// página do navegador correspondente.
  void _selecionarAba(int index) {
    if (index == 0) {
      _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    if (index == 1) {
      _treinosNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE5E5E5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            // Preserva as telas e seus respectivos estados.
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // ABA 0 - INÍCIO
                NavigatorPopHandler<Object?>(
                  enabled: _selectedIndex == 0,
                  onPopWithResult: (_) {
                    _homeNavigatorKey.currentState?.pop();
                  },
                  child: Navigator(
                    key: _homeNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => widget.home,
                      );
                    },
                  ),
                ),

                // ABA 1 - TREINOS
                NavigatorPopHandler<Object?>(
                  enabled: _selectedIndex == 1,
                  onPopWithResult: (_) {
                    _treinosNavigatorKey.currentState?.pop();
                  },
                  child: Navigator(
                    key: _treinosNavigatorKey,
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder:
                            (_) => const AlunoTreinosView(
                              data: TreinosMockData.alunoTreinos,
                            ),
                      );
                    },
                  ),
                ),

                // ABA 2 - EVOLUÇÃO
                const AlunoEvolutionView(),

                // ABA 3 - PERFIL
                AlunoProfileView(),
              ],
            ),

            // Componente visual compartilhado
            // com a área do professor.
            bottomNavigationBar: AppBottomNavigation(
              keyPrefix: 'aluno',
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selecionarAba,
            ),
          ),
        ),
      ),
    );
  }
}
