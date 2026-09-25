import 'package:academiagrazi/view/user/aluno_home_view.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _homeNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          NavigatorPopHandler<Object?>(
            enabled: _selectedIndex == 0,
            onPopWithResult: (_) {
              _homeNavigatorKey.currentState?.pop();
            },
            child: Navigator(
              key: _homeNavigatorKey,
              onGenerateRoute:
                  (settings) =>
                      MaterialPageRoute(settings: settings, builder: (_) => const AlunoHomeView()),
            ),
          ),
          const Center(child: Text('Treinos')),
          const Center(child: Text('Evolução')),
          const AlunoProfileView(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        indicatorColor: const Color(0xFFFF7943),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          }

          if (index != _selectedIndex) {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Treinos'),
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
