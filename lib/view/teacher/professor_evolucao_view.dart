import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/teacher/nova_avaliacao_view.dart';
import 'package:academiagrazi/view/user/aluno_evolucao_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aba Evolução do professor: escolhe um aluno vinculado, acompanha as
/// avaliações dele e registra novas.
class ProfessorEvolucaoView extends StatefulWidget {
  const ProfessorEvolucaoView({super.key});

  @override
  State<ProfessorEvolucaoView> createState() => _ProfessorEvolucaoViewState();
}

class _ProfessorEvolucaoViewState extends State<ProfessorEvolucaoView> {
  late final Stream<List<UserSummary>> _alunos;
  String? _alunoId;

  @override
  void initState() {
    super.initState();
    final professorId = locator<FirebaseAuth>().currentUser!.uid;
    _alunos = locator<TeacherUserSearcher>().streamLinkedUsers(professorId);
  }

  Future<void> _novaAvaliacao(UserSummary aluno) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NovaAvaliacaoView(aluno: aluno)),
    );
    if (salvou == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação registrada.')));
    }
  }

  Future<void> _excluir(String alunoId, PhysicalEvaluation avaliacao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir avaliação'),
            content: Text(
              'Excluir a avaliação de ${formatarData(avaliacao.date)}? '
              'Essa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirmou != true) return;

    try {
      await locator<PhysicalEvaluationService>().deleteEvaluation(
        alunoId,
        avaliacao.id,
      );
    } catch (e) {
      debugPrint('Erro ao excluir avaliação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível excluir a avaliação.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      body: StreamBuilder<List<UserSummary>>(
        stream: _alunos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro de conexão ao carregar os alunos.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alunos = snapshot.data!;
          if (alunos.isEmpty) {
            return const Center(child: Text('Nenhum aluno vinculado.'));
          }

          final aluno = alunos.firstWhere(
            (a) => a.id == _alunoId,
            orElse: () => alunos.first,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Avaliações',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(aluno.id),
                  initialValue: aluno.id,
                  decoration: const InputDecoration(
                    labelText: 'Aluno',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: [
                    for (final a in alunos)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (id) => setState(() => _alunoId = id),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: const Key('botao_nova_avaliacao'),
                  onPressed: () => _novaAvaliacao(aluno),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova avaliação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                EvolucaoAlunoConteudo(
                  alunoId: aluno.id,
                  onExcluir: (avaliacao) => _excluir(aluno.id, avaliacao),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
