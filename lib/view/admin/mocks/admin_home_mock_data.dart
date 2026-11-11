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
