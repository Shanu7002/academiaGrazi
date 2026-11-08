import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/service/training/student_training_view_data_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/user/aluno_historico_sessoes_view.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';
import 'package:academiagrazi/view/user/aluno_treinos_view.dart';
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
      _trainingStream = (widget.service ?? StudentTrainingViewDataService())
          .watchActiveUiData(id);
    }
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
      final plan = await _plans.getActivePlan(studentId);
      if (plan == null || !plan.routines.any((item) => item.id == routineId)) {
        throw StateError('A ficha publicada não está mais disponível.');
      }
      final pending = await _sessions.getInProgress(studentId);
      if (!mounted) return;

      var planId = plan.id;
      var selectedRoutine = routineId;
      String? existingSessionId;

      if (pending != null &&
          (pending.planId != plan.id || pending.routineId != routineId)) {
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
      if (mounted) setState(() => _opening = false);
    }
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

    return StreamBuilder<AlunoTreinosUiData?>(
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
          return _estado(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma ficha publicada',
            message: 'Seu professor ainda não atribuiu uma ficha para você.',
          );
        }
        return AlunoTreinosView(
          data: training,
          onIniciarTreino: _iniciarTreino,
          onHistorico: _abrirHistorico,
        );
      },
    );
  }

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
