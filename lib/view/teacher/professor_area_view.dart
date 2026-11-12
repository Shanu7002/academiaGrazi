import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bottom_navigation.dart';
import 'package:academiagrazi/view/user/aluno_profile_view.dart';
import 'package:academiagrazi/view/teacher/professor_dashboard_view.dart';
import 'package:academiagrazi/view/teacher/professor_evolucao_view.dart';
import 'package:academiagrazi/view/teacher/professor_ficha_treinos_view.dart';
import 'package:academiagrazi/view/teacher/student_open_request.dart';
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

  // O painel pede às abas Treinos e Evolução que abram um aluno.
  final _treinosRequest = StudentOpenRequest();
  final _evolucaoRequest = StudentOpenRequest();

  @override
  void dispose() {
    _treinosRequest.dispose();
    _evolucaoRequest.dispose();
    super.dispose();
  }

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
      color: AppColors.background,
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
                // Aba 0 - Painel: números, prioridades e atalhos.
                ProfessorDashboardView(
                  onOpenStudents: () {
                    _treinosRequest.showList();
                    _selecionarAba(1);
                  },
                  onOpenStudentTraining: (studentId) {
                    _treinosRequest.open(studentId);
                    _selecionarAba(1);
                  },
                  onOpenStudentAssessments: (studentId) {
                    _evolucaoRequest.open(studentId);
                    _selecionarAba(2);
                  },
                ),

                // Aba 1 - Fluxo real: alunos vinculados -> ficha -> edição.
                ProfessorFichaTreinosView(
                  onVoltarInicio: () => _selecionarAba(0),
                  openRequest: _treinosRequest,
                ),

                // Aba 2 - Avaliações físicas dos alunos.
                ProfessorEvolucaoView(openRequest: _evolucaoRequest),

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
