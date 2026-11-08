import 'training_exercise.dart';

/// Treino A/B/C (ou D...) de uma ficha.
class TrainingRoutine {
  final String id;
  final String letter;
  final String name;
  final String focus;
  /// Aquecimento prescrito pelo professor (opcional, em portugues).
  final String warmupInstructions;
  final String? imageUrl;
  final int estimatedMinutes;
  final List<TrainingExercise> exercises;

  const TrainingRoutine({
    required this.id,
    required this.letter,
    required this.name,
    required this.focus,
    this.warmupInstructions = '',
    this.imageUrl,
    required this.estimatedMinutes,
    required this.exercises,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'letter': letter,
    'name': name,
    'focus': focus,
    'warmupInstructions': warmupInstructions,
    'imageUrl': imageUrl,
    'estimatedMinutes': estimatedMinutes,
    'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
  };

  factory TrainingRoutine.fromMap(Map<String, dynamic> map) => TrainingRoutine(
    id: map['id'] as String,
    letter: map['letter'] as String,
    name: map['name'] as String,
    focus: map['focus'] as String? ?? '',
    warmupInstructions: map['warmupInstructions'] as String? ?? '',
    imageUrl: map['imageUrl'] as String?,
    estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 0,
    exercises:
        (map['exercises'] as List<dynamic>? ?? const [])
            .map(
              (item) => TrainingExercise.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
  );

  void validate() {
    if (id.trim().isEmpty ||
        letter.trim().isEmpty ||
        name.trim().isEmpty ||
        estimatedMinutes < 0 ||
        exercises.isEmpty) {
      throw StateError('Treino invalido: $id');
    }
    final ids = <String>{};
    for (final exercise in exercises) {
      exercise.validate();
      if (!ids.add(exercise.id)) {
        throw StateError('Item repetido no treino $id: ${exercise.id}');
      }
    }
  }
}
