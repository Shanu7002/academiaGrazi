import 'training_routine.dart';

enum TrainingPlanStatus { draft, published }

/// Prescricao individual de um aluno. Cada plano publicado e imutavel;
/// uma revisao posterior e criada como outro rascunho.
///
/// weeklySchedule usa DateTime.monday=1 ate DateTime.sunday=7.
/// Um valor null ou ausente indica descanso naquele dia.
class TrainingPlan {
  final String id;
  final String studentId;
  final String instructorId;
  final String name;
  final int version;
  final TrainingPlanStatus status;
  final List<TrainingRoutine> routines;
  final Map<int, String?> weeklySchedule;

  const TrainingPlan({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.name,
    required this.version,
    required this.status,
    required this.routines,
    required this.weeklySchedule,
  });

  TrainingPlan copyWith({
    String? id,
    int? version,
    TrainingPlanStatus? status,
  }) => TrainingPlan(
    id: id ?? this.id,
    studentId: studentId,
    instructorId: instructorId,
    name: name,
    version: version ?? this.version,
    status: status ?? this.status,
    routines: routines,
    weeklySchedule: weeklySchedule,
  );

  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'id': id,
    'studentId': studentId,
    'instructorId': instructorId,
    'name': name,
    'version': version,
    'status': status.name,
    'routines': routines.map((routine) => routine.toMap()).toList(),
    'weeklySchedule': {
      for (final entry in weeklySchedule.entries) '${entry.key}': entry.value,
    },
  };

  factory TrainingPlan.fromMap(Map<String, dynamic> map, String documentId) {
    final rawSchedule = Map<String, dynamic>.from(
      map['weeklySchedule'] as Map? ?? const <String, dynamic>{},
    );
    final schedule = <int, String?>{};
    for (final entry in rawSchedule.entries) {
      final day = int.tryParse(entry.key);
      if (day == null || day < 1 || day > 7) {
        throw FormatException('Dia invalido na programacao: ${entry.key}');
      }
      schedule[day] = entry.value as String?;
    }
    final rawStatus = map['status'] as String? ?? 'draft';
    return TrainingPlan(
      id: documentId,
      studentId: map['studentId'] as String,
      instructorId: map['instructorId'] as String,
      name: map['name'] as String,
      version: (map['version'] as num?)?.toInt() ?? 1,
      status: TrainingPlanStatus.values.firstWhere(
        (status) => status.name == rawStatus,
        orElse: () => throw FormatException('Status invalido: $rawStatus'),
      ),
      routines:
          (map['routines'] as List<dynamic>? ?? const [])
              .map(
                (item) => TrainingRoutine.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      weeklySchedule: schedule,
    );
  }

  /// Uma ficha incompleta pode existir como rascunho, mas nao ser publicada.
  void validateForPublication() {
    if (studentId.trim().isEmpty ||
        instructorId.trim().isEmpty ||
        name.trim().isEmpty ||
        version < 1 ||
        routines.isEmpty) {
      throw StateError('Ficha incompleta.');
    }

    final ids = <String>{};
    final letters = <String>{};
    for (final routine in routines) {
      routine.validate();
      if (!ids.add(routine.id) || !letters.add(routine.letter)) {
        throw StateError('Treino repetido na ficha: ${routine.id}');
      }
    }

    if (weeklySchedule.isEmpty) {
      throw StateError('Defina a programacao semanal antes de publicar.');
    }
    var scheduledDays = 0;
    for (final entry in weeklySchedule.entries) {
      if (entry.key < 1 || entry.key > 7) {
        throw StateError('Dia da semana invalido: ${entry.key}');
      }
      final routineId = entry.value;
      if (routineId != null && routineId.isNotEmpty) {
        scheduledDays++;
        if (!ids.contains(routineId)) {
          throw StateError('Treino $routineId nao existe nesta ficha.');
        }
      }
    }
    if (scheduledDays == 0) {
      throw StateError('Programe pelo menos um treino na semana.');
    }
  }
}
