import 'package:academiagrazi/config/business_rules.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';

enum AdminAlertType { instructorOverCapacity, inactiveStudents }

/// Alerta automático da home do admin.
class AdminAlert {
  final AdminAlertType type;
  final String title;
  final String description;

  /// Professor relacionado, para abrir os detalhes dele ao tocar.
  final String? instructorId;

  const AdminAlert({
    required this.type,
    required this.title,
    required this.description,
    this.instructorId,
  });
}

/// Alertas calculados a partir dos números do dashboard:
///
/// - professor com mais alunos do que a própria capacidade, do mais
///   sobrecarregado para o menos;
/// - inativos acima de [BusinessRules.inactiveStudentsAlertRatio] dos
///   alunos ativos (P6).
List<AdminAlert> adminAlerts({
  required StudentStats stats,
  required List<InstructorWorkload> team,
}) {
  final overloaded =
      team.where((instructor) => instructor.isOverCapacity).toList()..sort(
        (a, b) => (b.activeStudents - b.capacity).compareTo(
          a.activeStudents - a.capacity,
        ),
      );

  final alerts = [
    for (final instructor in overloaded)
      AdminAlert(
        type: AdminAlertType.instructorOverCapacity,
        title: 'Professor acima da capacidade',
        description:
            '${instructor.name.isEmpty ? 'Professor sem nome' : instructor.name} '
            'está com ${instructor.activeStudents} alunos para '
            '${instructor.capacity} vagas.',
        instructorId: instructor.id,
      ),
  ];

  final active = stats.active;
  if (stats.inactive > 0 &&
      (active <= 0 ||
          stats.inactive / active > BusinessRules.inactiveStudentsAlertRatio)) {
    final percent =
        active <= 0 ? null : (stats.inactive / active * 100).round();
    alerts.add(
      AdminAlert(
        type: AdminAlertType.inactiveStudents,
        title: 'Muitos alunos inativos',
        description:
            '${stats.inactive} alunos sem treinar há '
            '${BusinessRules.inactiveDaysWithoutTraining} dias ou mais'
            '${percent == null ? '' : ' ($percent% dos ativos)'}.',
      ),
    );
  }
  return alerts;
}
