import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/evaluations/physical_evaluation.dart';
import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/models/units/gym_class_model.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/evaluations/evaluation_progress.dart';
import 'package:academiagrazi/service/evaluations/physical_evaluation_service.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/student_weekly_progress.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/service/units/class_schedule.dart';
import 'package:academiagrazi/service/units/gym_class_service.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:academiagrazi/view/components/weekdays.dart';
import 'package:academiagrazi/view/user/student_workout_launcher.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Home do aluno: treino do dia com o professor responsável, atalhos,
/// sequência de treinos, resumo da evolução e próxima aula da unidade.
///
/// Tudo vem do Firestore em tempo real (a home continua montada no
/// `IndexedStack` enquanto o aluno treina pela aba Treinos).
class AlunoHomeView extends StatefulWidget {
  /// Abre a aba Treinos. Sem ele, os botões que levam até ela não aparecem.
  final VoidCallback? onOpenTrainings;

  /// Abre a aba Evolução (atalho "Avaliação").
  final VoidCallback? onOpenEvolution;

  /// Abre a aba Perfil, onde fica a ficha de saúde (atalho "Saúde").
  final VoidCallback? onOpenProfile;

  /// Relógio injetável para os testes.
  final DateTime Function()? clock;

  const AlunoHomeView({
    super.key,
    this.onOpenTrainings,
    this.onOpenEvolution,
    this.onOpenProfile,
    this.clock,
  });

  @override
  State<AlunoHomeView> createState() => _AlunoHomeViewState();
}

class _AlunoHomeViewState extends State<AlunoHomeView> {
  String? _studentId;
  late final StudentWorkoutLauncher _launcher;

  Stream<UserModel?>? _user;
  Stream<AlunoTreinosUiData?>? _training;
  Stream<HomeWorkoutPlan?>? _homeWorkout;
  Stream<TrainingSession?>? _inProgress;
  Stream<List<TrainingSession>>? _history;
  Stream<List<PhysicalEvaluation>>? _evaluations;

  // Recriados só quando o professor ou a unidade do aluno mudam.
  String? _teacherId;
  Future<UserModel?>? _teacher;
  String? _classesUnitId;
  Stream<List<GymClassModel>>? _classes;

  bool _opening = false;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _launcher = StudentWorkoutLauncher(
      plans: locator<TrainingPlanService>(),
      sessions: locator<TrainingSessionService>(),
      homes: locator<HomeWorkoutService>(),
    );
    _studentId = locator<FirebaseAuth>().currentUser?.uid;
    _load();
  }

  void _load() {
    final id = _studentId;
    if (id == null || id.isEmpty) return;
    final sessions = locator<TrainingSessionService>();
    _user = locator<RegisterUserService>().watchUserById(id);
    _training = locator<StudentTrainingViewDataService>().watchActiveUiData(id);
    _homeWorkout = locator<HomeWorkoutService>().watchCurrent(id);
    _inProgress = sessions.watchInProgress(id);
    _history = sessions.watchHistory(id);
    _evaluations = locator<PhysicalEvaluationService>().streamEvaluations(id);
    _teacherId = null;
    _teacher = null;
    _classesUnitId = null;
    _classes = null;
  }

  void _retry() => setState(_load);

  Future<UserModel?>? _teacherOf(UserModel student) {
    final id = student.responsable;
    if (id != _teacherId) {
      _teacherId = id;
      _teacher =
          id == null || id.isEmpty
              ? null
              : locator<RegisterUserService>().getUserById(id);
    }
    return _teacher;
  }

  Stream<List<GymClassModel>>? _classesOf(UserModel student) {
    final unitId = student.unitId;
    if (unitId != _classesUnitId) {
      _classesUnitId = unitId;
      _classes =
          unitId == null || unitId.isEmpty
              ? null
              : locator<GymClassService>().streamClasses(unitId: unitId);
    }
    return _classes;
  }

  /// Bloqueia toques duplicados enquanto a execução abre.
  Future<void> _opens(Future<void> Function(String studentId) open) async {
    final id = _studentId;
    if (_opening || id == null) return;
    setState(() => _opening = true);
    try {
      await open(id);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _startRoutine(String routineId) => _opens(
    (id) =>
        _launcher.startRoutine(context, studentId: id, routineId: routineId),
  );

  void _startHomeRoutine(String routineId) => _opens(
    (id) => _launcher.startHomeRoutine(
      context,
      studentId: id,
      routineId: routineId,
    ),
  );

  void _openHome(HomeWorkoutPlan plan) {
    final id = _studentId;
    if (id == null) return;
    _launcher.openHome(
      context,
      studentId: id,
      plan: plan,
      onStart: _startHomeRoutine,
    );
  }

  void _openHistory() {
    final id = _studentId;
    if (id == null) return;
    _launcher.openHistory(context, studentId: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grazi Braz', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _user == null ? _signedOut() : _content(),
        ),
      ),
    );
  }

  Widget _signedOut() => const _Message(
    icon: Icons.lock_outline_rounded,
    title: 'Entre na sua conta',
    message: 'Faça login para ver seu treino do dia.',
  );

  Widget _content() => StreamBuilder<UserModel?>(
    stream: _user,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        debugPrint('Falha ao carregar o aluno na home: ${snapshot.error}');
        return _Message(
          icon: Icons.cloud_off_outlined,
          title: 'Não conseguimos carregar sua home agora',
          message: 'Confira sua conexão e tente novamente.',
          onRetry: _retry,
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final student = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _trainingSection(student),
          const SizedBox(height: 20),
          _evolutionCard(),
          const SizedBox(height: 20),
          _nextClassCard(student),
        ],
      );
    },
  );

  // ── Treino do dia, atalhos e sequência (dependem das sessões) ──────────

  Widget _trainingSection(UserModel student) =>
      StreamBuilder<List<TrainingSession>>(
        stream: _history,
        builder: (context, historySnapshot) {
          // Uma falha no histórico não impede o treino do dia: só a sequência
          // fica indisponível.
          if (historySnapshot.hasError) {
            debugPrint(
              'Falha ao carregar o histórico: ${historySnapshot.error}',
            );
          }
          final history = historySnapshot.data;
          return StreamBuilder<HomeWorkoutPlan?>(
            stream: _homeWorkout,
            builder: (context, homeSnapshot) {
              final home = homeSnapshot.data;
              final hasHome = home != null && home.routines.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _featuredCard(
                    student,
                    history ?? const [],
                    hasHome ? home : null,
                  ),
                  const SizedBox(height: 15),
                  _shortcuts(hasHome ? home : null),
                  const SizedBox(height: 20),
                  _streakCard(history, failed: historySnapshot.hasError),
                ],
              );
            },
          );
        },
      );

  Widget _featuredCard(
    UserModel student,
    List<TrainingSession> history,
    HomeWorkoutPlan? home,
  ) => _Card(
    key: const Key('card_treino_do_dia'),
    bottomOnly: true,
    child: StreamBuilder<AlunoTreinosUiData?>(
      stream: _training,
      builder: (context, trainingSnapshot) {
        return StreamBuilder<TrainingSession?>(
          stream: _inProgress,
          builder: (context, pendingSnapshot) {
            final Widget body;
            if (trainingSnapshot.hasError) {
              debugPrint(
                'Falha ao carregar a ficha: ${trainingSnapshot.error}',
              );
              body = _FeaturedBody(
                title: 'Não conseguimos carregar seu treino agora',
                subtitle: 'Confira sua conexão e tente novamente.',
                action: OutlinedButton(
                  key: const Key('botao_tentar_novamente'),
                  onPressed: _retry,
                  child: const Text('Tentar novamente'),
                ),
              );
            } else if (trainingSnapshot.connectionState ==
                ConnectionState.waiting) {
              body = const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              body = _featuredBody(
                trainingSnapshot.data,
                pendingSnapshot.data,
                history,
                home,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardLabel(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Treino do dia',
                ),
                const SizedBox(height: 15),
                body,
                _teacherRow(student),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _featuredBody(
    AlunoTreinosUiData? training,
    TrainingSession? pending,
    List<TrainingSession> history,
    HomeWorkoutPlan? home,
  ) {
    if (training == null) {
      if (home != null) {
        return _FeaturedBody(
          title: 'Treino em casa',
          subtitle:
              home.routines.length == 1
                  ? '1 treino montado pelo seu professor'
                  : '${home.routines.length} treinos montados pelo seu '
                      'professor',
          action: _primaryButton(
            key: const Key('botao_abrir_treino_em_casa'),
            label: 'Abrir treino em casa',
            onPressed: () => _openHome(home),
          ),
        );
      }
      return const _FeaturedBody(
        key: Key('texto_aguardando_treino'),
        title: 'Aguardando seu professor',
        subtitle:
            'Seu professor ainda vai montar seu treino. Assim que ele '
            'publicar, ele aparece aqui.',
      );
    }

    final now = _now;
    final routine = _routineOf(
      training,
      training.programacaoSemanal[now.weekday],
    );
    if (routine == null) {
      return _FeaturedBody(
        key: const Key('texto_dia_descanso'),
        title: 'Hoje é dia de descanso',
        subtitle:
            'Sem treino programado para hoje. Aproveite para recuperar '
            'a energia.',
        action:
            widget.onOpenTrainings == null
                ? null
                : OutlinedButton(
                  key: const Key('botao_ver_treinos'),
                  onPressed: widget.onOpenTrainings,
                  child: const Text('Ver seus treinos'),
                ),
      );
    }

    final done = StudentWeeklyProgress.completedRoutineOnDay(
      history,
      now,
      routine.id,
    );
    if (StudentWeeklyProgress.isOpenToday(
      pending: pending,
      routineId: routine.id,
      day: now,
      finishedToday: done,
    )) {
      return _FeaturedBody(
        title: routine.nome,
        subtitle:
            '${pending!.completedSets}/${pending.totalSets} séries feitas. '
            'Continue de onde parou.',
        action: _primaryButton(
          key: const Key('botao_retomar_treino'),
          label: 'Retomar treino',
          onPressed: () => _startRoutine(routine.id),
        ),
      );
    }
    if (done != null) {
      return _FeaturedBody(
        key: const Key('texto_treino_concluido'),
        title: 'Treino de hoje concluído',
        subtitle: 'Você fez ${routine.nome}. Mandou bem!',
        action: OutlinedButton(
          key: const Key('botao_ver_treino_realizado'),
          onPressed: _openHistory,
          child: const Text('Ver treino realizado'),
        ),
      );
    }
    return _FeaturedBody(
      title: routine.nome,
      focus: routine.descricao,
      subtitle:
          '${routine.quantidadeExercicios} exercícios  •  '
          '${routine.duracaoMinutos} min previstos',
      action: _primaryButton(
        key: const Key('botao_iniciar_treino'),
        label: 'Iniciar treino',
        onPressed: () => _startRoutine(routine.id),
      ),
    );
  }

  static TreinoUi? _routineOf(AlunoTreinosUiData training, String? id) {
    if (id == null) return null;
    for (final routine in training.treinos) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  Widget _primaryButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) => FilledButton.icon(
    key: key,
    onPressed: _opening ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    icon: const Icon(Icons.play_arrow_rounded),
    label: Text(label),
  );

  Widget _teacherRow(UserModel student) {
    final teacher = _teacherOf(student);
    if (teacher == null) return const SizedBox.shrink();
    return FutureBuilder<UserModel?>(
      future: teacher,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            key: const Key('card_professor_responsavel'),
            children: [
              UserAvatar(
                photoUrl: data.photoUrl,
                backgroundColor: AppColors.avatarBackground,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEU PROFESSOR',
                      style: TextStyle(
                        color: AppColors.textBody,
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Só aparecem atalhos com destino; "Aulas" volta quando o aluno tiver a
  /// grade de aulas (GB-101).
  Widget _shortcuts(HomeWorkoutPlan? home) {
    final shortcuts = <Widget>[
      if (widget.onOpenProfile != null)
        _Shortcut(
          key: const Key('botao_atalho_saude'),
          icon: Icons.health_and_safety_outlined,
          label: 'Saúde',
          onPressed: widget.onOpenProfile!,
        ),
      if (home != null)
        _Shortcut(
          key: const Key('botao_atalho_treino_em_casa'),
          icon: Icons.home_outlined,
          label: 'Treinar em casa',
          onPressed: () => _openHome(home),
        ),
      if (widget.onOpenEvolution != null)
        _Shortcut(
          key: const Key('botao_atalho_avaliacao'),
          icon: Icons.monitor_weight_outlined,
          label: 'Avaliação',
          onPressed: widget.onOpenEvolution!,
        ),
    ];
    if (shortcuts.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 10, children: shortcuts);
  }

  Widget _streakCard(List<TrainingSession>? history, {required bool failed}) {
    final String value;
    final String message;
    if (failed) {
      value = '—';
      message = 'Não conseguimos calcular sua sequência agora.';
    } else if (history == null) {
      value = '…';
      message = 'Calculando sua sequência.';
    } else {
      final weeks = StudentWeeklyProgress.streakWeeks(history, _now);
      value = weeks == 1 ? '1 semana' : '$weeks semanas';
      message = switch (weeks) {
        0 => 'Treine esta semana e comece sua sequência!',
        1 => 'Bom começo! Que tal manter o ritmo?',
        _ => 'Você está on fire!',
      };
    }
    return _MetricCard(
      key: const Key('card_sequencia'),
      asset: 'assets/fogo2.png',
      value: value,
      valueKey: const Key('texto_sequencia'),
      message: message,
      chip: 'Sequência',
    );
  }

  // ── Evolução ──────────────────────────────────────────────────────────

  Widget _evolutionCard() => StreamBuilder<List<PhysicalEvaluation>>(
    stream: _evaluations,
    builder: (context, snapshot) {
      final String? value;
      final String message;
      if (snapshot.hasError) {
        debugPrint('Falha ao carregar as avaliações: ${snapshot.error}');
        value = null;
        message = 'Não conseguimos carregar suas avaliações agora.';
      } else if (!snapshot.hasData) {
        value = null;
        message = 'Carregando suas avaliações.';
      } else {
        final evaluations = snapshot.data!;
        final change = latestWeightChangeKg(evaluations);
        if (change != null) {
          value = _signedKg(change);
          message = 'no peso desde a avaliação anterior';
        } else if (evaluations.isNotEmpty) {
          value = _kg(evaluations.single.weightKg);
          message = 'na sua primeira avaliação. A próxima mostra sua evolução.';
        } else {
          value = null;
          message = 'Sua primeira avaliação física vai aparecer aqui.';
        }
      }
      return _MetricCard(
        key: const Key('card_evolucao'),
        asset: 'assets/progressao2.png',
        value: value,
        valueKey: const Key('texto_evolucao'),
        message: message,
        chip: 'Evolução',
      );
    },
  );

  static String _kg(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')} kg';

  static String _signedKg(double change) {
    final rounded = double.parse(change.toStringAsFixed(1));
    if (rounded == 0) return '0,0 kg';
    return '${rounded > 0 ? '+' : '-'}${_kg(rounded.abs())}';
  }

  // ── Próxima aula ──────────────────────────────────────────────────────

  Widget _nextClassCard(UserModel student) {
    final classes = _classesOf(student);
    if (classes == null) {
      return const _NextClassCard(
        message:
            'Quando sua unidade for definida, a próxima aula aparece '
            'aqui.',
      );
    }
    return StreamBuilder<List<GymClassModel>>(
      stream: classes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Falha ao carregar a grade de aulas: ${snapshot.error}');
          return const _NextClassCard(
            message: 'Não conseguimos carregar a grade de aulas agora.',
          );
        }
        if (!snapshot.hasData) {
          return const _NextClassCard(message: 'Carregando a grade de aulas.');
        }
        final now = _now;
        final next = nextGymClass(snapshot.data!, now);
        if (next == null) {
          return const _NextClassCard(
            message: 'Sua unidade ainda não tem aulas na grade.',
          );
        }
        return _NextClassCard(
          title: next.gymClass.name,
          message: _whenLabel(next.startsAt, now),
        );
      },
    );
  }

  static String _whenLabel(DateTime startsAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
    final hour =
        '${startsAt.hour.toString().padLeft(2, '0')}:'
        '${startsAt.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Hoje às $hour';
    if (day == DateTime(now.year, now.month, now.day + 1)) {
      return 'Amanhã às $hour';
    }
    return '${weekdayName(startsAt.weekday)} às $hour';
  }
}

// ── Componentes visuais ───────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool bottomOnly;
  final Color color;

  const _Card({
    super.key,
    required this.child,
    this.bottomOnly = false,
    this.color = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius:
          bottomOnly
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _CardLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CardLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        label.toUpperCase(),
        style: GoogleFonts.barlowCondensed(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: AppFontSize.small,
          letterSpacing: 0.6,
        ),
      ),
    ],
  );
}

class _FeaturedBody extends StatelessWidget {
  final String title;
  final String? focus;
  final String subtitle;
  final Widget? action;

  const _FeaturedBody({
    super.key,
    required this.title,
    this.focus,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title.toUpperCase(),
        style: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.title,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
          letterSpacing: 0.6,
        ),
      ),
      if (focus != null && focus!.trim().isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          focus!,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textBody,
          fontSize: AppFontSize.small,
        ),
      ),
      if (action != null) ...[const SizedBox(height: 15), action!],
    ],
  );
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _Shortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String asset;
  final String? value;
  final Key valueKey;
  final String message;
  final String chip;

  const _MetricCard({
    super.key,
    required this.asset,
    required this.value,
    required this.valueKey,
    required this.message,
    required this.chip,
  });

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 40,
                      maxHeight: 40,
                    ),
                    child: Image.asset(asset, fit: BoxFit.contain),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value!,
                        key: valueKey,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.barlowCondensed(
                          fontSize: AppFontSize.headline,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Chip(chip),
      ],
    ),
  );
}

class _NextClassCard extends StatelessWidget {
  final String? title;
  final String message;

  const _NextClassCard({this.title, required this.message});

  @override
  Widget build(BuildContext context) => _Card(
    key: const Key('card_proxima_aula'),
    color: AppColors.primary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 40,
                      maxHeight: 40,
                    ),
                    child: Image.asset(
                      'assets/calendario.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      title!.toUpperCase(),
                      key: const Key('texto_proxima_aula'),
                      style: GoogleFonts.barlowCondensed(
                        fontSize: AppFontSize.subtitle,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintBorderBright,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const _Chip(
              'Próxima aula',
              background: AppColors.primaryChipSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          message,
          key: const Key('texto_quando_proxima_aula'),
          style: const TextStyle(
            fontSize: AppFontSize.small,
            color: AppColors.mintBorderBright,
          ),
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;

  const _Chip(this.label, {this.background = AppColors.avatarBackground});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: GoogleFonts.barlowCondensed(
        fontSize: AppFontSize.caption,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 50, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.subtitle,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.small,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('botao_tentar_novamente'),
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    ),
  );
}
