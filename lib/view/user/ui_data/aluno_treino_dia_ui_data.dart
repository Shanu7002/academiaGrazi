import 'package:academiagrazi/view/user/ui_data/aluno_exercicio_detalhe_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';

class AlunoTreinoDiaUiData {
  final TreinoUi treino;
  final String professorNome;
  final String aquecimentoNome;
  final String aquecimentoResumo;
  final Set<String> exerciciosConcluidosIniciais;
  final Map<String, AlunoExercicioDetalheUiData> exercicioDetalhePorId;

  const AlunoTreinoDiaUiData({
    required this.treino,
    required this.professorNome,
    required this.aquecimentoNome,
    required this.aquecimentoResumo,
    this.exerciciosConcluidosIniciais = const <String>{},
    required this.exercicioDetalhePorId,
  });

  AlunoExercicioDetalheUiData? detalheDoExercicio(String exercicioId) {
    return exercicioDetalhePorId[exercicioId];
  }
}
