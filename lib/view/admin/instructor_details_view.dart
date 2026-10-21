import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/mocks/admin_team_mock_data.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/invite_code_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Detalhes de um professor: dados de acesso, carga e alunos vinculados.
class InstructorDetailsView extends StatefulWidget {
  final String instructorId;

  const InstructorDetailsView({super.key, required this.instructorId});

  @override
  State<InstructorDetailsView> createState() => _InstructorDetailsViewState();
}

class _InstructorDetailsViewState extends State<InstructorDetailsView> {
  final AdminDashboardService _dashboardService =
      locator<AdminDashboardService>();
  final TextEditingController _searchController = TextEditingController();
  late Future<InstructorDetails?> _details;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _details = _dashboardService.getInstructorDetails(widget.instructorId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _details = _dashboardService.getInstructorDetails(widget.instructorId);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Grazi Braz'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: FutureBuilder<InstructorDetails?>(
            future: _details,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return _CenteredMessage(
                  icon: Icons.cloud_off_outlined,
                  message:
                      'Não foi possível carregar o professor. '
                      'Tente novamente.',
                  actionLabel: 'Tentar novamente',
                  onAction: _reload,
                );
              }

              final details = snapshot.data;
              if (details == null) {
                return _CenteredMessage(
                  icon: Icons.person_off_outlined,
                  message: 'Professor não encontrado.',
                  actionLabel: 'Voltar',
                  onAction: () => Navigator.of(context).maybePop(),
                );
              }

              return _buildContent(details);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(InstructorDetails details) {
    final query = _search.trim().toLowerCase();
    final students =
        query.isEmpty
            ? details.students
            : details.students
                .where(
                  (s) =>
                      s.user.name.toLowerCase().contains(query) ||
                      s.user.email.toLowerCase().contains(query),
                )
                .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _reload();
        await _details;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _ProfileCard(details: details),
          const SizedBox(height: 16),
          _WorkloadCard(details: details),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              key: const Key('botao_redistribuir_professor'),
              onPressed:
                  () => _showMessage(
                    'Redistribuir alunos estará disponível em breve.',
                  ),
              icon: const Icon(Icons.sync, size: 20),
              label: Text(
                'Redistribuir Alunos',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle('Alunos (${details.students.length})'),
          const SizedBox(height: 16),
          if (details.students.isEmpty)
            const _EmptyStudents()
          else ...[
            TextField(
              key: const Key('campo_busca_aluno'),
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar aluno por nome ou e-mail',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum aluno encontrado para "$_search".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.slateText,
                  ),
                ),
              ),
            for (final student in students) ...[
              _StudentTile(
                student: student,
                onTap: () => _showStudentSheet(student),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  void _showStudentSheet(InstructorStudent student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StudentSheet(student: student),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const int _capacity = AdminTeamMockData.studentCapacity;

String _initials(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
        '${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }
  return phone;
}

String _goalLabel(PrimaryGoal goal) {
  switch (goal) {
    case PrimaryGoal.weightLoss:
      return 'Emagrecimento & Definição';
    case PrimaryGoal.muscleGain:
      return 'Ganho de Massa Muscular';
    case PrimaryGoal.conditioning:
      return 'Condicionamento & Saúde';
    case PrimaryGoal.strengthening:
      return 'Fortalecimento & Postura';
    case PrimaryGoal.mobility:
      return 'Mobilidade & Flexibilidade';
  }
}

const _noneOptions = {'Nenhuma dor', 'Não possuo'};

/// Condições e restrições relevantes, sem as opções de "nenhuma".
List<String> _healthAlerts(RegistrationProfile? profile) {
  if (profile == null) return const [];
  return [
    ...profile.health.conditions,
    ...profile.health.restrictions,
  ].where((item) => !_noneOptions.contains(item)).toList();
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

TextStyle get _labelStyle => GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: .5,
  color: AppColors.slateText,
);

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final InstructorDetails details;
  const _ProfileCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final instructor = details.instructor;
    final name = instructor.name.trim().isEmpty ? 'Sem nome' : instructor.name;
    final overloaded = details.students.length > _capacity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    overloaded
                        ? AppColors.dangerSurface
                        : AppColors.avatarBackground,
                child: Text(
                  _initials(name),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: overloaded ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AdminTeamMockData.instructorRole.toUpperCase(),
                      style: _labelStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'E-mail',
            value:
                instructor.email.isEmpty ? 'Não informado' : instructor.email,
          ),
          const SizedBox(height: 12),
          InviteCodeCard(
            instructorId: instructor.id,
            description:
                'Os alunos usam este código para se vincular ao professor.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: _labelStyle),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  final InstructorDetails details;

  const _WorkloadCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final total = details.students.length;
    final load = total / _capacity;
    final overloaded = total > _capacity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(
        borderColor:
            overloaded ? AppColors.dangerSurface : AppColors.borderTranslucent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Carga de Trabalho',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      overloaded
                          ? AppColors.dangerSurface
                          : AppColors.avatarBackground,
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(value: '$total', label: 'Alunos ativos'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '${details.newStudents()}',
                  label: 'Novos (30 dias)',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _StatTile(
                  value: AdminTeamMockData.pendingEvaluations,
                  label: 'Avaliações pendentes',
                  valueColor: AppColors.accentDark,
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
                '$total/$_capacity',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: overloaded ? AppColors.danger : AppColors.slateText,
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
              color: overloaded ? AppColors.accentDark : AppColors.chartBar,
              backgroundColor: AppColors.chartBarInactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoSoftSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.3,
              color: AppColors.slateText,
            ),
          ),
        ],
      ),
    );
  }
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

class _StudentTile extends StatelessWidget {
  final InstructorStudent student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = student.user;
    final name = user.name.trim().isEmpty ? 'Sem nome' : user.name;
    final profile = user.registrationProfile;
    final alerts = _healthAlerts(profile);
    final subtitle = [
      if (profile != null) _goalLabel(profile.primaryGoal),
      if (student.joinedAt != null) 'Desde ${_formatDate(student.joinedAt!)}',
    ].join(' • ');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('aluno_${user.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.infoSoftSurface,
                child: Text(
                  _initials(name),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.slateText,
                        ),
                      ),
                    ],
                    if (alerts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            size: 16,
                            color: AppColors.accentDark,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Atenção à saúde',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentSheet extends StatelessWidget {
  final InstructorStudent student;

  const _StudentSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final user = student.user;
    final profile = user.registrationProfile;
    final alerts = _healthAlerts(profile);
    final notes = profile?.health.notes.trim() ?? '';
    final emergency = profile?.emergencyContact;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .85,
          maxWidth: 430,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name.trim().isEmpty ? 'Sem nome' : user.name,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                user.email,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.slateText,
                ),
              ),
              const SizedBox(height: 20),
              if (profile == null)
                Text(
                  'Este aluno ainda não completou a ficha de cadastro.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.slateText,
                  ),
                )
              else ...[
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Objetivo',
                  value: _goalLabel(profile.primaryGoal),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.straighten,
                  label: 'Medidas',
                  value:
                      '${profile.measurements.age} anos • '
                      '${profile.measurements.heightCm} cm • '
                      '${profile.measurements.weightKg.toStringAsFixed(1)} kg',
                ),
                if (student.joinedAt != null) ...[
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Aluno desde',
                    value: _formatDate(student.joinedAt!),
                  ),
                ],
                const SizedBox(height: 20),
                Text('SAÚDE', style: _labelStyle),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  Text(
                    'Sem condições ou restrições informadas.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textBody,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final alert in alerts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentAlertSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accentAlertBorder,
                            ),
                          ),
                          child: Text(
                            alert,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentText,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    notes,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
                if (emergency != null && emergency.name.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.contact_phone_outlined,
                    label: 'Contato de emergência',
                    value: [
                      emergency.name,
                      if (emergency.relationship.isNotEmpty)
                        emergency.relationship,
                      if (emergency.phone.isNotEmpty)
                        _formatPhone(emergency.phone),
                    ].join(' • '),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.group_off_outlined,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum aluno vinculado a este professor ainda. Os alunos se '
            'vinculam usando o código de convite.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: AppColors.slateText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CenteredMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.slateText,
              ),
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
      ),
    );
  }
}
