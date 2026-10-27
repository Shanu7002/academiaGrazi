import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:academiagrazi/view/teacher/widgets/imagem_exercicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card independente com imagem, edição de séries e reordenação.
class ExercicioMontagemCard extends StatelessWidget {
  final int index;
  final ExercicioCatalogoProfessorUi exercicio;
  final ExercicioMontadoProfessorUi item;
  final ValueChanged<ExercicioMontadoProfessorUi> onChanged;
  final VoidCallback onRemove;

  const ExercicioMontagemCard({
    super.key,
    required this.index,
    required this.exercicio,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  static const tecnicas = [
    'Tradicional',
    'Rest-pause',
    'Drop-set',
    'Bi-set',
    'Super-set',
  ];

  Widget _numero({
    required String titulo,
    required int valor,
    required ValueChanged<int> onChange,
    bool aceitarZero = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: Key('${item.itemId}-$titulo'),
          initialValue: '$valor',
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (text) {
            final parsed = int.tryParse(text);
            if (parsed != null && (aceitarZero ? parsed >= 0 : parsed > 0)) {
              onChange(parsed);
            }
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.trainingListBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tecnica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Técnica',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          key: Key('${item.itemId}-tecnica'),
          initialValue: item.tecnica,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.trainingListBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items:
              tecnicas
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) onChanged(item.copyWith(tecnica: value));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ImagemExercicio(exercicio: exercicio),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercicio.nome,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        exercicio.grupoMuscular,
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                        ),
                      ),
                      if (exercicio.orientacoes.isNotEmpty)
                        Text(
                          exercicio.orientacoes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('remover-${item.itemId}'),
                  icon: const Icon(Icons.close, size: 19),
                  tooltip: 'Remover ${exercicio.nome}',
                  onPressed: onRemove,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _numero(
                    titulo: 'Séries',
                    valor: item.series,
                    onChange:
                        (valor) => onChanged(item.copyWith(series: valor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numero(
                    titulo: 'Reps',
                    valor: item.repeticoes,
                    onChange:
                        (valor) => onChanged(item.copyWith(repeticoes: valor)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _numero(
                    titulo: 'Descanso (s)',
                    valor: item.descansoSegundos,
                    aceitarZero: true,
                    onChange:
                        (valor) =>
                            onChanged(item.copyWith(descansoSegundos: valor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _tecnica()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
