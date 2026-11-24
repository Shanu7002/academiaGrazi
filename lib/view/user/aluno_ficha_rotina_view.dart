import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Consulta da ficha SEM iniciar sessao; so o botao de iniciar abre a execucao.
class AlunoFichaRotinaView extends StatelessWidget {
  final TreinoUi treino;
  final String professorNome;
  final VoidCallback onIniciar;
  final bool podeIniciar;

  const AlunoFichaRotinaView({
    super.key,
    required this.treino,
    required this.professorNome,
    required this.onIniciar,
    this.podeIniciar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.trainingListBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        title: Text('FICHA DO TREINO', style: GoogleFonts.barlowCondensed(
          color: AppColors.primary, fontSize: AppFontSize.title, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(children: [
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              Text(treino.nome,
                style: GoogleFonts.barlowCondensed(fontSize: AppFontSize.headline,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 5),
              Text('Professor: $professorNome  •  ${treino.duracaoMinutos} min previstos',
                style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Text('${treino.quantidadeExercicios} exercícios na ordem prescrita',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              if (treino.warmupInstructions.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  color: AppColors.primaryActionSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('AQUECIMENTO PRESCRITO',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 6),
                      Text(treino.warmupInstructions),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ...treino.exercicios.asMap().entries.map((entry) =>
                _exercicio(context, entry.key + 1, entry.value)),
              const SizedBox(height: 8),
              const Text('As fotos são ilustrativas. Use as orientações do professor para executar os movimentos.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
            ],
          )),
          if (podeIniciar) Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              key: const Key('aluno_ficha_iniciar'),
              onPressed: onIniciar,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar este treino'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 15)),
            )),
          ) else const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Text('Ficha disponível para consulta. Para iniciar, aguarde o dia programado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
          ),
        ]),
      ))),
    );
  }

  Widget _exercicio(BuildContext context, int index, ExercicioTreinoUi exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StudentExercisePhoto(url: exercise.imageUrl, size: 90),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$index. ${exercise.nome}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppFontSize.small,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              if (exercise.muscleGroup.isNotEmpty)
                Text(exercise.muscleGroup,
                  style: const TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
              const SizedBox(height: 7),
              Text('${exercise.sets} séries × ${exercise.repetitions} repetições',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppFontSize.caption,
                  color: AppColors.primary)),
              Text('${exercise.restSeconds}s de descanso  •  ${exercise.carga}',
                style: const TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 12),
          if (exercise.instructions.trim().isNotEmpty) ...[
            const Text('ORIENTAÇÕES DE EXECUÇÃO', style: TextStyle(
              color: AppColors.primary, fontSize: AppFontSize.caption, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(exercise.instructions,
              style: const TextStyle(fontSize: AppFontSize.caption, color: AppColors.textBody)),
          ]
          else
            const Row(children: [
              Icon(Icons.info_outline, size: 17, color: AppColors.textSecondary),
              SizedBox(width: 7),
              Expanded(child: Text('Orientações de execução não cadastradas.',
                style: TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary))),
            ]),
        ]),
      ),
    );
  }
}
