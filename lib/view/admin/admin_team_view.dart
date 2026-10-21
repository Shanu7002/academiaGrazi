import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/mocks/admin_team_mock_data.dart';
import 'package:academiagrazi/view/admin/register_instructor_view.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gestão da equipe: carga de alunos de cada professor.
class AdminTeamView extends StatefulWidget {
  const AdminTeamView({super.key});

  @override
  State<AdminTeamView> createState() => _AdminTeamViewState();
}

class _AdminTeamViewState extends State<AdminTeamView> {
  final AdminDashboardService _dashboardService =
      locator<AdminDashboardService>();
  late Future<List<InstructorWorkload>> _team;

  @override
  void initState() {
    super.initState();
    _team = _dashboardService.getTeamWorkload();
  }

  void _reload() {
    setState(() {
      _team = _dashboardService.getTeamWorkload();
    });
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponível em breve.')),
    );
  }

  Future<void> _openRegister() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterInstructorView()));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Grazi Braz', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _reload();
              await _team;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Carga da Equipe',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Volume de alunos por professor e alertas de '
                    'capacidade.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.slateText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ActionButton(
                    key: const Key('botao_redistribuir_alunos'),
                    icon: Icons.sync,
                    label: 'Redistribuir Alunos',
                    background: AppColors.accent,
                    foreground: AppColors.accentText,
                    onPressed: () => _showSoon('Redistribuir alunos'),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    key: const Key('botao_cadastrar_professor_equipe'),
                    icon: Icons.person_add_alt_1,
                    label: 'Cadastrar Professor',
                    background: AppColors.surface,
                    foreground: AppColors.primary,
                    borderColor: AppColors.primary,
                    onPressed: _openRegister,
                  ),
                  const SizedBox(height: 24),
                  const _NoteCard(),
                  const SizedBox(height: 28),
                  FutureBuilder<List<InstructorWorkload>>(
                    future: _team,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _MessageCard(
                          icon: Icons.cloud_off_outlined,
                          message:
                              'Não foi possível carregar a equipe. '
                              'Tente novamente.',
                          actionLabel: 'Tentar novamente',
                          onAction: _reload,
                        );
                      }

                      final team = snapshot.data ?? const [];
                      if (team.isEmpty) {
                        return _MessageCard(
                          icon: Icons.groups_outlined,
                          message: 'Nenhum professor cadastrado ainda.',
                          actionLabel: 'Cadastrar professor',
                          onAction: _openRegister,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionTitle('Lista de Professores'),
                          const SizedBox(height: 16),
                          for (final instructor in team) ...[
                            _InstructorCard(
                              instructor: instructor,
                              onDetails:
                                  () => _showSoon('Detalhes do professor'),
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 12),
                          const _SectionTitle('Distribuição de Alunos'),
                          const SizedBox(height: 16),
                          _DistributionCard(team: team),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const int _capacity = AdminTeamMockData.studentCapacity;

bool _isOverloaded(InstructorWorkload instructor) =>
    instructor.activeStudents > _capacity;

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

BoxDecoration _cardDecoration({
  Color borderColor = AppColors.borderTranslucent,
}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowCard,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        text,
        style: GoogleFonts.barlowCondensed(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: foreground),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: borderColor ?? background, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoSoftSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderTranslucent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Nota: ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text:
                        'os indicadores consideram os alunos vinculados a cada '
                        'professor. A capacidade de referência é de '
                        '$_capacity alunos por professor.',
                  ),
                ],
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  final InstructorWorkload instructor;
  final VoidCallback onDetails;

  const _InstructorCard({required this.instructor, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final overloaded = _isOverloaded(instructor);
    final load = instructor.activeStudents / _capacity;
    final accent = overloaded ? AppColors.accentDark : AppColors.chartBar;
    final name = instructor.name.isEmpty ? 'Sem nome' : instructor.name;

    return Container(
      key: Key('card_professor_${instructor.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(
        borderColor:
            overloaded ? AppColors.dangerSurface : AppColors.borderTranslucent,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (overloaded) Container(width: 4, color: AppColors.accentDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              overloaded
                                  ? AppColors.dangerSurface
                                  : AppColors.avatarBackground,
                          child: Text(
                            _initials(name),
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  overloaded
                                      ? AppColors.danger
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AdminTeamMockData.instructorRole.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(overloaded: overloaded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: '${instructor.activeStudents}',
                            label: 'Alunos ativos',
                            valueColor: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            value: AdminTeamMockData.pendingEvaluations,
                            label: 'Avaliações pendentes',
                            valueColor: AppColors.accentDark,
                            background:
                                overloaded
                                    ? AppColors.dangerSurface.withValues(
                                      alpha: .35,
                                    )
                                    : AppColors.infoSoftSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Capacidade (${(load * 100).round()}%)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slateText,
                            ),
                          ),
                        ),
                        Text(
                          '${instructor.activeStudents}/$_capacity',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                overloaded
                                    ? AppColors.danger
                                    : AppColors.slateText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: load.clamp(0, 1).toDouble(),
                        minHeight: 10,
                        color: accent,
                        backgroundColor: AppColors.chartBarInactive,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onDetails,
                        iconAlignment: IconAlignment.end,
                        icon: Icon(
                          overloaded ? Icons.error : Icons.arrow_forward,
                          size: 18,
                        ),
                        label: Text(
                          overloaded ? 'Ver Pendências' : 'Ver Detalhes',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool overloaded;

  const _StatusChip({required this.overloaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            overloaded ? AppColors.dangerSurface : AppColors.avatarBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        overloaded ? 'Sobrecarga' : 'Carga equilibrada',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: overloaded ? AppColors.danger : AppColors.primary,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color background;

  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
    this.background = AppColors.infoSoftSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slateText),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final List<InstructorWorkload> team;

  const _DistributionCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final maxStudents = team
        .map((i) => i.activeStudents)
        .fold<int>(_capacity, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comparativo de alunos por professor',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (final instructor in team) ...[
            _DistributionBar(instructor: instructor, maxStudents: maxStudents),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          const Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _LegendItem(color: AppColors.chartBar, label: 'Dentro da meta'),
              _LegendItem(color: AppColors.accentDark, label: 'Acima da meta'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final InstructorWorkload instructor;
  final int maxStudents;

  const _DistributionBar({required this.instructor, required this.maxStudents});

  @override
  Widget build(BuildContext context) {
    final overloaded = _isOverloaded(instructor);
    final name = instructor.name.isEmpty ? 'Sem nome' : instructor.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.slateText,
                ),
              ),
            ),
            Text(
              '${instructor.activeStudents}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: overloaded ? AppColors.danger : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final barWidth = width * instructor.activeStudents / maxStudents;
            final goalX = width * _capacity / maxStudents;

            return SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.chartBarInactive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: barWidth,
                    decoration: BoxDecoration(
                      color:
                          overloaded
                              ? AppColors.accentDark
                              : AppColors.chartBar,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Linha da meta de capacidade.
                  Positioned(
                    left: (goalX - 1).clamp(0, width - 2).toDouble(),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.primaryDark),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.slateText),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.slateText),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
