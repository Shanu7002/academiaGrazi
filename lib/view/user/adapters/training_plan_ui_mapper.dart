import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_exercicio_detalhe_ui_data.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treino_dia_ui_data.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';

/// Adapta uma ficha publicada para os modelos das telas existentes do aluno.
///
/// Nao inventa historico: a conclusao so sera marcada quando o servico de
/// sessoes reais for adicionado na proxima etapa.
class TrainingPlanUiMapper {
  static AlunoTreinosUiData fromPlan(
    TrainingPlan plan, {
    required String studentName,
    required String instructorName,
    DateTime? now,
  }) {
    if (plan.status != TrainingPlanStatus.published) {
      throw StateError('A tela do aluno so pode receber ficha publicada.');
    }
    final today = now ?? DateTime.now();
    final routineToday = plan.weeklySchedule[today.weekday];
    final routineViews = <TreinoUi>[];
    final routineDetails = <String, AlunoTreinoDiaUiData>{};

    for (final routine in plan.routines) {
      final items = routine.exercises
          .map(_toExerciseUi)
          .toList(growable: false);
      final isToday = routine.id == routineToday;
      final data = TreinoUi(
        id: routine.id,
        letra: routine.letter,
        nome: routine.name,
        descricao: routine.focus,
        duracaoMinutos: routine.estimatedMinutes,
        quantidadeExercicios: routine.exercises.length,
        nivel: 'Personalizado',
        estrategia: 'Orientacao do professor',
        principaisExercicios: routine.exercises.map((e) => e.name).join(', '),
        seriesResumo: _seriesResumo(routine.exercises),
        status:
            isToday ? TreinoStatusUi.recomendado : TreinoStatusUi.programado,
        statusTexto:
            isToday ? 'RECOMENDADO PARA HOJE' : 'DISPONIVEL NA SUA FICHA',
        exercicios: items,
      );
      routineViews.add(data);

      final itemDetails = <String, AlunoExercicioDetalheUiData>{};
      for (var index = 0; index < routine.exercises.length; index++) {
        final exercise = routine.exercises[index];
        itemDetails[exercise.id] = AlunoExercicioDetalheUiData(
          exercicio: items[index],
          descanso: '${exercise.restSeconds}s',
          orientacoes: exercise.instructions,
          // O player da tela antiga continua demonstrativo neste momento.
          tempoVideo: '--',
        );
      }
      routineDetails[routine.id] = AlunoTreinoDiaUiData(
        treino: data,
        professorNome: instructorName,
        aquecimentoNome: 'Aquecimento',
        aquecimentoResumo: 'Conforme orientacao do professor',
        exercicioDetalhePorId: itemDetails,
      );
    }

    final activeDays =
        plan.weeklySchedule.values
            .where((routineId) => routineId != null && routineId.isNotEmpty)
            .length;
    final averageMinutes =
        plan.routines.isEmpty
            ? 0
            : (plan.routines.fold<int>(
                      0,
                      (sum, routine) => sum + routine.estimatedMinutes,
                    ) /
                    plan.routines.length)
                .round();

    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return AlunoTreinosUiData(
      alunoNome: studentName,
      semana: '${_dayMonth(monday)} a ${_dayMonth(sunday)}',
      professorNome: instructorName,
      ultimaAtualizacao: 'Versao ${plan.version}',
      cicloNome: plan.name,
      frequencia: '${activeDays}x',
      frequenciaLegenda: 'por semana',
      duracaoMedia: '$averageMinutes min',
      duracaoLegenda: 'media por treino',
      validade: 'Ate nova ficha',
      validadeLegenda: 'Sem vencimento cadastrado',
      treinos: routineViews,
      complementares: const <TreinoComplementarUi>[],
      treinoDiaPorId: routineDetails,
    );
  }

  static ExercicioTreinoUi _toExerciseUi(TrainingExercise exercise) =>
      ExercicioTreinoUi(
        id: exercise.id,
        nome: exercise.name,
        series: '${exercise.sets}x${exercise.repetitions}',
        carga:
            exercise.targetLoadKg == null
                ? 'A definir'
                : '${_formatLoad(exercise.targetLoadKg!)} kg',
      );

  static String _seriesResumo(List<TrainingExercise> exercises) {
    if (exercises.isEmpty) return 'Sem exercicios';
    final uniqueSets = exercises.map((exercise) => exercise.sets).toSet();
    return uniqueSets.length == 1
        ? '${uniqueSets.single} series'
        : 'Series personalizadas';
  }

  static String _formatLoad(double kg) =>
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

  static String _dayMonth(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
