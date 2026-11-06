import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:flutter/material.dart';

/// Mostra a imagem de referência cadastrada para um exercício.
/// Usa bytes da galeria em prioridade ao asset pré-cadastrado.
class ImagemExercicio extends StatelessWidget {
  final ExercicioCatalogoProfessorUi exercicio;
  final double tamanho;

  const ImagemExercicio({
    super.key,
    required this.exercicio,
    this.tamanho = 64,
  });

  bool get _temImagem =>
      exercicio.imagemBytes != null ||
      (exercicio.imagemAsset?.isNotEmpty ?? false);

  Widget _placeholder() {
    return const ColoredBox(
      color: AppColors.avatarBackground,
      child: Center(
        child: Icon(Icons.fitness_center, color: AppColors.primary),
      ),
    );
  }

  Widget _conteudoImagem() {
    final bytes = exercicio.imagemBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final path = exercicio.imagemAsset;
    if (path != null && path.isNotEmpty) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  void _ampliar(BuildContext context) {
    if (!_temImagem) return;

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(exercicio.nome),
            content: SizedBox(
              width: 320,
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _conteudoImagem(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Imagem de referência: ${exercicio.nome}',
      child: InkWell(
        key: Key('imagem_${exercicio.id}'),
        onTap: _temImagem ? () => _ampliar(context) : null,
        borderRadius: BorderRadius.circular(9),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: tamanho,
            height: tamanho,
            child: _conteudoImagem(),
          ),
        ),
      ),
    );
  }
}
