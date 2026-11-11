import 'dart:typed_data';

/// Modelos utilizados pela interface da montagem de treino.
/// Ainda não são modelos persistidos no Firestore.
class AlunoResumoProfessorUi {
  final String id;
  final String nome;

  const AlunoResumoProfessorUi({required this.id, required this.nome});
}

/// Um exercício do catálogo: imagem e orientações pertencem ao exercício,
/// não à prescrição individual do aluno.
class ExercicioCatalogoProfessorUi {
  final String id;
  final String nome;
  final String grupoMuscular;

  /// Caminho de uma imagem já incluída nos assets do aplicativo.
  final String? imagemAsset;

  /// Imagem temporária escolhida na galeria.
  /// Não é persistida no backend nesta etapa.
  final Uint8List? imagemBytes;

  final String orientacoes;

  const ExercicioCatalogoProfessorUi({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    this.imagemAsset,
    this.imagemBytes,
    this.orientacoes = '',
  });
}

/// Exercício dentro de um treino: permite que o mesmo exercício do catálogo
/// tenha parâmetros distintos em treinos e alunos diferentes.
class ExercicioMontadoProfessorUi {
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
