/// Modelos de interface do fluxo de montagem de treino do professor.
/// Nao sao modelos do Firestore: a persistencia sera adicionada em outra etapa.
class AlunoResumoProfessorUi {
  final String id;
  final String nome;

  const AlunoResumoProfessorUi({required this.id, required this.nome});
}

class ExercicioCatalogoProfessorUi {
  final String id;
  final String nome;
  final String grupoMuscular;

  const ExercicioCatalogoProfessorUi({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
  });
}

class ExercicioMontadoProfessorUi {
  /// Identificador da inclusao na serie, distinto do exercicio do catalogo.
  final String itemId;
  final String exercicioId;
  final int series;
  final int repeticoes;
  final int descansoSegundos;
  final String tecnica;

  const ExercicioMontadoProfessorUi({
    required this.itemId,
    required this.exercicioId,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    required this.tecnica,
  });

  ExercicioMontadoProfessorUi copyWith({
    int? series,
    int? repeticoes,
    int? descansoSegundos,
    String? tecnica,
  }) {
    return ExercicioMontadoProfessorUi(
      itemId: itemId,
      exercicioId: exercicioId,
      series: series ?? this.series,
      repeticoes: repeticoes ?? this.repeticoes,
      descansoSegundos: descansoSegundos ?? this.descansoSegundos,
      tecnica: tecnica ?? this.tecnica,
    );
  }
}
