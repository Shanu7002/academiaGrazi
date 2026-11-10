import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/view/user/aluno_treino_em_casa_view.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/user/aluno_historico_sessoes_view.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';
import 'package:academiagrazi/view/user/aluno_painel_semanal_view.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Entrada da aba de treinos com ficha publicada e sessao de execucao real.
class AlunoTreinosFirestoreView extends StatefulWidget {
  final String? studentId;
  final StudentTrainingViewDataService? service;
  final TrainingPlanService? planService;
  final TrainingSessionService? sessionService;

  const AlunoTreinosFirestoreView({
    super.key,
    this.studentId,
    this.service,
    this.planService,
    this.sessionService,
  });

  @override
  State<AlunoTreinosFirestoreView> createState() =>
      _AlunoTreinosFirestoreViewState();
}

class _AlunoTreinosFirestoreViewState extends State<AlunoTreinosFirestoreView> {
  late final String? _studentId;
  Stream<AlunoTreinosUiData?>? _trainingStream;
  Stream<List<TrainingSession>>? _historyStream;
  Future<TrainingSession?>? _pendingFuture;
  Stream<HomeWorkoutPlan?>? _homeStream;
  HomeWorkoutService? _homeServiceInstance;
  HomeWorkoutService get _homes => _homeServiceInstance ??= HomeWorkoutService();
  TrainingPlanService? _planServiceInstance;
  TrainingSessionService? _sessionServiceInstance;
  bool _opening = false;

  TrainingPlanService get _plans =>
      _planServiceInstance ??= widget.planService ?? TrainingPlanService();

  TrainingSessionService get _sessions =>
      _sessionServiceInstance ??=
          widget.sessionService ?? TrainingSessionService(planService: _plans);

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId ?? locator<FirebaseAuth>().currentUser?.uid;
    final id = _studentId;
    if (id != null &&
        id.isNotEmpty &&
        (widget.service != null || Firebase.apps.isNotEmpty)) {
      _trainingStream = (widget.service ?? StudentTrainingViewDataService(
        catalogService: ExerciseCatalogService(),
      )).watchActiveUiData(id);
      if (Firebase.apps.isNotEmpty) {
        _homeStream = _homes.watchCurrent(id);
      }
      if (widget.sessionService != null || Firebase.apps.isNotEmpty) {
        _historyStream = _sessions.watchHistory(id);
        _pendingFuture = _sessions.getInProgress(id);
      }
    }
  }

  void _refreshPending() {
    final id = _studentId;
    if (id == null || _historyStream == null || !mounted) return;
    setState(() => _pendingFuture = _sessions.getInProgress(id));
  }

  void _avisar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _iniciarTreino(String routineId) async {
    final studentId = _studentId;
    if (_opening || studentId == null || studentId.isEmpty) return;
    setState(() => _opening = true);
    try {
      final pending = await _sessions.getInProgress(studentId);
      final plan = await _plans.getActivePlan(studentId);
      if (pending?.routineId != routineId &&
          (plan == null || !plan.routines.any((item) => item.id == routineId))) {
        throw StateError('A ficha publicada não está mais disponível.');
      }
      if (!mounted) return;

      var planId = pending?.routineId == routineId ? pending!.planId : plan!.id;
      var selectedRoutine = routineId;
      String? existingSessionId = pending?.routineId == routineId ? pending!.id : null;

      if (pending != null &&
          (plan == null || pending.planId != plan.id || pending.routineId != routineId) &&
          pending.routineId != routineId) {
        final retomar = await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Você já tem um treino em andamento'),
                content: Text(
                  'O treino "${pending.routineName}" ainda não foi finalizado. '
                  'Deseja continuar de onde parou?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Agora não'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Continuar treino'),
                  ),
                ],
              ),
        );
        if (!mounted || retomar != true) return;
        planId = pending.planId;
        selectedRoutine = pending.routineId;
        existingSessionId = pending.id;
      }

      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => AlunoSessaoTreinoView(
                studentId: studentId,
                planId: planId,
                routineId: selectedRoutine,
                existingSessionId: existingSessionId,
                service: _sessions,
              ),
        ),
      );
    } catch (_) {
      _avisar('Não foi possível abrir o treino. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        _refreshPending();
      }
    }
  }

  Future<void> _iniciarHome(String routineId) async {
    final studentId = _studentId;
    if (_opening || studentId == null || studentId.isEmpty) return;
    setState(() => _opening = true);
    try {
      final home = await _homes.getCurrent(studentId);
      if (home == null || !home.routines.any((r) => r.id == routineId)) {
        throw StateError('Treino em casa indisponível.');
      }
      final pending = await _sessions.getInProgress(studentId);
      var planId = 'home';
      var selectedRoutine = routineId;
      String? sessionId;
      if (pending != null) {
        if (pending.planId == 'home' && pending.routineId == routineId) {
          sessionId = pending.id;
        } else {
          if (!mounted) return;
          final resume = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Já existe um treino em andamento'),
            content: Text('Deseja retomar "${pending.routineName}" antes de iniciar outro?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Agora não')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retomar')),
            ],
          ));
          if (resume != true || !mounted) return;
          planId = pending.planId;
          selectedRoutine = pending.routineId;
          sessionId = pending.id;
        }
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AlunoSessaoTreinoView(studentId: studentId,
          planId: planId, routineId: selectedRoutine,
          existingSessionId: sessionId, service: _sessions),
      ));
    } catch (_) {
      _avisar('Não foi possível abrir o treino em casa. Confira a conexão.');
    } finally {
      if (mounted) { setState(() => _opening = false); _refreshPending(); }
    }
  }

  void _abrirHome(HomeWorkoutPlan plan) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AlunoTreinoEmCasaView(plan: plan,
        onStart: _iniciarHome, onHistory: _abrirHistorico),
    ));
  }

  void _abrirHistorico() {
    final id = _studentId;
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AlunoHistoricoSessoesView(studentId: id, service: _sessions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_trainingStream == null) {
      final id = _studentId;
      final withoutSession = id == null || id.isEmpty;
      return _estado(
        icon: withoutSession ? Icons.lock_outline : Icons.cloud_off_outlined,
        title: withoutSession ? 'Entre na sua conta' : 'Serviço indisponível',
        message:
            withoutSession
                ? 'Faça login para consultar sua ficha de treinos.'
                : 'O Firebase ainda não foi inicializado.',
      );
    }

    if (_homeStream == null) return _buildTraining(null);
    return StreamBuilder<HomeWorkoutPlan?>(
      stream: _homeStream,
      builder: (context, homeSnapshot) => _buildTraining(homeSnapshot.data),
    );
  }

  Widget _buildTraining(HomeWorkoutPlan? homeWorkout) => StreamBuilder<AlunoTreinosUiData?>(
      stream: _trainingStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _estado(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar os treinos',
            message:
                'Verifique a conexão e as permissões da sua ficha no Firebase.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _estado(
            icon: Icons.fitness_center,
            title: 'Carregando sua ficha',
            message: 'Consultando os treinos publicados pelo seu professor.',
            loading: true,
          );
        }
        final training = snapshot.data;
        if (training == null) {
          if (homeWorkout != null && homeWorkout.routines.isNotEmpty) {
            return AlunoTreinoEmCasaView(plan: homeWorkout,
              onStart: _iniciarHome, onHistory: _abrirHistorico);
          }
          return _estado(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma ficha publicada',
            message: 'Seu professor ainda não atribuiu uma ficha para você.',
          );
        }
        final history = _historyStream;
        if (history == null) {
          return _painel(training, const [], null, homeWorkout);
        }
        return StreamBuilder<List<TrainingSession>>(
          stream: history,
          builder: (context, finishedSnapshot) {
            // Uma falha temporaria no historico nao impede a leitura da ficha.
            final finished = finishedSnapshot.data ?? const <TrainingSession>[];
            return FutureBuilder<TrainingSession?>(
              future: _pendingFuture,
              builder: (context, pendingSnapshot) => _painel(
                training, finished, pendingSnapshot.data, homeWorkout,
              ),
            );
          },
        );
      },
    );

  Widget _painel(
    AlunoTreinosUiData data,
    List<TrainingSession> finished,
    TrainingSession? pending,
    HomeWorkoutPlan? homeWorkout,
  ) => AlunoPainelSemanalView(
    data: data,
    historico: finished,
    emAndamento: pending,
    onIniciarTreino: _iniciarTreino,
    onHistorico: _abrirHistorico,
    abrindoTreino: _opening,
    homeWorkout: homeWorkout,
    onOpenHome: homeWorkout == null ? null : () => _abrirHome(homeWorkout),
  );

  Widget _estado({
    required IconData icon,
    required String title,
    required String message,
    bool loading = false,
  }) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      backgroundColor: AppColors.trainingListBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator()
                else
                  Icon(icon, size: 50, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
