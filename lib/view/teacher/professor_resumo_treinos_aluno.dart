import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/student_weekly_progress.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Indicadores do aluno atualizados quando uma sessao finalizada e salva.
/// Nao duplica estados de presenca em documentos separados do Firestore.
class ProfessorResumoTreinosAluno extends StatefulWidget {
  final String studentId;
  final TrainingSessionService service;
  final VoidCallback onHistorico;

  const ProfessorResumoTreinosAluno({
    super.key,
    required this.studentId,
    required this.service,
    required this.onHistorico,
  });

  @override
  State<ProfessorResumoTreinosAluno> createState() =>
      _ProfessorResumoTreinosAlunoState();
}

class _ProfessorResumoTreinosAlunoState
    extends State<ProfessorResumoTreinosAluno> {
  late Stream<List<TrainingSession>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.service.watchHistory(widget.studentId);
  }

  @override
  void didUpdateWidget(covariant ProfessorResumoTreinosAluno oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId ||
        oldWidget.service != widget.service) {
      _history = widget.service.watchHistory(widget.studentId);
    }
  }

  String _format(DateTime time) {
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} às ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: StreamBuilder<List<TrainingSession>>(
      stream: _history,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <TrainingSession>[];
        final thisWeek = StudentWeeklyProgress.inWeek(sessions, DateTime.now());
        final last = sessions.isEmpty ? null : sessions.first;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.insights_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Acompanhamento de treinos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: AppFontSize.body,
                  color: AppColors.textPrimary))),
            if (snapshot.hasData)
              const Icon(Icons.circle, size: 8, color: AppColors.success),
          ]),
          const SizedBox(height: 10),
          if (snapshot.hasError)
            const Text('Histórico indisponível no momento.',
              style: TextStyle(color: AppColors.textSecondary))
          else if (!snapshot.hasData)
            const LinearProgressIndicator()
          else ...[
            Text('${thisWeek.length} treino(s) concluído(s) nesta semana',
              key: const Key('professor_status_treinos_semana'),
              style: const TextStyle(fontWeight: FontWeight.w700,
                color: AppColors.primary)),
            const SizedBox(height: 5),
            Text(last == null
                ? 'Nenhuma sessão finalizada registrada.'
                : 'Último: ${last.routineName} · ${_format(last.finishedAt ?? last.startedAt)} '
                  '· ${last.completedSets}/${last.totalSets} séries',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            key: const Key('professor_acompanhar_treinos'),
            onPressed: widget.onHistorico,
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Ver histórico e cargas do aluno'),
          )),
        ]);
      },
    ),
  );
}
