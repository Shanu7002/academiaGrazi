import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Historico real de execucoes, separado das fichas prescritas.
class AlunoHistoricoSessoesView extends StatefulWidget {
  final String studentId;
  final TrainingSessionService? service;

  const AlunoHistoricoSessoesView({
    super.key,
    required this.studentId,
    this.service,
  });

  @override
  State<AlunoHistoricoSessoesView> createState() =>
      _AlunoHistoricoSessoesViewState();
}

class _AlunoHistoricoSessoesViewState extends State<AlunoHistoricoSessoesView> {
  late final TrainingSessionService _service;
  late Stream<List<TrainingSession>> _history;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrainingSessionService();
    _history = _service.watchHistory(widget.studentId);
  }

  String _date(DateTime at) {
    final local = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de treinos'),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
      ),
      backgroundColor: AppColors.trainingListBackground,
      body: StreamBuilder<List<TrainingSession>>(
        stream: _history,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar seu histórico.'),
                  TextButton(
                    onPressed:
                        () => setState(
                          () =>
                              _history = _service.watchHistory(
                                widget.studentId,
                              ),
                        ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não finalizou nenhum treino. '
                  'Quando finalizar, ele aparecerá aqui.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(session.routineName),
                      subtitle: Text(
                        '${session.finishedAt == null ? "" : _date(session.finishedAt!)} · '
                        '${session.completedSets}/${session.totalSets} séries',
                      ),
                      children: [
                        for (final exercise in session.exercises)
                          ListTile(
                            title: Text(exercise.name),
                            subtitle: Text(
                              '${exercise.sets.where((s) => s.completed).length} '
                              'de ${exercise.sets.length} séries concluídas',
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
