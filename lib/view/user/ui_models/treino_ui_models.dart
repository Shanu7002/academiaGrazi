enum TreinoStatusUi { recomendado, concluido, programado }

class ExercicioTreinoUi {
  final String id;
  final String nome;
  final String? aquecimento;
  final String series;
  final String carga;
  final String catalogExerciseId;
  final String muscleGroup;
  final String instructions;
  final bool instructionsAutoTranslated;
  final String? imageUrl;
  final int sets;
  final int repetitions;
  final int restSeconds;
  final String technique;

  const ExercicioTreinoUi({
    required this.id,
    required this.nome,
    this.aquecimento,
    required this.series,
    required this.carga,
    this.catalogExerciseId = '',
    this.muscleGroup = '',
    this.instructions = '',
    this.instructionsAutoTranslated = false,
    this.imageUrl,
    this.sets = 0,
    this.repetitions = 0,
    this.restSeconds = 0,
    this.technique = 'Tradicional',
  });
}

class TreinoUi {
  final String id;
  final String letra;
  final String nome;
  final String descricao;
  final String warmupInstructions;
  final int duracaoMinutos;
  final int quantidadeExercicios;
  final String nivel;
  final String estrategia;
  final String principaisExercicios;
  final String seriesResumo;
  final TreinoStatusUi status;
  final String statusTexto;
  final List<ExercicioTreinoUi> exercicios;
  final String? imageUrl;

  const TreinoUi({
    required this.id,
    required this.letra,
    required this.nome,
    required this.descricao,
    this.warmupInstructions = '',
    required this.duracaoMinutos,
    required this.quantidadeExercicios,
    required this.nivel,
    required this.estrategia,
    required this.principaisExercicios,
    required this.seriesResumo,
    required this.status,
    required this.statusTexto,
    required this.exercicios,
    this.imageUrl,
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
