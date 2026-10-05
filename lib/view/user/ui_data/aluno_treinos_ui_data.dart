import 'package:academiagrazi/view/user/ui_data/aluno_treino_dia_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';

class AlunoTreinosUiData {
  final String alunoNome;
  final String semana;
  final String professorNome;
  final String ultimaAtualizacao;

  final String cicloNome;
  final String frequencia;
  final String frequenciaLegenda;
  final String duracaoMedia;
  final String duracaoLegenda;
  final String validade;
  final String validadeLegenda;

  final List<TreinoUi> treinos;
  final List<TreinoComplementarUi> complementares;
  final Map<String, AlunoTreinoDiaUiData> treinoDiaPorId;

  const AlunoTreinosUiData({
    required this.alunoNome,
    required this.semana,
    required this.professorNome,
    required this.ultimaAtualizacao,
    required this.cicloNome,
    required this.frequencia,
    required this.frequenciaLegenda,
    required this.duracaoMedia,
    required this.duracaoLegenda,
    required this.validade,
    required this.validadeLegenda,
    required this.treinos,
    required this.complementares,
    required this.treinoDiaPorId,
  });

  AlunoTreinoDiaUiData? detalheDoTreino(String treinoId) {
    return treinoDiaPorId[treinoId];
  }
}
