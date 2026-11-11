/// Turno da escala: o professor [instructorId] está na unidade [unitId]
/// toda semana no dia [weekday], das [startTime] às [endTime].
///
/// Os horários são do relógio local da academia (`'HH:mm'`) e o turno
/// começa e termina no mesmo dia ([startTime] < [endTime]).
class InstructorShiftModel {
  final String id;
  final String instructorId;
  final String unitId;

  /// Dia da semana no padrão do [DateTime.weekday]: 1 = segunda, 7 = domingo.
  final int weekday;
  final String startTime;
  final String endTime;

  /// Gravado uma única vez, na criação do documento.
  final DateTime? createdAt;

  const InstructorShiftModel({
    required this.id,
    required this.instructorId,
    required this.unitId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  static final RegExp _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Minutos desde a meia-noite de um horário `'HH:mm'`, ou `null` se o
  /// texto não for um horário válido.
  static int? minutesOf(String time) {
    if (!_timePattern.hasMatch(time)) return null;
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get startMinutes => minutesOf(startTime)!;
  int get endMinutes => minutesOf(endTime)!;

  /// Dia de 1 a 7, horários `'HH:mm'` e início antes do fim.
  bool get isValid {
    final start = minutesOf(startTime);
    final end = minutesOf(endTime);
    return weekday >= DateTime.monday &&
        weekday <= DateTime.sunday &&
        instructorId.isNotEmpty &&
        unitId.isNotEmpty &&
        start != null &&
        end != null &&
        start < end;
  }

  /// Documento completo, usado somente na criação.
  Map<String, dynamic> toJson() => {
    'instructorId': instructorId,
    'unitId': unitId,
    'weekday': weekday,
    'startTime': startTime,
    'endTime': endTime,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  factory InstructorShiftModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAt = json['createdAt'];
    return InstructorShiftModel(
      id: id,
      instructorId: (json['instructorId'] as String?) ?? '',
      unitId: (json['unitId'] as String?) ?? '',
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      startTime: (json['startTime'] as String?) ?? '',
      endTime: (json['endTime'] as String?) ?? '',
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
