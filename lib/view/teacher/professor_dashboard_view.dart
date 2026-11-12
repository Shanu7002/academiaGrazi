import 'package:academiagrazi/view/components/user_greeting.dart';
import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/teachers/teacher_students.dart';
import 'package:academiagrazi/view/teacher/lista_alunos.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/instructor_schedule_builder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfessorDashboardView extends StatefulWidget {
  /// Abre o aluno na aba Treinos (ficha e treinos realizados).
  final ValueChanged<String>? onOpenStudentTraining;

  /// Abre a montagem da ficha do aluno na aba Treinos.
  final ValueChanged<String>? onEditStudentTraining;

  /// Abre o aluno na aba Evolução (avaliações físicas).
  final ValueChanged<String>? onOpenStudentAssessments;

  const ProfessorDashboardView({
    super.key,
    this.onOpenStudentTraining,
    this.onEditStudentTraining,
    this.onOpenStudentAssessments,
  });

  @override
  State<ProfessorDashboardView> createState() => _ProfessorDashboardViewState();
}

class _ProfessorDashboardViewState extends State<ProfessorDashboardView> {
  /// Prioridades exibidas antes de "Ver todas".
  static const int _collapsedPriorities = 5;

  final String? _teacherId = locator<FirebaseAuth>().currentUser?.uid;
  Future<TeacherDashboardData>? _data;
  bool _showAllPriorities = false;

  static const Color navy = AppColors.primaryDark;
  static const Color green = AppColors.primary;
  static const Color textColor = AppColors.textSecondary;
  static const Color red = AppColors.danger;
  static const Color orange = AppColors.accentDark;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<TeacherDashboardData>? _load() {
    final id = _teacherId;
    if (id == null || id.isEmpty) return null;
    return locator<TeacherDashboardService>().load(id);
  }

  Future<void> _reload() async {
    final data = _load();
    setState(() {
      _data = data;
    });
    try {
      await data;
    } catch (_) {
      // O FutureBuilder mostra o erro.
    }
  }

  /// As ações levam a outras abas; ao voltar, o painel já está atualizado.
  void _openTraining(String studentId) {
    widget.onOpenStudentTraining?.call(studentId);
    _reload();
  }

  void _openAssessments(String studentId) {
    widget.onOpenStudentAssessments?.call(studentId);
    _reload();
  }

  /// Abre a lista de alunos (já filtrada, se for o caso) e atualiza o
  /// painel ao voltar.
  Future<void> _openStudents([
    TeacherStudentFilter filter = TeacherStudentFilter.all,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => ListaAlunosView(
              initialFilter: filter,
              onOpenStudent: widget.onOpenStudentTraining,
              onEditTraining: widget.onEditStudentTraining,
            ),
      ),
    );
    if (mounted) _reload();
  }

  static String _count(int value, String singular, String plural) =>
      '$value ${value == 1 ? singular : plural}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grazi Braz', showBackButton: false),
      body: FutureBuilder<TeacherDashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
              'Erro ao carregar o painel do professor: ${snapshot.error}',
            );
          }
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data;
          return RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: InstructorScheduleBuilder(
                instructorId: _teacherId,
                builder:
                    (context, schedule) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UserGreeting(),
                            const SizedBox(height: 10),
                            Text(
                              schedule.currentLabel,
                              key: const Key('texto_turno_atual'),
                              style: GoogleFonts.barlowCondensed(
                                color: textColor,
                                fontSize: AppFontSize.body,
                              ),
                            ),
                          ],
                        ),
                        if (snapshot.hasError) ...[
                          const SizedBox(height: 16),
                          _LoadError(onRetry: _reload),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardMetricCard(
                                key: const Key('card_alunos_ativos'),
                                asset: 'assets/tresAlunos.svg',
                                title: 'Alunos',
                                value: _metric(loading, data?.activeStudents),
                                description: 'Ativos',
                                onTap:
                                    _teacherId == null ? null : _openStudents,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _DashboardMetricCard(
                                key: const Key('card_presencas'),
                                asset: 'assets/presencas.svg',
                                title: 'Presenças',
                                value: _metric(loading, data?.presentToday),
                                description: 'Hoje',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _DashboardMetricCard(
                          key: const Key('card_risco_evasao'),
                          asset: 'assets/inativo.svg',
                          title: 'Alunos',
                          value: _metric(loading, data?.atRisk.length),
                          description: 'Risco de evasão',
                          fullWidth: true,
                          accentColor: red,
                          shadowColor: red,
                          onTap:
                              data == null || data.atRisk.isEmpty
                                  ? null
                                  : () => _openStudents(
                                    TeacherStudentFilter.atRisk,
                                  ),
                        ),
                        const SizedBox(height: 15),
                        _DashboardMetricCard(
                          key: const Key('card_proximo_turno'),
                          asset: 'assets/relogio.svg',
                          title: 'Próximo Turno',
                          value: schedule.nextUnitLabel,
                          description: schedule.nextWhenLabel,
                          isNextShift: true,
                          accentColor: AppColors.primary,
                          shadowColor: navy,
                        ),
                        const SizedBox(height: 30),
                        _priorities(loading, data),
                      ],
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _metric(bool loading, int? value) =>
      loading ? '…' : (value?.toString() ?? '—');

  Widget _priorities(bool loading, TeacherDashboardData? data) {
    final priorities = data?.priorities ?? const <TeacherPriority>[];
    final visible =
        _showAllPriorities
            ? priorities
            : priorities.take(_collapsedPriorities).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BrandHeading('Prioridades', level: BrandHeadingLevel.section),
            if (priorities.isNotEmpty)
              Container(
                key: const Key('badge_alertas'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _count(priorities.length, 'Alerta', 'Alertas'),
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryChipSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (data == null)
          const SizedBox.shrink()
        else if (priorities.isEmpty)
          Text(
            'Nenhuma pendência hoje. Seus alunos estão em dia!',
            key: const Key('texto_sem_pendencias'),
            style: GoogleFonts.barlowCondensed(
              fontSize: AppFontSize.body,
              color: textColor,
            ),
          )
        else ...[
          for (final priority in visible) ...[
            _priorityCard(priority),
            const SizedBox(height: 15),
          ],
          if (priorities.length > _collapsedPriorities)
            TextButton(
              key: const Key('botao_ver_todas_prioridades'),
              onPressed:
                  () =>
                      setState(() => _showAllPriorities = !_showAllPriorities),
              child: Text(
                _showAllPriorities
                    ? 'Mostrar menos'
                    : 'Ver todas (${priorities.length})',
              ),
            ),
        ],
      ],
    );
  }

  Widget _priorityCard(TeacherPriority priority) {
    final student = priority.student;
    final days = priority.days;
    final key = Key('card_prioridade_${priority.kind.name}_${student.id}');
    final openTraining =
        widget.onOpenStudentTraining == null
            ? null
            : () => _openTraining(student.id);
    return switch (priority.kind) {
      TeacherPriorityKind.inactive => _PriorityCard(
        key: key,
        name: student.name,
        description:
            days == null
                ? 'Ainda não treinou (inativo).'
                : '${_count(days, 'dia', 'dias')} sem treinar (inativo).',
        asset: 'assets/alertaVermelho.svg',
        action: 'Ver perfil',
        accentColor: red,
        iconBackgroundColor: AppColors.accentAlertBorder,
        onTap: openTraining,
      ),
      TeacherPriorityKind.atRisk => _PriorityCard(
        key: key,
        name: student.name,
        description: '${_count(days ?? 0, 'dia', 'dias')} sem treinar.',
        asset: 'assets/alertaVermelho.svg',
        action: 'Ver perfil',
        accentColor: orange,
        iconBackgroundColor: AppColors.accentAlertBorder,
        onTap: openTraining,
      ),
      TeacherPriorityKind.noPlan => _PriorityCard(
        key: key,
        name: student.name,
        description: 'Sem ficha de treino ativa.',
        asset: 'assets/halter.svg',
        action: 'Montar',
        accentColor: green,
        iconBackgroundColor: AppColors.mintBorderBright,
        onTap: openTraining,
      ),
      TeacherPriorityKind.assessmentOverdue => _PriorityCard(
        key: key,
        name: student.name,
        description:
            days == null
                ? 'Ainda sem avaliação física.'
                : 'Última avaliação há ${_count(days, 'dia', 'dias')}.',
        asset: 'assets/quadradoAviso.svg',
        action: 'Revisar',
        accentColor: orange,
        iconBackgroundColor: AppColors.accentAlertBorder,
        onTap:
            widget.onOpenStudentAssessments == null
                ? null
                : () => _openAssessments(student.id),
      ),
    };
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.dangerSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Não conseguimos carregar seus alunos agora. Confira a conexão.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSize.small,
            ),
          ),
        ),
        TextButton(
          key: const Key('botao_tentar_novamente'),
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

// ============================================================
// COMPONENTE REUTILIZÁVEL: CARDS DE MÉTRICAS E PRÓXIMO TURNO
// ============================================================

class _DashboardMetricCard extends StatelessWidget {
  final String asset;
  final String title;
  final String value;
  final String description;
  final bool fullWidth;
  final bool isNextShift;
  final Color accentColor;
  final Color shadowColor;
  final VoidCallback? onTap;

  const _DashboardMetricCard({
    super.key,
    required this.asset,
    required this.title,
    required this.value,
    required this.description,
    this.fullWidth = false,
    this.isNextShift = false,
    this.accentColor = AppColors.primary,
    this.shadowColor = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tappable(onTap: onTap, child: _card());
  }

  Widget _card() {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e título
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 50, maxHeight: 50),
                child: SvgPicture.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Conteúdo específico de cada tipo de card
          if (isNextShift) ...[
            Text(
              value,
              style: GoogleFonts.barlowCondensed(
                fontWeight: FontWeight.w700,
                fontSize: AppFontSize.headline,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: GoogleFonts.barlowCondensed(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Proteção de layout: Reduz o tamanho da fonte caso o texto seja muito longo
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.barlowCondensed(
                        fontWeight: FontWeight.w700,
                        fontSize: AppFontSize.display,
                        color:
                            fullWidth
                                ? AppColors.danger
                                : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTE REUTILIZÁVEL: CARD DE PRIORIDADE
// ============================================================

class _PriorityCard extends StatelessWidget {
  final String name;
  final String description;
  final String asset;
  final String action;
  final Color accentColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  const _PriorityCard({
    super.key,
    required this.name,
    required this.description,
    required this.asset,
    required this.action,
    required this.accentColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tappable(onTap: onTap, child: _card());
  }

  Widget _card() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      asset,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.title,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: AppFontSize.body,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    action,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Torna um cartão tocável sem mudar o visual; sem [onTap], só o cartão.
class _Tappable extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _Tappable({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
