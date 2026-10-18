enum TreinoStatusUi {
  recomendado,
  concluido,
  programado,
}

class ExercicioTreinoUi {
  final String id;
  final String nome;
  final String? aquecimento;
  final String series;
  final String carga;

  const ExercicioTreinoUi({
    required this.id,
    required this.nome,
    this.aquecimento,
    required this.series,
    required this.carga,
  });
}

class TreinoUi {
  final String id;
  final String letra;
  final String nome;
  final String descricao;
  final int duracaoMinutos;
  final int quantidadeExercicios;
  final String nivel;
  final String estrategia;
  final String principaisExercicios;
  final String seriesResumo;
  final TreinoStatusUi status;
  final String statusTexto;
  final List<ExercicioTreinoUi> exercicios;

  const TreinoUi({
    required this.id,
    required this.letra,
    required this.nome,
    required this.descricao,
    required this.duracaoMinutos,
    required this.quantidadeExercicios,
    required this.nivel,
    required this.estrategia,
    required this.principaisExercicios,
    required this.seriesResumo,
    required this.status,
    required this.statusTexto,
    required this.exercicios,
  });
}

class TreinoComplementarUi {
  final String id;
  final String nome;
  final String descricao;
  final int duracaoMinutos;

  const TreinoComplementarUi({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.duracaoMinutos,
  });
}
