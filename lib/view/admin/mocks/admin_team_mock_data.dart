// Dados mockados da tela de gestão da equipe.
// Substituir pelos dados reais quando o banco tiver essas informações.

abstract final class AdminTeamMockData {
  // MOCK: ainda não existe capacidade configurável por professor.
  static const int studentCapacity = 30;

  // MOCK: ainda não existe o cadastro de especialidade/cargo do professor.
  static const String instructorRole = 'Professor';

  // MOCK: avaliações físicas ainda não são registradas no banco.
  static const String pendingEvaluations = '--';
}
