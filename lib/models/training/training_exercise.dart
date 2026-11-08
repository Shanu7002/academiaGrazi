/// Um item prescrito dentro de uma rotina de treinamento.
///
/// Guarda os dados de referencia como snapshot, para que mudancas futuras no
/// catalogo nao alterem uma ficha que ja foi publicada.
class TrainingExercise {
  final String id;
  final String catalogExerciseId;
  final String name;
  final String muscleGroup;
  final String instructions;
  final String? imageUrl;
  final int sets;
  final int repetitions;
  final int restSeconds;
  final String technique;
  final double? targetLoadKg;

  const TrainingExercise({
    required this.id,
    required this.catalogExerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.repetitions,
    required this.restSeconds,
    this.instructions = '',
    this.imageUrl,
    this.technique = 'Tradicional',
    this.targetLoadKg,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'catalogExerciseId': catalogExerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'instructions': instructions,
    'imageUrl': imageUrl,
    'sets': sets,
    'repetitions': repetitions,
    'restSeconds': restSeconds,
    'technique': technique,
    'targetLoadKg': targetLoadKg,
  };

  factory TrainingExercise.fromMap(Map<String, dynamic> map) {
    return TrainingExercise(
      id: map['id'] as String,
      catalogExerciseId: map['catalogExerciseId'] as String,
      name: map['name'] as String,
      muscleGroup: map['muscleGroup'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      sets: (map['sets'] as num).toInt(),
      repetitions: (map['repetitions'] as num).toInt(),
      restSeconds: (map['restSeconds'] as num).toInt(),
      technique: map['technique'] as String? ?? 'Tradicional',
      targetLoadKg: (map['targetLoadKg'] as num?)?.toDouble(),
    );
  }

  void validate() {
    if (id.trim().isEmpty ||
        catalogExerciseId.trim().isEmpty ||
        name.trim().isEmpty ||
        sets <= 0 ||
        repetitions <= 0 ||
        restSeconds < 0 ||
        (targetLoadKg != null && targetLoadKg! < 0)) {
      throw StateError('Exercicio prescrito invalido: $id');
    }
  }
}
