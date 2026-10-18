import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';

class AlunoExercicioDetalheUiData {
  final ExercicioTreinoUi exercicio;
  final String descanso;
  final String orientacoes;
  final String tempoVideo;

  const AlunoExercicioDetalheUiData({
    required this.exercicio,
    required this.descanso,
    required this.orientacoes,
    required this.tempoVideo,
  });
}
