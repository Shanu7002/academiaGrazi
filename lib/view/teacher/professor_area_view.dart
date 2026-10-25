import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/app_bottom_navigation.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:academiagrazi/view/teacher/professor_dashboard_view.dart';
import 'package:academiagrazi/view/teacher/professor_montagem_treino_view.dart';
import 'package:flutter/material.dart';

/// Controla as quatro abas da área do professor.
///
/// A barra inferior é reutilizável, mas as telas
/// e o estado pertencem exclusivamente ao instrutor.
class ProfessorAreaView extends StatefulWidget {
  const ProfessorAreaView({super.key});

  @override
  State<ProfessorAreaView> createState() => _ProfessorAreaViewState();
}

class _ProfessorAreaViewState extends State<ProfessorAreaView> {
  int _abaSelecionada = 0;

  void _selecionarAba(int indice) {
    if (indice == _abaSelecionada) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _abaSelecionada = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE5E5E5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Scaffold(
            backgroundColor: AppColors.background,

            // Mantém as quatro telas montadas.
            // Assim, ao trocar de aba, o professor
            // não perde o rascunho da montagem.
            body: IndexedStack(
              index: _abaSelecionada,
              children: [
                // Aba 0 - Dashboard do outro desenvolvedor.
                const ProfessorDashboardView(),

                // Aba 1 - Nossa montagem de treinos.
                ProfessorMontagemTreinoView(
                  onVoltarInicio: () => _selecionarAba(0),
                ),

                // Aba 2 - Desenvolvimento futuro.
                const _AbaProfessorPendente(
                  titulo: 'Evolução',
                  icone: Icons.insights_outlined,
                ),

                // Aba 3 - Perfil compartilhado com aluno e admin.
                const AlunoProfileView(),
              ],
            ),

            // A barra é definida em um componente único.
            bottomNavigationBar: AppBottomNavigation(
              keyPrefix: 'professor',
              selectedIndex: _abaSelecionada,
              onDestinationSelected: _selecionarAba,
            ),
          ),
        ),
      ),
    );
  }
}

/// Página temporária para funcionalidades ainda
/// não desenvolvidas no perfil de instrutor.
class _AbaProfessorPendente extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const _AbaProfessorPendente({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: AppColors.primary, size: 42),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tela em desenvolvimento',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
