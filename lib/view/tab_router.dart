import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/admin_home_view.dart';
import 'package:academiagrazi/view/admin/admin_team_view.dart';
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
  /// No modo admin a aba Início mostra a AdminHomeView e a aba Evolução é
  /// substituída pela Equipe.
  final bool isAdmin;

  const MainShell({super.key, this.isAdmin = false});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Navegadores independentes das abas Início e Treinos.
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _treinosNavigatorKey = GlobalKey<NavigatorState>();
  final _equipeNavigatorKey = GlobalKey<NavigatorState>();

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
                        builder:
                            (_) =>
                                widget.isAdmin
                                    ? const AdminHomeView()
                                    : const AlunoHomeView(),
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

                // =====================================================
                // EVOLUÇÃO (aluno) / EQUIPE (admin)
                // =====================================================
                if (widget.isAdmin)
                  NavigatorPopHandler<Object?>(
                    enabled: _selectedIndex == 2,
                    onPopWithResult: (_) {
                      _equipeNavigatorKey.currentState?.pop();
                    },
                    child: Navigator(
                      key: _equipeNavigatorKey,
                      onGenerateRoute: (settings) {
                        return MaterialPageRoute(
                          settings: settings,
                          builder: (_) => const AdminTeamView(),
                        );
                      },
                    ),
                  )
                else
                  const AlunoEvolutionView(),

                // ABA 3 - PERFIL
                AlunoProfileView(),
              ],
            ),

                if (index == 2) {
                  _equipeNavigatorKey.currentState?.popUntil(
                    (route) => route.isFirst,
                  );
                }

                if (index != _selectedIndex) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Início',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.fitness_center),
                  label: 'Treinos',
                ),
                if (widget.isAdmin)
                  const NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups),
                    label: 'Equipe',
                  )
                else
                  const NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: 'Evolução',
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
