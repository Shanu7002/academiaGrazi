import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Leitura das sessoes FINALIZADAS do aluno vinculado ao professor.
///
/// Nao acessa dados de outros alunos e nao altera sessao alguma. A verificacao
/// de autorizacao e feita no Firestore, em trainingSessions (allow get/list).
class ProfessorHistoricoAlunoView extends StatefulWidget {
  final String studentId;
  final String studentName;
  final TrainingSessionService? service;

  const ProfessorHistoricoAlunoView({
    super.key,
    required this.studentId,
    required this.studentName,
    this.service,
  });

  @override
  State<ProfessorHistoricoAlunoView> createState() =>
      _ProfessorHistoricoAlunoViewState();
}

class _ProfessorHistoricoAlunoViewState
    extends State<ProfessorHistoricoAlunoView> {
  late TrainingSessionService _service;
  late Stream<List<TrainingSession>> _history;

  @override
  void initState() {
    super.initState();
    _resetStream();
  }

  @override
  void didUpdateWidget(covariant ProfessorHistoricoAlunoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId ||
        oldWidget.service != widget.service) {
      _resetStream();
    }
  }

  void _resetStream() {
    _service = widget.service ?? TrainingSessionService();
    _history = _service.watchHistory(widget.studentId);
  }

  void _retry() => setState(_resetStream);

  static String _date(DateTime date) {
    final at = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} '
        '${two(at.hour)}:${two(at.minute)}';
  }

  static String _duration(TrainingSession session) {
    final end = session.finishedAt;
    if (end == null) return '—';
    final minutes = end.difference(session.startedAt).inMinutes;
    if (minutes < 0) return '—';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}min';
  }

  static String _loadLabel(TrainingSetResult set) {
    if (set.loadKg == null) return 'Sem carga registrada';
    final value = set.loadKg!;
    final text =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$text kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhamento de treinos'),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
      ),
      backgroundColor: AppColors.trainingListBackground,
      body: StreamBuilder<List<TrainingSession>>(
        stream: _history,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Não foi possível consultar os treinos deste aluno. '
              'Verifique a conexão ou as permissões.',
              action: TextButton(
                key: const Key('professor_tentar_novamente_historico'),
                onPressed: _retry,
                child: const Text('Tentar novamente'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return _message(
              '${widget.studentName} ainda não finalizou nenhum treino. '
              'As execuções concluídas aparecerão aqui.',
            );
          }
          return _content(sessions);
        },
      ),
    );
  }

  Widget _message(String message, {Widget? action}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fitness_center_outlined,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(List<TrainingSession> sessions) {
    // O service ordena por termino, do mais recente para o mais antigo.
    final totalSets = sessions.fold<int>(
      0,
      (total, session) => total + session.completedSets,
    );
    final validDurations =
        sessions
            .where(
              (session) =>
                  session.finishedAt != null &&
                  !session.finishedAt!.isBefore(session.startedAt),
            )
            .map(
              (session) =>
                  session.finishedAt!.difference(session.startedAt).inMinutes,
            )
            .toList();
    final averageMinutes =
        validDurations.isEmpty
            ? null
            : validDurations.reduce((a, b) => a + b) ~/ validDurations.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              widget.studentName,
              key: const Key('professor_nome_aluno_historico'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Histórico de execuções finalizadas'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric('Treinos concluídos', '${sessions.length}'),
                _metric('Séries concluídas', '$totalSets'),
                _metric(
                  'Duração média',
                  averageMinutes == null ? '—' : '$averageMinutes min',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Sessões registradas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final session in sessions) _sessionCard(session),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(TrainingSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ExpansionTile(
        key: Key('professor_sessao_${session.id}'),
        title: Text(
          session.routineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_date(session.finishedAt ?? session.startedAt)} · '
          '${session.completedSets}/${session.totalSets} séries · '
          '${_duration(session)}',
        ),
        children: [
          for (final exercise in session.exercises)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  for (final set in exercise.sets)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            set.completed
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color:
                                set.completed
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Série ${set.number}: ${_loadLabel(set)}'
                              '${set.completed ? '' : ' · não concluída'}',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
