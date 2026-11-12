import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/view/user/aluno_historico_sessoes_view.dart';
import 'package:academiagrazi/view/user/aluno_sessao_treino_view.dart';
import 'package:academiagrazi/view/user/aluno_treino_em_casa_view.dart';
import 'package:flutter/material.dart';

/// Abre a execução do treino do aluno (ficha presencial ou treino em casa),
/// retomando a sessão em andamento quando houver.
///
/// Compartilhado pela aba Treinos e pela home do aluno, para que as duas
/// entradas sigam o mesmo fluxo. As falhas viram aviso em pt-BR.
class StudentWorkoutLauncher {
  final TrainingPlanService _plans;
  final TrainingSessionService _sessions;
  final HomeWorkoutService _homes;

  StudentWorkoutLauncher({
    required TrainingPlanService plans,
    required TrainingSessionService sessions,
    required HomeWorkoutService homes,
  }) : _plans = plans,
       _sessions = sessions,
       _homes = homes;

  /// Inicia (ou retoma) a rotina [routineId] da ficha publicada.
  Future<void> startRoutine(
    BuildContext context, {
    required String studentId,
    required String routineId,
  }) async {
    try {
      final pending = await _sessions.getInProgress(studentId);
      final plan = await _plans.getActivePlan(studentId);
      if (pending?.routineId != routineId &&
          (plan == null ||
              !plan.routines.any((item) => item.id == routineId))) {
        throw StateError('A ficha publicada não está mais disponível.');
      }
      if (!context.mounted) return;

      var planId = pending?.routineId == routineId ? pending!.planId : plan!.id;
      var selectedRoutine = routineId;
      String? existingSessionId =
          pending?.routineId == routineId ? pending!.id : null;

      if (pending != null && pending.routineId != routineId) {
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
        if (!context.mounted || retomar != true) return;
        planId = pending.planId;
        selectedRoutine = pending.routineId;
        existingSessionId = pending.id;
      }

      if (!context.mounted) return;
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
    } catch (error) {
      debugPrint('Falha ao abrir o treino: $error');
      if (!context.mounted) return;
      _warn(context, 'Não conseguimos abrir o treino agora. Tente novamente.');
    }
  }

  /// Inicia (ou retoma) a rotina [routineId] do treino em casa.
  Future<void> startHomeRoutine(
    BuildContext context, {
    required String studentId,
    required String routineId,
  }) async {
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
          if (!context.mounted) return;
          final resume = await showDialog<bool>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Já existe um treino em andamento'),
                  content: Text(
                    'Deseja retomar "${pending.routineName}" antes de '
                    'iniciar outro?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Agora não'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Retomar'),
                    ),
                  ],
                ),
          );
          if (resume != true || !context.mounted) return;
          planId = pending.planId;
          selectedRoutine = pending.routineId;
          sessionId = pending.id;
        }
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder:
              (_) => AlunoSessaoTreinoView(
                studentId: studentId,
                planId: planId,
                routineId: selectedRoutine,
                existingSessionId: sessionId,
                service: _sessions,
              ),
        ),
      );
    } catch (error) {
      debugPrint('Falha ao abrir o treino em casa: $error');
      if (!context.mounted) return;
      _warn(
        context,
        'Não conseguimos abrir o treino em casa agora. Confira a conexão.',
      );
    }
  }

  /// Abre a lista de treinos em casa; [onStart] inicia a rotina escolhida.
  void openHome(
    BuildContext context, {
    required String studentId,
    required HomeWorkoutPlan plan,
    required ValueChanged<String> onStart,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => AlunoTreinoEmCasaView(
              plan: plan,
              onStart: onStart,
              onHistory: () => openHistory(context, studentId: studentId),
            ),
      ),
    );
  }

  /// Abre o histórico de treinos finalizados.
  void openHistory(BuildContext context, {required String studentId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => AlunoHistoricoSessoesView(
              studentId: studentId,
              service: _sessions,
            ),
      ),
    );
  }

  static void _warn(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
