import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Barra inferior reutilizável.
///
/// Ela define apenas o visual das abas.
/// A tela que utiliza o componente decide o que abrir.
class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String keyPrefix;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.keyPrefix = 'app',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: NavigationBar(
          key: ValueKey('${keyPrefix}_bottom_navigation'),
          height: 80,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            NavigationDestination(
              key: ValueKey('${keyPrefix}_tab_inicio'),
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'Início',
            ),
            NavigationDestination(
              key: ValueKey('${keyPrefix}_tab_treinos'),
              icon: const Icon(Icons.fitness_center),
              label: 'Treinos',
            ),
            NavigationDestination(
              key: ValueKey('${keyPrefix}_tab_evolucao'),
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: 'Evolução',
            ),
            NavigationDestination(
              key: ValueKey('${keyPrefix}_tab_perfil'),
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
