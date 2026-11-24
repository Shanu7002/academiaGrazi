import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/units/unit_model.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:academiagrazi/service/teachers/teacher_dashboard.dart';
import 'package:academiagrazi/service/teachers/teacher_students.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/instructor_schedule_builder.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:academiagrazi/view/components/user_greeting.dart';
import 'package:academiagrazi/view/components/weekdays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lista dos alunos do professor, com busca, filtros e a situação de cada um.
///
/// Aberta pelo painel do professor (card "Alunos" e card de risco).
class ListaAlunosView extends StatefulWidget {
  /// Filtro já aplicado ao abrir (ex.: risco de evasão).
  final TeacherStudentFilter initialFilter;

  /// Abre o aluno (resumo de treinos) na aba Treinos.
  final ValueChanged<String>? onOpenStudent;

  /// Abre a montagem da ficha do aluno na aba Treinos.
  final ValueChanged<String>? onEditTraining;

  const ListaAlunosView({
    super.key,
    this.initialFilter = TeacherStudentFilter.all,
    this.onOpenStudent,
    this.onEditTraining,
  });

  @override
  State<ListaAlunosView> createState() => _ListaAlunosViewState();
}

class _ListaAlunosViewState extends State<ListaAlunosView> {
  final String? _teacherId = locator<FirebaseAuth>().currentUser?.uid;
  late final TeacherDashboardService _service =
      locator<TeacherDashboardService>();
  final _search = TextEditingController();

  Future<List<TeacherStudentSnapshot>>? _students;
  Stream<List<UnitModel>>? _units;
  late TeacherStudentFilter _filter = widget.initialFilter;
  String? _unitId;

  @override
  void initState() {
    super.initState();
    _students = _load();
    // Sem o service de unidades (testes isolados), sem filtro por unidade.
    if (locator.isRegistered<UnitService>()) {
      _units = locator<UnitService>().streamUnits();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<TeacherStudentSnapshot>>? _load() {
    final id = _teacherId;
    if (id == null || id.isEmpty) return null;
    return _service.loadStudents(id);
  }

  Future<void> _reload() async {
    final students = _load();
    setState(() {
      _students = students;
    });
    try {
      await students;
    } catch (_) {
      // O FutureBuilder mostra o erro.
    }
  }

  /// Fecha a lista e leva o professor à aba Treinos.
  void _go(ValueChanged<String>? action, String studentId) {
    if (action == null) return;
    Navigator.of(context).pop();
    action(studentId);
  }

  void _select(TeacherStudentFilter filter, {String? unitId}) {
    setState(() {
      _filter = filter;
      _unitId = unitId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      body: FutureBuilder<List<TeacherStudentSnapshot>>(
        future: _students,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const UserGreeting(),
                const SizedBox(height: 10),
                InstructorScheduleBuilder(
                  instructorId: _teacherId,
                  builder:
                      (context, schedule) => Text(
                        schedule.currentLabel,
                        style: GoogleFonts.barlowCondensed(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSize.body,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('campo_busca_aluno'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar aluno...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _filters(snapshot.data),
                const SizedBox(height: 15),
                ..._content(snapshot),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(List<TeacherStudentSnapshot>? students) {
    final studentUnits = {
      for (final item in students ?? const <TeacherStudentSnapshot>[])
        if (item.student.unitId != null) item.student.unitId!,
    };
    Widget chip(
      String key,
      String label,
      TeacherStudentFilter filter, {
      String? unitId,
    }) {
      final selected = _filter == filter && _unitId == unitId;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: Key(key),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.primary,
          labelStyle: GoogleFonts.barlowCondensed(
            fontWeight: FontWeight.bold,
            fontSize: AppFontSize.small,
            color: selected ? AppColors.onAccent : AppColors.primary,
          ),
          side: const BorderSide(color: AppColors.primary),
          backgroundColor: AppColors.surface,
          onSelected: (_) => _select(filter, unitId: unitId),
        ),
      );
    }

    return StreamBuilder<List<UnitModel>>(
      stream: _units,
      builder: (context, unitsSnapshot) {
        final units =
            (unitsSnapshot.data ?? const <UnitModel>[])
                .where((unit) => studentUnits.contains(unit.id))
                .toList();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('filtro_todos', 'Todos', TeacherStudentFilter.all),
              chip(
                'filtro_risco',
                'Risco de evasão',
                TeacherStudentFilter.atRisk,
              ),
              chip(
                'filtro_inativos',
                'Inativos',
                TeacherStudentFilter.inactive,
              ),
              chip(
                'filtro_avaliacao_pendente',
                'Avaliação pendente',
                TeacherStudentFilter.assessmentPending,
              ),
              for (final unit in units)
                chip(
                  'filtro_unidade_${unit.id}',
                  unit.name,
                  TeacherStudentFilter.all,
                  unitId: unit.id,
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(AsyncSnapshot<List<TeacherStudentSnapshot>> snapshot) {
    if (snapshot.hasError) {
      debugPrint('Erro ao carregar a lista de alunos: ${snapshot.error}');
      return [
        _Message(
          text:
              'Não conseguimos carregar seus alunos agora. Confira a conexão.',
          action: OutlinedButton(
            key: const Key('botao_tentar_novamente'),
            onPressed: _reload,
            child: const Text('Tentar novamente'),
          ),
        ),
      ];
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final students = snapshot.data ?? const <TeacherStudentSnapshot>[];
    if (students.isEmpty) {
      return const [
        _Message(
          key: Key('texto_sem_alunos'),
          text:
              'Você ainda não tem alunos. Compartilhe seu código de convite, '
              'que fica no Perfil, para eles se cadastrarem.',
        ),
      ];
    }
    final now = _service.now;
    final rows = filterTeacherStudents(
      teacherStudentRows(students, now),
      query: _search.text,
      filter: _filter,
      unitId: _unitId,
    );
    if (rows.isEmpty) {
      return const [
        _Message(
          key: Key('texto_sem_resultado'),
          text: 'Nenhum aluno encontrado com esse filtro.',
        ),
      ];
    }
    return [
      for (final row in rows) ...[
        CardAluno(
          key: Key('card_aluno_${row.id}'),
          row: row,
          now: now,
          onVerPerfil:
              widget.onOpenStudent == null
                  ? null
                  : () => _go(widget.onOpenStudent, row.id),
          onEditarTreino:
              widget.onEditTraining == null
                  ? null
                  : () => _go(widget.onEditTraining, row.id),
        ),
        const SizedBox(height: 15),
      ],
    ];
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({super.key, required this.text, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.barlowCondensed(
            fontSize: AppFontSize.body,
            color: AppColors.textSecondary,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

/// Cartão de um aluno: foto, situação e as ações do professor.
class CardAluno extends StatelessWidget {
  final TeacherStudentRow row;
  final DateTime now;
  final VoidCallback? onVerPerfil;
  final VoidCallback? onEditarTreino;

  const CardAluno({
    super.key,
    required this.row,
    required this.now,
    this.onVerPerfil,
    this.onEditarTreino,
  });

  static const Color green = AppColors.primary;

  (String, Color) get _status => switch (row.status) {
    StudentStatus.active => ('Ativo', AppColors.primary),
    StudentStatus.atRisk => ('Risco', AppColors.accentText),
    StudentStatus.inactive => ('Inativo', AppColors.danger),
    StudentStatus.newcomer => ('Novo', AppColors.info),
  };

  String get _subtitle {
    final days = row.daysIdle;
    String plural(int value) => value == 1 ? '1 dia' : '$value dias';
    switch (row.status) {
      case StudentStatus.inactive:
        return days == null
            ? 'Inativo (ainda não treinou)'
            : 'Inativo (${plural(days)})';
      case StudentStatus.atRisk:
        return '${plural(days ?? 0)} sem treinar';
      case StudentStatus.newcomer:
        return 'Ainda não treinou';
      case StudentStatus.active:
        final next = row.nextTrainingDay;
        if (next != null) return 'Próximo treino ${_dayLabel(next)}';
        if (row.snapshot.hasHomeWorkout) return 'Treina em casa';
        return row.snapshot.hasActivePlan
            ? 'Treinou ${days == 0 ? 'hoje' : 'há ${plural(days ?? 0)}'}'
            : 'Sem ficha de treino';
    }
  }

  String _dayLabel(DateTime day) {
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'hoje';
    if (day == DateTime(now.year, now.month, now.day + 1)) return 'amanhã';
    return weekdayName(day.weekday).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _status;
    final hasPlan = row.snapshot.hasActivePlan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                photoUrl: row.snapshot.student.photoUrl,
                size: 60,
                backgroundColor: AppColors.avatarBackground,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        color: AppColors.primaryDark,
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      key: Key('texto_situacao_${row.id}'),
                      style: GoogleFonts.barlowCondensed(
                        color: AppColors.textBody,
                        fontSize: AppFontSize.small,
                      ),
                    ),
                    if (row.assessmentPending) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Avaliação física pendente',
                        style: GoogleFonts.barlowCondensed(
                          color: AppColors.accentText,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 9, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: GoogleFonts.barlowCondensed(
                      color: statusColor,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onVerPerfil != null || onEditarTreino != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (onVerPerfil != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      key: Key('botao_ver_perfil_${row.id}'),
                      onPressed: onVerPerfil,
                      icon: SvgPicture.asset(
                        'assets/iconePerfil.svg',
                        width: 18,
                        height: 18,
                      ),
                      label: const Text('Ver perfil'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                    ),
                  ),
                if (onVerPerfil != null && onEditarTreino != null)
                  const SizedBox(width: 10),
                if (onEditarTreino != null)
                  Expanded(
                    child: FilledButton.icon(
                      key: Key('botao_editar_treino_${row.id}'),
                      onPressed: onEditarTreino,
                      icon: SvgPicture.asset(
                        'assets/editarPerfil.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.onAccent,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(hasPlan ? 'Editar treino' : 'Montar treino'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        minimumSize: const Size(0, 46),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
