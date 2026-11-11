import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_alerts.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/hourly_movement.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/gym_classes_view.dart';
import 'package:academiagrazi/view/admin/instructor_details_view.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
import 'package:academiagrazi/view/admin/units_view.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  final AdminDashboardService _dashboardService =
      locator<AdminDashboardService>();
  late final Future<StudentStats> _studentStats;
  late Future<HourlyMovement> _movement;
  late Future<List<AdminAlert>> _alerts;

  @override
  void initState() {
    super.initState();
    _studentStats = _dashboardService.getStudentStats();
    _movement = _dashboardService.getHourlyMovement();
    _alerts = _loadAlerts(_studentStats);
  }

  /// Alertas automáticos; reaproveita a busca de alunos dos cards.
  Future<List<AdminAlert>> _loadAlerts(Future<StudentStats> stats) async {
    final results = await Future.wait([
      stats,
      _dashboardService.getTeamWorkload(),
    ]);
    return adminAlerts(
      stats: results[0] as StudentStats,
      team: results[1] as List<InstructorWorkload>,
    );
  }

  void _reloadAlerts() {
    setState(() {
      _alerts = _loadAlerts(_dashboardService.getStudentStats());
    });
  }

  void _reloadMovement() {
    setState(() {
      _movement = _dashboardService.getHourlyMovement();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grazi Braz', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visão Geral',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumo operacional de hoje',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 14,
                    color: AppColors.slateText,
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<StudentStats>(
                  future: _studentStats,
                  builder: (context, snapshot) {
                    final stats = snapshot.data;
                    final growth = stats?.growthPercent;

                    String value(int Function(StudentStats) pick) {
                      if (snapshot.hasError) return '--';
                      if (stats == null) return '...';
                      return '${pick(stats)}';
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                key: const Key('card_alunos_ativos'),
                                icon: Icons.directions_walk,
                                iconColor: AppColors.primary,
                                iconBackground: AppColors.avatarBackground,
                                label: 'Alunos ativos',
                                value: value((s) => s.active),
                                badge:
                                    growth == null
                                        ? null
                                        : '+${growth.round()}%',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                key: const Key('card_alunos_remotos'),
                                icon: Icons.laptop_chromebook,
                                iconColor: AppColors.primaryDark,
                                iconBackground: AppColors.infoSoftSurface,
                                label: 'Remotos',
                                value: value((s) => s.remote),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InactiveCard(
                          key: const Key('card_alunos_inativos'),
                          value: value((s) => s.inactive),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Acesso Rápido',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                _QuickAccessButton(
                  key: const Key('botao_equipe'),
                  icon: Icons.group_add,
                  label: 'Equipe',
                  highlighted: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterInstructorView(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _QuickAccessButton(
                  key: const Key('botao_blocos'),
                  icon: Icons.grid_view_rounded,
                  label: 'Blocos',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UnitsView()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _QuickAccessButton(
                  key: const Key('botao_aulas'),
                  icon: Icons.calendar_month,
                  label: 'Aulas',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GymClassesView()),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _MovementCard(movement: _movement, onRetry: _reloadMovement),
                const SizedBox(height: 32),
                _AlertsCard(alerts: _alerts, onRetry: _reloadAlerts),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.borderTranslucent),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowCard,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String? badge;

  const _StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBadge(
                icon: icon,
                color: iconColor,
                background: iconBackground,
              ),
              if (badge != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoftSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveCard extends StatelessWidget {
  final String value;

  const _InactiveCard({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBadge(
            icon: Icons.person_off_outlined,
            color: AppColors.danger,
            background: AppColors.dangerSurface,
          ),
          const SizedBox(height: 12),
          Text(
            'INATIVOS (30D+)',
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onPressed;

  const _QuickAccessButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? Colors.white : AppColors.primaryDark;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: foreground),
        label: Text(
          label,
          style: GoogleFonts.barlowCondensed(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: highlighted ? AppColors.primary : AppColors.surface,
          side: BorderSide(
            color: highlighted ? AppColors.primary : AppColors.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final Future<HourlyMovement> movement;
  final VoidCallback onRetry;

  const _MovementCard({required this.movement, required this.onRetry});

  static const double _chartHeight = 160;

  static String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('card_movimentacao'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: FutureBuilder<HourlyMovement>(
        future: movement,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final peakHour = data?.peakHour;

          Widget body;
          if (snapshot.hasError) {
            body = _MovementMessage(
              text: 'Não foi possível carregar a movimentação.',
              action: TextButton(
                key: const Key('botao_tentar_movimentacao'),
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            );
          } else if (data == null) {
            body = const SizedBox(
              height: _chartHeight,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          } else if (data.isEmpty) {
            body = const _MovementMessage(
              text: 'Nenhum treino finalizado nos últimos 30 dias.',
            );
          } else {
            body = _chart(data);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Movimentação por Horário',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  if (peakHour != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: AppColors.accentText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pico ${peakHour}h',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Treinos finalizados nos últimos 30 dias',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              body,
            ],
          );
        },
      ),
    );
  }

  Widget _chart(HourlyMovement data) {
    final values = data.counts;
    final peak = data.peakCount;
    final peakIndex = values.indexOf(peak);
    final lastHour = data.firstHour + values.length;
    final labels = [data.firstHour, 12, 18, lastHour];

    return Column(
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Tooltip(
                    message:
                        '${_hourLabel(data.firstHour + i)}: '
                        '${values[i]} treino(s)',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: _chartHeight * values[i] / peak,
                        decoration: BoxDecoration(
                          color: _barColor(values[i], peak, i == peakIndex),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                          boxShadow:
                              i == peakIndex
                                  ? const [
                                    BoxShadow(
                                      color: AppColors.accentBorderTransparent,
                                      blurRadius: 10,
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final hour in labels)
              Text(
                _hourLabel(hour),
                style: GoogleFonts.barlowCondensed(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _barColor(int value, int peak, bool isPeak) {
    if (isPeak) return AppColors.accent;
    if (value >= peak * 0.5) return AppColors.chartBar;
    return AppColors.chartBarInactive;
  }
}

class _AlertsCard extends StatelessWidget {
  final Future<List<AdminAlert>> alerts;
  final VoidCallback onRetry;

  const _AlertsCard({required this.alerts, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('card_alertas'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alertas Operacionais',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<AdminAlert>>(
            future: alerts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Erro ao calcular alertas: ${snapshot.error}');
                return _MovementMessage(
                  text: 'Não foi possível carregar os alertas.',
                  action: TextButton(
                    key: const Key('botao_tentar_alertas'),
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }
              final items = snapshot.data;
              if (items == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (items.isEmpty) {
                return const _MovementMessage(
                  text: 'Nenhum alerta no momento.',
                );
              }
              return Column(
                children: [
                  for (final alert in items) ...[
                    _AlertTile(alert: alert),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AdminAlert alert;

  const _AlertTile({required this.alert});

  bool get _isWarning => alert.type == AdminAlertType.instructorOverCapacity;

  void _open(BuildContext context) {
    final instructorId = alert.instructorId;
    if (instructorId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstructorDetailsView(instructorId: instructorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isWarning ? AppColors.accentText : AppColors.primaryDark;
    final canOpen = alert.instructorId != null;

    return Material(
      color:
          _isWarning ? AppColors.accentAlertSurface : AppColors.infoSoftSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              _isWarning
                  ? AppColors.accentAlertBorder
                  : AppColors.borderTranslucent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('alerta_${alert.type.name}_${alert.instructorId ?? ''}'),
        onTap: canOpen ? () => _open(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isWarning ? Icons.groups : Icons.person_off_outlined,
                size: 20,
                color: _isWarning ? AppColors.accent : AppColors.primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 13,
                        height: 1.4,
                        color: _isWarning ? textColor : AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              if (canOpen)
                Icon(Icons.chevron_right, size: 20, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementMessage extends StatelessWidget {
  final String text;
  final Widget? action;

  const _MovementMessage({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlowCondensed(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 4), action!],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
