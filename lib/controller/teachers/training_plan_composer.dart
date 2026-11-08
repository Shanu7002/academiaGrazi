import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';

/// Editor de rascunhos independente de widgets e do Firestore.
///
/// Mantem uma ficha por aluno. A publicacao propriamente dita e feita pelo
/// TrainingPlanService, que verifica o vinculo e a versao no banco.
class TrainingPlanComposer {
  final String studentId;
  final String instructorId;
  final String planId;
  final int version;
  String name;

  final Map<String, TrainingRoutine> _routines = {};
  final Map<int, String?> _weeklySchedule = {};

  TrainingPlanComposer({
    required this.studentId,
    required this.instructorId,
    required this.name,
    this.planId = '',
    this.version = 1,
  });

  factory TrainingPlanComposer.fromDraft(TrainingPlan draft) {
    if (draft.status != TrainingPlanStatus.draft) {
      throw StateError('Uma ficha publicada nao pode ser editada.');
    }
    final composer = TrainingPlanComposer(
      studentId: draft.studentId,
      instructorId: draft.instructorId,
      name: draft.name,
      planId: draft.id,
      version: draft.version,
    );
    for (final routine in draft.routines) {
      composer._routines[routine.id] = _copyRoutine(routine);
    }
    composer._weeklySchedule.addAll(draft.weeklySchedule);
    return composer;
  }

  List<TrainingRoutine> get routines =>
      List<TrainingRoutine>.unmodifiable(_routines.values);

  Map<int, String?> get weeklySchedule =>
      Map<int, String?>.unmodifiable(_weeklySchedule);

  TrainingRoutine routine(String routineId) =>
      _routines[routineId] ??
      (throw StateError('Treino nao encontrado: $routineId'));

  String addRoutine({
    required String letter,
    required String name,
    String focus = '',
    int estimatedMinutes = 45,
    String? imageUrl,
  }) {
    final normalized = letter.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(normalized) ||
        name.trim().isEmpty ||
        estimatedMinutes < 0) {
      throw ArgumentError('Letra, nome ou duracao do treino invalida.');
    }
    final id = 'treino-${normalized.toLowerCase()}';
    if (_routines.containsKey(id) ||
        _routines.values.any((item) => item.letter == normalized)) {
      throw StateError('O Treino $normalized ja existe nesta ficha.');
    }
    _routines[id] = TrainingRoutine(
      id: id,
      letter: normalized,
      name: name.trim(),
      focus: focus.trim(),
      imageUrl: imageUrl,
      estimatedMinutes: estimatedMinutes,
      exercises: const [],
    );
    return id;
  }

  void updateRoutine({
    required String routineId,
    String? name,
    String? focus,
    int? estimatedMinutes,
    String? imageUrl,
  }) {
    final current = routine(routineId);
    final newName = name?.trim() ?? current.name;
    final newMinutes = estimatedMinutes ?? current.estimatedMinutes;
    if (newName.isEmpty || newMinutes < 0) {
      throw ArgumentError('Nome ou duracao invalida.');
    }
    _routines[routineId] = TrainingRoutine(
      id: current.id,
      letter: current.letter,
      name: newName,
      focus: focus?.trim() ?? current.focus,
      imageUrl: imageUrl ?? current.imageUrl,
      estimatedMinutes: newMinutes,
      exercises: List<TrainingExercise>.of(current.exercises),
    );
  }

  void removeRoutine(String routineId) {
    if (_routines.remove(routineId) == null) {
      throw StateError('Treino nao encontrado: $routineId');
    }
    for (final day in _weeklySchedule.keys.toList()) {
      if (_weeklySchedule[day] == routineId) {
        _weeklySchedule[day] = null;
      }
    }
  }

  void addExercise(String routineId, TrainingExercise exercise) {
    final current = routine(routineId);
    exercise.validate();
    if (current.exercises.any((item) => item.id == exercise.id)) {
      throw StateError('Item ja existe no treino: ${exercise.id}');
    }
    _replaceExercises(routineId, [...current.exercises, exercise]);
  }

  void updateExercise(String routineId, TrainingExercise updated) {
    final current = routine(routineId);
    updated.validate();
    final index = current.exercises.indexWhere((item) => item.id == updated.id);
    if (index < 0) {
      throw StateError('Exercicio nao encontrado: ${updated.id}');
    }
    final exercises = List<TrainingExercise>.of(current.exercises);
    exercises[index] = updated;
    _replaceExercises(routineId, exercises);
  }

  void removeExercise(String routineId, String exerciseItemId) {
    final current = routine(routineId);
    if (!current.exercises.any((item) => item.id == exerciseItemId)) {
      throw StateError('Exercicio nao encontrado: $exerciseItemId');
    }
    _replaceExercises(
      routineId,
      current.exercises.where((item) => item.id != exerciseItemId).toList(),
    );
  }

  /// Indices convencionais: a posicao 0 e o primeiro exercicio.
  void moveExercise(String routineId, int from, int to) {
    final current = routine(routineId);
    final exercises = List<TrainingExercise>.of(current.exercises);
    if (from < 0 ||
        from >= exercises.length ||
        to < 0 ||
        to >= exercises.length) {
      throw RangeError('Posicao fora do intervalo do treino.');
    }
    final item = exercises.removeAt(from);
    exercises.insert(to, item);
    _replaceExercises(routineId, exercises);
  }

  /// De segunda-feira (1) a domingo (7); null representa descanso.
  void assignDay(int weekday, String? routineId) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'Dia invalido');
    }
    final normalized =
        routineId == null || routineId.isEmpty ? null : routineId;
    if (normalized != null && !_routines.containsKey(normalized)) {
      throw StateError('Nao e possivel agendar treino inexistente.');
    }
    _weeklySchedule[weekday] = normalized;
  }

  TrainingPlan buildDraft() => TrainingPlan(
    id: planId,
    studentId: studentId,
    instructorId: instructorId,
    name: name.trim(),
    version: version,
    status: TrainingPlanStatus.draft,
    routines: routines.map(_copyRoutine).toList(growable: false),
    weeklySchedule: Map<int, String?>.of(_weeklySchedule),
  );

  /// Valida antes de enviar para publishDraft; nao marca a ficha publicada.
  TrainingPlan buildReadyToPublish() {
    final draft = buildDraft();
    draft.validateForPublication();
    return draft;
  }

  void _replaceExercises(String routineId, List<TrainingExercise> exercises) {
    final current = routine(routineId);
    _routines[routineId] = TrainingRoutine(
      id: current.id,
      letter: current.letter,
      name: current.name,
      focus: current.focus,
      imageUrl: current.imageUrl,
      estimatedMinutes: current.estimatedMinutes,
      exercises: List<TrainingExercise>.of(exercises),
    );
  }

  static TrainingRoutine _copyRoutine(TrainingRoutine routine) =>
      TrainingRoutine(
        id: routine.id,
        letter: routine.letter,
        name: routine.name,
        focus: routine.focus,
        imageUrl: routine.imageUrl,
        estimatedMinutes: routine.estimatedMinutes,
        exercises: List<TrainingExercise>.of(routine.exercises),
      );
}
