import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/students/student_status.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/admin/widgets/student_registration_details.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dados do aluno para o admin, com a troca do professor responsável e da
/// modalidade. Mostra a ficha de saúde: dado sensível, só para o admin.
class AdminStudentDetailsView extends StatefulWidget {
  final String studentId;

  const AdminStudentDetailsView({super.key, required this.studentId});

  @override
  State<AdminStudentDetailsView> createState() =>
      _AdminStudentDetailsViewState();
}

class _AdminStudentDetailsViewState extends State<AdminStudentDetailsView> {
  final AdminStudentService _service = locator<AdminStudentService>();
  final AdminDashboardService _dashboardService =
      locator<AdminDashboardService>();

  late Stream<UserModel?> _student;
  late Stream<List<UserModel>> _instructors;
  Future<StudentActivity>? _activity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _student = _service.streamStudent(widget.studentId);
    _instructors = _service.streamInstructors();
    _activity = null;
  }

  void _reload() => setState(_subscribe);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      if (!mounted) return;
      _showMessage(success);
    } catch (error) {
      debugPrint('Erro ao salvar aluno: $error');
      if (!mounted) return;
      _showMessage('Não foi possível salvar a alteração. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeInstructor(UserModel student, String? currentName) async {
    final chosen = await showModalBottomSheet<InstructorWorkload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => _InstructorPicker(
            team: _dashboardService.getTeamWorkload(),
            currentId: student.responsable,
          ),
    );
    if (chosen == null || !mounted) return;

    final studentName = student.name.trim().isEmpty ? 'o aluno' : student.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Trocar professor responsável?'),
            content: Text(
              '$studentName passa de '
              '${currentName ?? 'nenhum professor'} para ${chosen.name}. '
              'A ficha atual continua valendo até ${chosen.name} publicar '
              'uma nova.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('botao_confirmar_troca_professor'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Trocar'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    await _save(
      () => _service.changeInstructor(student.id, chosen.id),
      'Professor responsável atualizado.',
    );
  }

  Future<void> _changeModality(
    UserModel student,
    StudentModality modality,
  ) async {
    if (student.modality == modality) return;
    await _save(
      () => _service.setModality(student.id, modality),
      'Modalidade atualizada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Aluno'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StreamBuilder<UserModel?>(
            stream: _student,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Erro ao carregar aluno: ${snapshot.error}');
                return _Message(
                  text: 'Não foi possível carregar o aluno.',
                  action: TextButton(
                    key: const Key('botao_tentar_aluno'),
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              final student = snapshot.data;
              if (student == null) {
                return const _Message(text: 'Aluno não encontrado.');
              }
              _activity ??= _service.getActivity(student);
              return StreamBuilder<List<UserModel>>(
                stream: _instructors,
                builder: (context, instructorsSnapshot) {
                  final instructors = instructorsSnapshot.data;
                  final String? instructorName;
                  if (student.responsable == null) {
                    instructorName = null;
                  } else if (instructors == null) {
                    instructorName = '...';
                  } else {
                    instructorName =
                        instructors
                            .where((i) => i.id == student.responsable)
                            .map((i) => i.name)
                            .firstOrNull;
                  }
                  return _details(student, instructorName);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _details(UserModel student, String? instructorName) {
    final name = student.name.trim().isEmpty ? 'Sem nome' : student.name;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _Card(
          child: Row(
            children: [
              UserAvatar(
                photoUrl: student.photoUrl,
                size: 72,
                backgroundColor: AppColors.avatarBackground,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      student.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.slateText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ActivityBadge(activity: _activity),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VÍNCULO', style: adminLabelStyle),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdminInfoRow(
                      icon: Icons.sports_gymnastics,
                      label: 'Professor responsável',
                      value: instructorName ?? 'Sem professor',
                    ),
                  ),
                  TextButton(
                    key: const Key('botao_trocar_professor'),
                    onPressed:
                        _saving
                            ? null
                            : () => _changeInstructor(student, instructorName),
                    child: const Text('Trocar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AdminInfoRow(
                icon: Icons.laptop_chromebook,
                label: 'Modalidade',
                value:
                    student.modality == null
                        ? 'Ainda não definida'
                        : student.modality == StudentModality.remote
                        ? 'Remoto (treina em casa)'
                        : 'Presencial',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<StudentModality>(
                  key: const Key('seletor_modalidade_aluno'),
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: StudentModality.onSite,
                      label: Text('Presencial'),
                      icon: Icon(Icons.fitness_center, size: 18),
                    ),
                    ButtonSegment(
                      value: StudentModality.remote,
                      label: Text('Remoto'),
                      icon: Icon(Icons.home_outlined, size: 18),
                    ),
                  ],
                  selected: {if (student.modality != null) student.modality!},
                  onSelectionChanged:
                      _saving
                          ? null
                          : (selection) {
                            if (selection.isEmpty) return;
                            _changeModality(student, selection.first);
                          },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('FICHA DE CADASTRO', style: adminLabelStyle),
              const SizedBox(height: 12),
              StudentRegistrationDetails(
                user: student,
                joinedAt: student.createdAt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _statusLabel(StudentStatus status) => switch (status) {
  StudentStatus.active => 'Ativo',
  StudentStatus.atRisk => 'Em risco',
  StudentStatus.inactive => 'Inativo',
  StudentStatus.newcomer => 'Novo',
};

class _ActivityBadge extends StatelessWidget {
  final Future<StudentActivity>? activity;

  const _ActivityBadge({required this.activity});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentActivity>(
      future: activity,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.hasError) {
          debugPrint('Erro ao calcular situação: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        if (data == null) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final (color, surface) = switch (data.status) {
          StudentStatus.active => (
            AppColors.primary,
            AppColors.avatarBackground,
          ),
          StudentStatus.newcomer => (
            AppColors.primaryDark,
            AppColors.infoSoftSurface,
          ),
          StudentStatus.atRisk => (
            AppColors.accentText,
            AppColors.accentAlertSurface,
          ),
          StudentStatus.inactive => (AppColors.danger, AppColors.dangerSurface),
        };
        final last = data.lastFinishedAt;
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              key: const Key('situacao_aluno'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _statusLabel(data.status),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              last == null
                  ? 'Nenhum treino finalizado'
                  : 'Último treino em ${formatDateBr(last.toLocal())}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstructorPicker extends StatelessWidget {
  final Future<List<InstructorWorkload>> team;
  final String? currentId;

  const _InstructorPicker({required this.team, required this.currentId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
          maxWidth: 430,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha o novo professor',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FutureBuilder<List<InstructorWorkload>>(
                  future: team,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint(
                        'Erro ao listar professores: ${snapshot.error}',
                      );
                      return const _Message(
                        text: 'Não foi possível carregar os professores.',
                      );
                    }
                    final instructors = snapshot.data;
                    if (instructors == null) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final options =
                        instructors.where((i) => i.id != currentId).toList()
                          ..sort(
                            (a, b) => a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            ),
                          );
                    if (options.isEmpty) {
                      return const _Message(
                        text: 'Não há outro professor cadastrado.',
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final instructor in options)
                          ListTile(
                            key: Key('opcao_professor_${instructor.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              instructor.name.isEmpty
                                  ? 'Professor sem nome'
                                  : instructor.name,
                            ),
                            subtitle: Text(
                              '${instructor.activeStudents}/'
                              '${instructor.capacity} alunos'
                              '${instructor.isOverCapacity ? ' · acima da capacidade' : ''}',
                              style: TextStyle(
                                color:
                                    instructor.isOverCapacity
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, instructor),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Message({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
