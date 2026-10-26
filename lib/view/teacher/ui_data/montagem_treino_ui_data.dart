import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';

/// Contrato de dados de entrada, independente do Firebase e da tela.
class MontagemTreinoProfessorUiData {
  final String nomeTreino;
  final String alunoSelecionadoId;
  final List<AlunoResumoProfessorUi> alunos;
  final List<ExercicioCatalogoProfessorUi> catalogo;
  final List<ExercicioMontadoProfessorUi> exerciciosIniciais;
  final int duracaoEstimadaMinutos;
  final String volume;
  final String dicaExecucao;

  const MontagemTreinoProfessorUiData({
    required this.nomeTreino,
    required this.alunoSelecionadoId,
    required this.alunos,
    required this.catalogo,
    required this.exerciciosIniciais,
    required this.duracaoEstimadaMinutos,
    required this.volume,
    required this.dicaExecucao,
  });
}
