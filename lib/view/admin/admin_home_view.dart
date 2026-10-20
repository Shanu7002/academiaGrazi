import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/mocks/admin_home_mock_data.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
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

  @override
  void initState() {
    super.initState();
    _studentStats = _dashboardService.getStudentStats();
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponível em breve.')),
    );
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
                  style: GoogleFonts.inter(
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
                    final String activeValue;
                    if (snapshot.hasError) {
                      activeValue = '--';
                    } else if (stats == null) {
                      activeValue = '...';
                    } else {
                      activeValue = '${stats.total}';
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            key: const Key('card_alunos_ativos'),
                            icon: Icons.directions_walk,
                            iconColor: AppColors.primary,
                            iconBackground: AppColors.avatarBackground,
                            label: 'Alunos ativos',
                            value: activeValue,
                            badge:
                                growth == null ? null : '+${growth.round()}%',
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: _StatCard(
                            icon: Icons.laptop_chromebook,
                            iconColor: AppColors.primaryDark,
                            iconBackground: AppColors.infoSoftSurface,
                            label: 'Remotos',
                            value: '${AdminHomeMockData.remoteStudents}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _InactiveCard(value: AdminHomeMockData.inactiveStudents),
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
                  icon: Icons.grid_view_rounded,
                  label: 'Blocos',
                  onPressed: () => _showSoon('Blocos'),
                ),
                const SizedBox(height: 12),
                _QuickAccessButton(
                  icon: Icons.calendar_month,
                  label: 'Aulas',
                  onPressed: () => _showSoon('Aulas'),
                ),
                const SizedBox(height: 12),
                _QuickAccessButton(
                  icon: Icons.attach_money,
                  label: 'Finanças',
                  onPressed: () => _showSoon('Finanças'),
                ),
                const SizedBox(height: 32),
                const _MovementCard(),
                const SizedBox(height: 32),
                const _AlertsCard(),
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
                      style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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
  final int value;

  const _InactiveCard({required this.value});

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
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.slateText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
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
          style: GoogleFonts.inter(
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
  const _MovementCard();

  static const double _chartHeight = 160;

  @override
  Widget build(BuildContext context) {
    const values = AdminHomeMockData.hourlyMovement;
    final peak = values.reduce((a, b) => a > b ? a : b);
    final peakIndex = values.indexOf(peak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
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
                      AdminHomeMockData.peakLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: _chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in AdminHomeMockData.hourLabels)
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        label == '18:00' ? FontWeight.bold : FontWeight.normal,
                    color:
                        label == '18:00'
                            ? AppColors.accent
                            : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _barColor(int value, int peak, bool isPeak) {
    if (isPeak) return AppColors.accent;
    if (value >= peak * 0.5) return AppColors.chartBar;
    return AppColors.chartBarInactive;
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          for (final alert in AdminHomeMockData.alerts) ...[
            _AlertTile(alert: alert),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AdminAlertMock alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final textColor =
        alert.isWarning ? AppColors.accentText : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            alert.isWarning
                ? AppColors.accentAlertSurface
                : AppColors.infoSoftSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              alert.isWarning
                  ? AppColors.accentAlertBorder
                  : AppColors.borderTranslucent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert.isWarning ? Icons.build : Icons.groups,
            size: 20,
            color: alert.isWarning ? AppColors.accent : AppColors.primaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: alert.isWarning ? textColor : AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
