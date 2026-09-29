import 'package:academiagrazi/service/users/register.dart';
import 'package:academiagrazi/view/user/aluno_home_view.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:academiagrazi/view/user/aluno_treinos_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  final RegisterService userService;
  final FirebaseAuth authInstance;

  const MainShell({
    super.key,
    required this.userService,
    required this.authInstance,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _treinosNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // =====================================================
          // INÍCIO
          // =====================================================
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
                  builder: (_) => const AlunoHomeView(),
                );
              },
            ),
          ),

          // =====================================================
          // TREINOS
          // =====================================================
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
                  builder: (_) => const AlunoTreinosView(),
                );
              },
            ),
          ),

          // =====================================================
          // EVOLUÇÃO
          // =====================================================
          const Center(
            child: Text('Evolução'),
          ),

          // =====================================================
          // PERFIL
          // Mantém a implementação nova da sprint-3.
          // =====================================================
          AlunoProfileView(
            userService: widget.userService,
            authInstance: widget.authInstance,
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        indicatorColor: const Color(0xFFFF7943),
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          // Ao tocar em Início, volta para a raiz da Home.
          if (index == 0) {
            _homeNavigatorKey.currentState?.popUntil(
              (route) => route.isFirst,
            );
          }

          // Ao tocar em Treinos, volta para a lista de treinos.
          if (index == 1) {
            _treinosNavigatorKey.currentState?.popUntil(
              (route) => route.isFirst,
            );
          }

          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Treinos',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Evolução',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}