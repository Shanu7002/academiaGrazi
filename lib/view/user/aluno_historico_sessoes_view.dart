import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Historico REAL. Preserva versoes antigas da ficha e informa quando a
/// conclusao foi parcial. O professor consulta os mesmos documentos.
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

  String _date(DateTime date) {
    final at = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} às ${two(at.hour)}:${two(at.minute)}';
  }

  String _duration(TrainingSession session) {
    final end = session.finishedAt;
    if (end == null) return '—';
    final minutes = end.difference(session.startedAt).inMinutes;
    return minutes < 0 ? '—' : '$minutes min';
  }

  String _load(double? value) {
    if (value == null) return 'Sem carga';
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$formatted kg';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.trainingListBackground,
    appBar: AppBar(
      title: Text('MEU HISTÓRICO', style: GoogleFonts.barlowCondensed(
        fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
    ),
    body: StreamBuilder<List<TrainingSession>>(
      stream: _history,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Não foi possível carregar seu histórico.',
                textAlign: TextAlign.center),
            TextButton(onPressed: () => setState(() =>
                _history = _service.watchHistory(widget.studentId)),
                child: const Text('Tentar novamente')),
          ]),
        ));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sessions = snapshot.data!;
        if (sessions.isEmpty) return const Center(child: Padding(
          padding: EdgeInsets.all(28),
          child: Text('Nenhum treino finalizado ainda. Quando você finalizar uma '
              'sessão, ela aparecerá aqui e também para o seu professor.',
              textAlign: TextAlign.center),
        ));
        return Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Text('TREINOS REALIZADOS',
                style: GoogleFonts.barlowCondensed(fontWeight: FontWeight.w800,
                  fontSize: 28, color: AppColors.textPrimary)),
              const SizedBox(height: 5),
              Text('${sessions.length} sessão(ões) finalizada(s) no total',
                style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              for (final session in sessions) _sessionCard(session),
            ],
          ),
        ));
      },
    ),
  );

  Widget _sessionCard(TrainingSession session) {
    final full = session.totalSets > 0 &&
        session.completedSets == session.totalSets;
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border)),
      child: ExpansionTile(
        key: Key('aluno_historico_${session.id}'),
        shape: const Border(), collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: full ? AppColors.successSurface : AppColors.accentSurface,
          child: Icon(full ? Icons.check_circle : Icons.timelapse,
            color: full ? AppColors.success : AppColors.accentDark),
        ),
        title: Text(session.planId == 'home'
            ? '${session.routineName} · Em casa' : session.routineName,
          style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_date(session.finishedAt ?? session.startedAt),
            style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('${session.completedSets}/${session.totalSets} séries  •  ${_duration(session)}  •  ${full ? 'Completo' : 'Parcial'}',
            style: TextStyle(fontSize: 12,
              color: full ? AppColors.success : AppColors.accentDark)),
        ]),
        children: [
          for (final exercise in session.exercises)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StudentExercisePhoto(url: exercise.imageUrl, size: 54),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${exercise.sets.where((s) => s.completed).length} de ${exercise.sets.length} séries concluídas',
                      style: const TextStyle(color: AppColors.textSecondary,
                        fontSize: 12)),
                    const SizedBox(height: 4),
                    for (final set in exercise.sets)
                      Text('Série ${set.number}: ${set.completed ? 'Feita' : 'Não feita'} · ${_load(set.loadKg)}',
                        style: const TextStyle(color: AppColors.textBody,
                          fontSize: 12)),
                  ],
                )),
              ]),
            ),
        ],
      ),
    );
  }
}
