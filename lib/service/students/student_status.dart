import 'package:academiagrazi/config/business_rules.dart';

/// Situação do aluno a partir do último treino finalizado.
///
/// Usada pelo dashboard do professor, pela lista de alunos e pelo admin:
/// nenhuma tela calcula o status por conta própria.
enum StudentStatus {
  /// Treinou há menos de [BusinessRules.riskDaysWithoutTraining] dias.
  active,

  /// Sem treino há [BusinessRules.riskDaysWithoutTraining] dias ou mais.
  atRisk,

  /// Sem treino há [BusinessRules.inactiveDaysWithoutTraining] dias ou mais.
  inactive,

  /// Ainda sem treino finalizado e cadastrado há menos de
  /// [BusinessRules.inactiveDaysWithoutTraining] dias.
  newcomer,
}

/// Dias de calendário entre [since] e [now], no fuso local.
///
/// Conta dias, não blocos de 24 h: um treino ontem às 23h, visto hoje às
/// 8h, conta 1 dia. Nunca é negativo.
int daysSince(DateTime since, DateTime now) {
  final start = since.toLocal();
  final end = now.toLocal();
  // UTC evita a diferença de 23/25 h em dias com troca de horário.
  final startDay = DateTime.utc(start.year, start.month, start.day);
  final endDay = DateTime.utc(end.year, end.month, end.day);
  final days = endDay.difference(startDay).inDays;
  return days < 0 ? 0 : days;
}

/// Dias desde o último treino finalizado, ou `null` se nunca treinou.
int? daysWithoutTraining(DateTime? lastFinishedAt, DateTime now) {
  return lastFinishedAt == null ? null : daysSince(lastFinishedAt, now);
}

/// Status do aluno pelo último treino finalizado ([lastFinishedAt]).
///
/// Quem nunca treinou é [StudentStatus.newcomer] enquanto o cadastro
/// ([createdAt]) tiver menos de [BusinessRules.inactiveDaysWithoutTraining]
/// dias; depois disso (ou sem data de cadastro) é
/// [StudentStatus.inactive].
StudentStatus statusFor({
  required DateTime? lastFinishedAt,
  required DateTime? createdAt,
  required DateTime now,
}) {
  final days = daysWithoutTraining(lastFinishedAt, now);
  if (days == null) {
    final joinedDaysAgo = createdAt == null ? null : daysSince(createdAt, now);
    return joinedDaysAgo != null &&
            joinedDaysAgo < BusinessRules.inactiveDaysWithoutTraining
        ? StudentStatus.newcomer
        : StudentStatus.inactive;
  }
  if (days >= BusinessRules.inactiveDaysWithoutTraining) {
    return StudentStatus.inactive;
  }
  if (days >= BusinessRules.riskDaysWithoutTraining) {
    return StudentStatus.atRisk;
  }
  return StudentStatus.active;
}
