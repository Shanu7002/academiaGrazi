import 'training_plan.dart';
import 'training_routine.dart';

enum TrainingSessionStatus { inProgress, finished }

/// Resultado de uma serie executada. A numeracao comeca em 1.
class TrainingSetResult {
  final int number;
  final bool completed;
  final double? loadKg;

  const TrainingSetResult({
    required this.number,
    this.completed = false,
    this.loadKg,
  });

  TrainingSetResult copyWith({bool? completed, double? loadKg}) =>
      TrainingSetResult(
        number: number,
        completed: completed ?? this.completed,
        loadKg: loadKg ?? this.loadKg,
      );

  Map<String, dynamic> toMap() => {
    'number': number,
    'completed': completed,
    'loadKg': loadKg,
  };

  factory TrainingSetResult.fromMap(Map<String, dynamic> map) =>
      TrainingSetResult(
        number: (map['number'] as num).toInt(),
        completed: map['completed'] as bool? ?? false,
        loadKg: (map['loadKg'] as num?)?.toDouble(),
      );
}

/// Snapshot do exercicio prescrito: a ficha original nunca e alterada.
class TrainingSessionExercise {
  final String itemId;
  final String catalogExerciseId;
  final String name;
  final String muscleGroup;
  final String instructions;
  final String? imageUrl;
  final int repetitions;
  final int restSeconds;
  final String technique;
  final double? suggestedLoadKg;
  final List<TrainingSetResult> sets;

  const TrainingSessionExercise({
    required this.itemId,
    required this.catalogExerciseId,
    required this.name,
    required this.muscleGroup,
    required this.instructions,
    required this.imageUrl,
    required this.repetitions,
    required this.restSeconds,
    required this.technique,
    required this.suggestedLoadKg,
    required this.sets,
  });

  bool get completed => sets.isNotEmpty && sets.every((set) => set.completed);

  TrainingSessionExercise copyWith({List<TrainingSetResult>? sets}) =>
      TrainingSessionExercise(
        itemId: itemId,
        catalogExerciseId: catalogExerciseId,
        name: name,
        muscleGroup: muscleGroup,
        instructions: instructions,
        imageUrl: imageUrl,
        repetitions: repetitions,
        restSeconds: restSeconds,
        technique: technique,
        suggestedLoadKg: suggestedLoadKg,
        sets: sets ?? this.sets,
      );

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'catalogExerciseId': catalogExerciseId,
    'name': name,
    'muscleGroup': muscleGroup,
    'instructions': instructions,
    'imageUrl': imageUrl,
    'repetitions': repetitions,
    'restSeconds': restSeconds,
    'technique': technique,
    'suggestedLoadKg': suggestedLoadKg,
    'sets': sets.map((set) => set.toMap()).toList(),
  };

  factory TrainingSessionExercise.fromMap(Map<String, dynamic> map) =>
      TrainingSessionExercise(
        itemId: map['itemId'] as String,
        catalogExerciseId: map['catalogExerciseId'] as String,
        name: map['name'] as String,
        muscleGroup: map['muscleGroup'] as String? ?? '',
        instructions: map['instructions'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
        restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 0,
        technique: map['technique'] as String? ?? 'Tradicional',
        suggestedLoadKg: (map['suggestedLoadKg'] as num?)?.toDouble(),
        sets: (map['sets'] as List<dynamic>? ?? const [])
            .map(
              (raw) => TrainingSetResult.fromMap(
                Map<String, dynamic>.from(raw as Map),
              ),
            )
            .toList(growable: false),
      );
}

/// Execucao individual de um treino da ficha publicada.
///
/// O documento e separado da prescricao para preservar o historico mesmo
/// quando o professor publicar uma nova ficha.
class TrainingSession {
  final String id;
  final String studentId;
  final String instructorId;
  final String planId;
  final int planVersion;
  final String routineId;
  final String routineName;
  final TrainingSessionStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final bool warmupDone;
  final List<TrainingSessionExercise> exercises;

  const TrainingSession({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.planId,
    required this.planVersion,
    required this.routineId,
    required this.routineName,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.warmupDone,
    required this.exercises,
  });

  factory TrainingSession.fromRoutine({
    required String sessionId,
    required TrainingPlan plan,
    required TrainingRoutine routine,
    required DateTime startedAt,
  }) {
    if (plan.status != TrainingPlanStatus.published ||
        !plan.routines.any((item) => item.id == routine.id)) {
      throw StateError(
        'Somente um treino de ficha publicada pode ser iniciado.',
      );
    }
    routine.validate();
    return TrainingSession(
      id: sessionId,
      studentId: plan.studentId,
      instructorId: plan.instructorId,
      planId: plan.id,
      planVersion: plan.version,
      routineId: routine.id,
      routineName: routine.name,
      status: TrainingSessionStatus.inProgress,
      startedAt: startedAt.toUtc(),
      finishedAt: null,
      warmupDone: false,
      exercises: routine.exercises
          .map((exercise) {
            return TrainingSessionExercise(
              itemId: exercise.id,
              catalogExerciseId: exercise.catalogExerciseId,
              name: exercise.name,
              muscleGroup: exercise.muscleGroup,
              instructions: exercise.instructions,
              imageUrl: exercise.imageUrl,
              repetitions: exercise.repetitions,
              restSeconds: exercise.restSeconds,
              technique: exercise.technique,
              suggestedLoadKg: exercise.targetLoadKg,
              sets: List.generate(
                exercise.sets,
                (index) => TrainingSetResult(number: index + 1),
                growable: false,
              ),
            );
          })
          .toList(growable: false),
    );
  }

  int get completedSets => exercises.fold<int>(
    0,
    (total, exercise) =>
        total + exercise.sets.where((set) => set.completed).length,
  );

  int get totalSets =>
      exercises.fold<int>(0, (total, exercise) => total + exercise.sets.length);

  int get completedExercises =>
      exercises.where((exercise) => exercise.completed).length;

  TrainingSession updateSet({
    required String exerciseItemId,
    required int setNumber,
    required bool completed,
    double? loadKg,
  }) {
    _ensureEditable();
    if (setNumber <= 0 ||
        (loadKg != null && (!loadKg.isFinite || loadKg < 0))) {
      throw ArgumentError('Serie ou carga invalida.');
    }
    final exerciseIndex = exercises.indexWhere(
      (exercise) => exercise.itemId == exerciseItemId,
    );
    if (exerciseIndex < 0) {
      throw StateError('Exercicio nao pertence a esta sessao.');
    }
    final exercise = exercises[exerciseIndex];
    final setIndex = exercise.sets.indexWhere((set) => set.number == setNumber);
    if (setIndex < 0) {
      throw RangeError('Serie nao encontrada no exercicio.');
    }
    final sets = List<TrainingSetResult>.of(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(
      completed: completed,
      loadKg: loadKg,
    );
    final updated = List<TrainingSessionExercise>.of(exercises);
    updated[exerciseIndex] = exercise.copyWith(sets: sets);
    return _copy(exercises: updated);
  }

  TrainingSession markWarmup(bool done) {
    _ensureEditable();
    return _copy(warmupDone: done);
  }

  TrainingSession finishAt(DateTime now) {
    _ensureEditable();
    final end = now.toUtc();
    if (end.isBefore(startedAt)) {
      throw StateError('O termino nao pode ser anterior ao inicio.');
    }
    if (completedSets == 0) {
      throw StateError('Registre ao menos uma serie antes de finalizar.');
    }
    return _copy(status: TrainingSessionStatus.finished, finishedAt: end);
  }

  void _ensureEditable() {
    if (status != TrainingSessionStatus.inProgress) {
      throw StateError('Uma sessao finalizada nao pode ser alterada.');
    }
  }

  TrainingSession _copy({
    TrainingSessionStatus? status,
    DateTime? finishedAt,
    bool? warmupDone,
    List<TrainingSessionExercise>? exercises,
  }) => TrainingSession(
    id: id,
    studentId: studentId,
    instructorId: instructorId,
    planId: planId,
    planVersion: planVersion,
    routineId: routineId,
    routineName: routineName,
    status: status ?? this.status,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    warmupDone: warmupDone ?? this.warmupDone,
    exercises: exercises ?? this.exercises,
  );

  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'id': id,
    'studentId': studentId,
    'instructorId': instructorId,
    'planId': planId,
    'planVersion': planVersion,
    'routineId': routineId,
    'routineName': routineName,
    'status': status.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    if (finishedAt != null) 'finishedAt': finishedAt!.toUtc().toIso8601String(),
    'warmupDone': warmupDone,
    'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
  };

  factory TrainingSession.fromMap(Map<String, dynamic> map, String id) {
    final rawStatus = map['status'] as String;
    final status = TrainingSessionStatus.values.firstWhere(
      (candidate) => candidate.name == rawStatus,
      orElse: () => throw FormatException('Status da sessao invalido.'),
    );
    final startedAt = DateTime.tryParse(map['startedAt'] as String);
    final finishedAt =
        map['finishedAt'] == null
            ? null
            : DateTime.tryParse(map['finishedAt'] as String);
    if (startedAt == null ||
        (map['finishedAt'] != null && finishedAt == null) ||
        (status == TrainingSessionStatus.finished && finishedAt == null)) {
      throw const FormatException('Data da sessao invalida.');
    }
    return TrainingSession(
      id: id,
      studentId: map['studentId'] as String,
      instructorId: map['instructorId'] as String,
      planId: map['planId'] as String,
      planVersion: (map['planVersion'] as num).toInt(),
      routineId: map['routineId'] as String,
      routineName: map['routineName'] as String,
      status: status,
      startedAt: startedAt.toUtc(),
      finishedAt: finishedAt?.toUtc(),
      warmupDone: map['warmupDone'] as bool? ?? false,
      exercises: (map['exercises'] as List<dynamic>? ?? const [])
          .map(
            (raw) => TrainingSessionExercise.fromMap(
              Map<String, dynamic>.from(raw as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
