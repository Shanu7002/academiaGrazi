/// Regras de negócio da academia como constantes nomeadas.
///
/// Telas e services usam estes valores em vez de números soltos. Cada
/// constante cita a pendência de definição (P1, P2…) de `docs/BACKLOG.md`
/// que a originou; para mudar um valor, altere-o aqui e no backlog.
abstract final class BusinessRules {
  /// P1 · Dias sem treino finalizado para o aluno entrar em
  /// "risco de evasão".
  static const int riskDaysWithoutTraining = 10;

  /// P2 · Dias sem treino finalizado para o aluno ser considerado inativo
  /// (o admin exibe "Inativos (30D+)").
  static const int inactiveDaysWithoutTraining = 30;

  /// P3 · A sequência conta semanas consecutivas com pelo menos este número
  /// de treinos finalizados.
  static const int streakMinFinishedSessionsPerWeek = 1;

  /// P4 · Dias de antecedência para uma avaliação agendada virar prioridade
  /// "vence em X dias".
  static const int assessmentDueSoonDays = 3;

  /// P5 · Duração estimada da ficha:
  /// Σ(séries × (repetições × [secondsPerRep] + descanso)) +
  /// [warmupMinutes] de aquecimento.
  static const int secondsPerRep = 4;

  /// P5 · Minutos de aquecimento somados à duração estimada.
  static const int warmupMinutes = 5;

  /// P5 · Volume "Leve" vai até este total de séries.
  static const int lightVolumeMaxSets = 12;

  /// P5 · Volume "Médio" vai até este total de séries; acima é "Intenso".
  static const int mediumVolumeMaxSets = 20;

  /// P6 · O admin recebe alerta quando os inativos passam desta fração dos
  /// alunos ativos (0.10 = 10%).
  static const double inactiveStudentsAlertRatio = 0.10;

  /// GB-085 · Capacidade de alunos de um professor sem `studentCapacity`
  /// cadastrada. Acima dela, o admin recebe o alerta de sobrecarga.
  static const int defaultStudentCapacity = 30;
}
