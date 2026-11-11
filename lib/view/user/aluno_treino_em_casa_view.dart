import 'package:academiagrazi/models/training/home_workout_plan.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Aparece somente quando o professor publicou treinos opcionais em casa.
class AlunoTreinoEmCasaView extends StatefulWidget {
  final HomeWorkoutPlan plan;
  final ValueChanged<String> onStart;
  final VoidCallback onHistory;

  const AlunoTreinoEmCasaView({super.key, required this.plan,
    required this.onStart, required this.onHistory});

  @override
  State<AlunoTreinoEmCasaView> createState() => _AlunoTreinoEmCasaViewState();
}

class _AlunoTreinoEmCasaViewState extends State<AlunoTreinoEmCasaView> {
  Map<String, ExerciseCatalogEntry> _catalog = const {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final entries = await ExerciseCatalogService().findByIds(
        widget.plan.routines.expand((r) => r.exercises)
            .map((exercise) => exercise.catalogExerciseId)
            .where((id) => id.startsWith('repdb-')),
      );
      if (mounted) setState(() => _catalog = entries);
    } catch (_) {
      // Permite consultar a prescricao salva mesmo se o catalogo estiver offline.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.trainingListBackground,
    appBar: AppBar(title: const Text('TREINAR EM CASA'),
      backgroundColor: Colors.white, foregroundColor: AppColors.primary),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        const Text('Sua ficha para treinar em casa', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 7),
        const Text('Exercícios prescritos pelo seu professor. '
          'Você pode realizá-los nos dias adequados à sua rotina.'),
        const SizedBox(height: 16),
        for (final routine in widget.plan.routines) Card(
          color: Colors.white, child: Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(routine.name, style: const TextStyle(fontSize: 19,
              fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('${routine.exercises.length} exercícios • ${routine.estimatedMinutes} min previstos'),
            if (routine.focus.trim().isNotEmpty) Text('Foco: ${routine.focus}'),
            if (routine.warmupInstructions.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('AQUECIMENTO', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(routine.warmupInstructions),
            ],
            const SizedBox(height: 10),
            for (var i = 0; i < routine.exercises.length; i++) ...[
              const Divider(),
              Builder(builder: (context) {
                final exercise = routine.exercises[i];
                final catalog = _catalog[exercise.catalogExerciseId];
                final guidance = StudentExercisePresentation.guidance(exercise.instructions, catalog);
                final image = StudentExercisePresentation.image(exercise.imageUrl, catalog);
                final label = StudentExercisePresentation.name(exercise.name, catalog);
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StudentExercisePhoto(url: image, size: 74),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}. $label', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${exercise.sets} séries × ${exercise.repetitions} rep. • ${exercise.restSeconds}s descanso',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (guidance.text != null && guidance.text!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(guidance.text!, style: const TextStyle(fontSize: 13)),
                    ],
                  ])),
                ]);
              }),
            ],
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              key: Key('iniciar_casa_${routine.id}'),
              onPressed: () => widget.onStart(routine.id),
              icon: const Icon(Icons.play_arrow), label: Text('Iniciar ${routine.name}'))),
          ]))),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: widget.onHistory,
          icon: const Icon(Icons.history), label: const Text('Ver histórico de treinos')),
      ]))),
  );
}
