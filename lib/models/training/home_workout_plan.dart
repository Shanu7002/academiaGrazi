import 'training_routine.dart';

/// Prescricao opcional, independente da ficha presencial do aluno.
/// O documento atual fica em users/{studentId}/homeWorkouts/current.
/// Sessoes executadas preservam o snapshot, mesmo depois de alteracoes.
class HomeWorkoutPlan {
  final String studentId;
  final String instructorId;
  final int version;
  final List<TrainingRoutine> routines;

  const HomeWorkoutPlan({
    required this.studentId,
    required this.instructorId,
    required this.version,
    required this.routines,
  });

  factory HomeWorkoutPlan.fromMap(Map<String, dynamic> map) => HomeWorkoutPlan(
    studentId: map['studentId'] as String,
    instructorId: map['instructorId'] as String,
    version: (map['version'] as num?)?.toInt() ?? 1,
    routines: (map['routines'] as List<dynamic>? ?? const [])
        .map((item) => TrainingRoutine.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false),
  );

  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'studentId': studentId,
    'instructorId': instructorId,
    'status': 'published',
    'version': version,
    'routines': routines.map((item) => item.toMap()).toList(growable: false),
  };

  void validate() {
    if (studentId.isEmpty || studentId.contains('/') ||
        instructorId.isEmpty || instructorId.contains('/') ||
        version < 1 || routines.isEmpty || routines.length > 8) {
      throw StateError('Informe um aluno e de 1 a 8 treinos em casa.');
    }
    if (routines.fold<int>(0, (total, r) => total + r.exercises.length) > 60) {
      throw StateError('Limite de 60 exercicios por prescricao.');
    }
    final ids = <String>{};
    for (final routine in routines) {
      routine.validate();
      if (!ids.add(routine.id)) {
        throw StateError('Treino em casa duplicado: ${routine.id}.');
      }
    }
  }
}
