import 'package:academiagrazi/models/units/instructor_shift_model.dart';

/// Aula da grade semanal (ex.: Spinning, segunda às 19:00, no Bloco A).
///
/// Somente informativa: não há reserva nem controle de lotação nesta
/// versão; [capacity] só é exibida. Exclusão lógica com [active] = false.
class GymClassModel {
  final String id;

  /// Modalidade da aula, como aparece na grade (ex.: "Spinning").
  final String name;
  final String unitId;
  final String? instructorId;

  /// Dia da semana no padrão do [DateTime.weekday]: 1 = segunda, 7 = domingo.
  final int weekday;

  /// Horário de início `'HH:mm'`, no relógio local da academia.
  final String startTime;
  final int durationMinutes;

  /// Vagas, apenas informativo.
  final int? capacity;
  final bool active;

  /// Gravado uma única vez, na criação do documento.
  final DateTime? createdAt;

  const GymClassModel({
    required this.id,
    required this.name,
    required this.unitId,
    this.instructorId,
    required this.weekday,
    required this.startTime,
    required this.durationMinutes,
    this.capacity,
    this.active = true,
    this.createdAt,
  });

  int get startMinutes => InstructorShiftModel.minutesOf(startTime)!;

  /// Nome e bloco preenchidos, dia de 1 a 7, horário `'HH:mm'`, duração e
  /// capacidade (quando houver) positivas.
  bool get isValid =>
      name.trim().isNotEmpty &&
      unitId.isNotEmpty &&
      weekday >= DateTime.monday &&
      weekday <= DateTime.sunday &&
      InstructorShiftModel.minutesOf(startTime) != null &&
      durationMinutes > 0 &&
      (capacity == null || capacity! > 0);

  /// Documento completo, usado somente na criação.
  Map<String, dynamic> toJson() => {
    'name': name,
    'unitId': unitId,
    if (instructorId != null) 'instructorId': instructorId,
    'weekday': weekday,
    'startTime': startTime,
    'durationMinutes': durationMinutes,
    if (capacity != null) 'capacity': capacity,
    'active': active,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  factory GymClassModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAt = json['createdAt'];
    return GymClassModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      unitId: (json['unitId'] as String?) ?? '',
      instructorId: json['instructorId'] as String?,
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      startTime: (json['startTime'] as String?) ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
