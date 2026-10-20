// Dados mockados da Home do admin.
// Substituir pelos dados reais quando o banco tiver essas informações.

class AdminAlertMock {
  final String title;
  final String description;
  final bool isWarning;

  const AdminAlertMock({
    required this.title,
    required this.description,
    required this.isWarning,
  });
}

abstract final class AdminHomeMockData {
  // MOCK: ainda não existe modalidade remota no cadastro.
  static const int remoteStudents = 24;

  // MOCK: ainda não registramos check-ins para calcular inatividade.
  static const int inactiveStudents = 8;

  // MOCK: movimentação por horário (06h às 22h). O maior valor é o pico.
  static const List<int> hourlyMovement = [
    4,
    7,
    10,
    8,
    5,
    4,
    9,
    14,
    20,
    17,
    10,
    4,
  ];
  static const String peakLabel = 'Pico 18h';
  static const List<String> hourLabels = ['06:00', '12:00', '18:00', '22:00'];

  // MOCK: alertas operacionais.
  static const List<AdminAlertMock> alerts = [
    AdminAlertMock(
      title: 'Manutenção Necessária',
      description:
          'Esteira 04 apresentando ruído anormal no motor. Último registro: '
          'Prof. Lucas',
      isWarning: true,
    ),
    AdminAlertMock(
      title: 'Atenção da Lotação',
      description:
          'Aula de Spinning às 19h atingiu a capacidade máxima (30/30).',
      isWarning: false,
    ),
  ];
}
