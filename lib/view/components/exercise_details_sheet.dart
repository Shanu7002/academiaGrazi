import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Abre os detalhes de um exercício (imagem, grupo muscular e orientações).
///
/// Compartilhado entre a montagem do professor e a execução do aluno. Os
/// vídeos ficaram fora desta versão (AGENTS.md §1.1): a imagem ocupa o lugar
/// do player.
Future<void> showExerciseDetailsSheet(
  BuildContext context, {
  required String name,
  String muscleGroup = '',
  String instructions = '',
  String? imageUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => ExerciseDetailsSheet(
          name: name,
          muscleGroup: muscleGroup,
          instructions: instructions,
          imageUrl: imageUrl,
        ),
  );
}

class ExerciseDetailsSheet extends StatelessWidget {
  final String name;
  final String muscleGroup;
  final String instructions;
  final String? imageUrl;

  const ExerciseDetailsSheet({
    super.key,
    required this.name,
    this.muscleGroup = '',
    this.instructions = '',
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final group = StudentExercisePresentation.muscleGroup(muscleGroup.trim());
    final guidance = instructions.trim();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          maxWidth: 430,
        ),
        child: SingleChildScrollView(
          key: const Key('detalhes_exercicio'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StudentExercisePhoto(
                url: imageUrl,
                size: double.infinity,
                height: 220,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.barlowCondensed(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSize.headline,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              if (group.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryChipSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    group,
                    style: GoogleFonts.barlowCondensed(
                      color: AppColors.primary,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              BrandHeading('Orientações', level: BrandHeadingLevel.section),
              const SizedBox(height: 6),
              Text(
                guidance.isEmpty
                    ? 'Orientações de execução não cadastradas.'
                    : guidance,
                style: GoogleFonts.barlowCondensed(
                  color:
                      guidance.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textBody,
                  fontSize: AppFontSize.caption,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('botao_fechar_detalhes_exercicio'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
