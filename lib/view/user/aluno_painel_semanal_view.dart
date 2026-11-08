import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/student_weekly_progress.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/user/aluno_ficha_rotina_view.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';
import 'package:academiagrazi/view/user/ui_models/treino_ui_models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nova tela real de treinos. Exibe a programacao publicada pelo professor e
/// sessoes finalizadas; nao usa estados demonstrativos nem grava concluido local.
class AlunoPainelSemanalView extends StatelessWidget {
  final AlunoTreinosUiData data;
  final List<TrainingSession> historico;
  final TrainingSession? emAndamento;
  final ValueChanged<String> onIniciarTreino;
  final VoidCallback onHistorico;
  final bool abrindoTreino;
  final DateTime? agora;

  const AlunoPainelSemanalView({
    super.key,
    required this.data,
    required this.historico,
    required this.emAndamento,
    required this.onIniciarTreino,
    required this.onHistorico,
    this.abrindoTreino = false,
    this.agora,
  });

  static const _dias = <String>[
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
  ];

  DateTime get _hoje => agora ?? DateTime.now();

  TreinoUi? _treinoPorId(String? id) {
    if (id == null) return null;
    for (final treino in data.treinos) {
      if (treino.id == id) return treino;
    }
    return null;
  }

  /// Uma sessao antiga nao e um treino em andamento *de hoje*.
  /// O descanso e a programacao semanal sempre prevalecem no painel.
  bool _sessaoAbertaHoje(
    TreinoUi? treinoDoDia,
    DateTime dia,
    TrainingSession? finalizadoHoje,
  ) {
    final pendente = emAndamento;
    if (treinoDoDia == null ||
        pendente == null ||
        pendente.status != TrainingSessionStatus.inProgress ||
        pendente.routineId != treinoDoDia.id ||
        !StudentWeeklyProgress.sameDay(pendente.startedAt.toLocal(), dia)) {
      return false;
    }
    // Se uma sessao desse treino ja foi finalizada depois da pendencia,
    // nao volte a anunciar a tentativa antiga como treino em andamento.
    final fim = finalizadoHoje?.finishedAt;
    return fim == null || fim.isBefore(pendente.startedAt);
  }

  bool _podeIniciarHoje(TreinoUi treino) {
    final dia = _hoje;
    if (data.programacaoSemanal[dia.weekday] != treino.id) return false;
    final finalizado = StudentWeeklyProgress.completedRoutineOnDay(
      historico, dia, treino.id,
    );
    // Ao concluir o treino do dia, a ficha segue para consulta, sem
    // oferecer outro inicio. Uma nova sessao ja iniciada pode ser retomada.
    return finalizado == null || _sessaoAbertaHoje(treino, dia, finalizado);
  }

  void _abrirFicha(BuildContext context, TreinoUi treino) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlunoFichaRotinaView(
          treino: treino,
          professorNome: data.professorNome,
          podeIniciar: _podeIniciarHoje(treino),
          onIniciar: () {
            Navigator.of(context).pop();
            onIniciarTreino(treino.id);
          },
        ),
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: padding,
        child: child,
      );

  Widget _chip(String label, {Color? foreground, Color? background}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background ?? AppColors.primaryActionSurface,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: foreground ?? AppColors.primary,
    )),
  );

  TextStyle get _sectionStyle => GoogleFonts.barlowCondensed(
    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final today = _hoje;
    final start = StudentWeeklyProgress.monday(today);
    final thisWeek = StudentWeeklyProgress.inWeek(historico, today);
    final todayId = data.programacaoSemanal[today.weekday];
    final todayRoutine = _treinoPorId(todayId);
    final finishedToday = StudentWeeklyProgress.onDay(historico, today);
    final completedToday = StudentWeeklyProgress.completedRoutineOnDay(
      finishedToday, today, todayRoutine?.id,
    );
    final activeToday = _sessaoAbertaHoje(todayRoutine, today, completedToday);
    final ordered = [...data.treinos]..sort((a, b) => a.letra.compareTo(b.letra));

    return Scaffold(
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      backgroundColor: AppColors.trainingListBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              key: const Key('aluno_painel_semanal'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
              children: [
                Text('SEUS TREINOS', style: GoogleFonts.barlowCondensed(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text('Ficha de ${data.professorNome}  •  ${data.ultimaAtualizacao}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 20),
                _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('SUA SEMANA', style: _sectionStyle)),
                    _chip(data.semana, foreground: AppColors.primary),
                  ]),
                  const SizedBox(height: 6),
                  Text('${thisWeek.length} treino(s) registrado(s) nesta semana',
                    key: const Key('aluno_total_treinos_semana'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 13),
                  for (var i = 0; i < 7; i++)
                    _dia(context, start.add(Duration(days: i)), today),
                ])),
                const SizedBox(height: 18),
                _panel(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        todayRoutine == null ? 'HOJE É DIA DE DESCANSO'
                            : activeToday ? 'TREINO EM ANDAMENTO'
                            : completedToday != null ? 'TREINO DE HOJE CONCLUÍDO'
                            : 'TREINO DE HOJE',
                        style: _sectionStyle,
                      )),
                      Icon(todayRoutine == null ? Icons.spa_outlined
                          : activeToday ? Icons.play_circle
                          : completedToday != null ? Icons.check_circle_outline
                          : Icons.today_outlined,
                        color: AppColors.primary),
                    ]),
                    const SizedBox(height: 8),
                    if (todayRoutine == null) ...[
                      const Text('Hoje é seu dia de descanso! 🌿',
                        key: Key('aluno_dia_descanso'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                      const SizedBox(height: 5),
                      const Text('Sem treino programado para hoje. Aproveite para se recuperar.',
                        style: TextStyle(color: AppColors.textSecondary)),
                      if (finishedToday.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        _chip('Treino registrado hoje',
                          background: AppColors.successSurface,
                          foreground: AppColors.success),
                      ],
                    ] else if (activeToday) ...[
                      Text(emAndamento!.routineName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                      const SizedBox(height: 6),
                      Text('${emAndamento!.completedSets}/${emAndamento!.totalSets} séries feitas. Continue de onde parou.',
                        style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        key: const Key('aluno_retomar_treino'),
                        onPressed: abrindoTreino ? null : () => onIniciarTreino(emAndamento!.routineId),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Retomar treino'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      )),
                    ] else if (completedToday != null) ...[
                      Text(todayRoutine.nome,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                      const SizedBox(height: 6),
                      Text('Você concluiu ${completedToday.completedSets} de ${completedToday.totalSets} séries e o registro está no seu histórico.',
                        key: const Key('aluno_treino_concluido_hoje'),
                        style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: onHistorico,
                        icon: const Icon(Icons.history),
                        label: const Text('Ver treino realizado'),
                      )),
                    ] else ...[
                      Text(todayRoutine.nome,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                      const SizedBox(height: 5),
                      Text('${todayRoutine.quantidadeExercicios} exercícios  •  ${todayRoutine.duracaoMinutos} min previstos',
                        style: const TextStyle(color: AppColors.textSecondary)),
                      if (emAndamento != null) ...[
                        const SizedBox(height: 7),
                        const Text('Existe uma sessão anterior não finalizada. Ao iniciar, você poderá retomá-la.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: OutlinedButton(
                          key: const Key('aluno_ver_treino_hoje'),
                          onPressed: () => _abrirFicha(context, todayRoutine),
                          child: const Text('Ver exercícios'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: FilledButton(
                          key: const Key('aluno_iniciar_treino_hoje'),
                          onPressed: abrindoTreino ? null : () => onIniciarTreino(todayRoutine.id),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                          child: const Text('Iniciar treino'),
                        )),
                      ]),
                    ],
                  ],
                )),
                const SizedBox(height: 21),
                Text('SUA FICHA COMPLETA', style: _sectionStyle),
                if (todayRoutine == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 9),
                    child: Text('Apenas para consulta. Hoje não há treino a iniciar.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                const SizedBox(height: 10),
                for (final treino in ordered) ...[
                  _rotinaCard(context, treino),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text('ÚLTIMOS TREINOS', style: _sectionStyle)),
                  TextButton(onPressed: onHistorico, child: const Text('Ver todos')),
                ]),
                if (historico.isEmpty)
                  _panel(child: const Text('Nenhum treino finalizado ainda. Seus registros aparecerão aqui.'))
                else
                  ...historico.take(3).map((session) => _registro(context, session)),
                const SizedBox(height: 16),
                _panel(child: const Row(children: [
                  Icon(Icons.home_outlined, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Treinar em casa', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Funcionalidade em desenvolvimento',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                ])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dia(BuildContext context, DateTime day, DateTime today) {
    final scheduled = _treinoPorId(data.programacaoSemanal[day.weekday]);
    final finished = StudentWeeklyProgress.onDay(historico, day);
    final scheduledDone = StudentWeeklyProgress.completedRoutineOnDay(
      finished, day, scheduled?.id,
    );
    final isToday = StudentWeeklyProgress.sameDay(day, today);
    final didTrain = finished.isNotEmpty;
    final label = scheduled == null ? 'Descanso' : scheduled.nome;
    final status = scheduledDone != null
        ? (scheduledDone.completedSets == scheduledDone.totalSets && scheduledDone.totalSets > 0
            ? 'Feito' : 'Parcial')
        : didTrain ? 'Treinou' : isToday ? 'Hoje'
        : day.isAfter(DateTime(today.year, today.month, today.day)) ? 'Programado'
        : scheduled == null ? 'Descanso' : 'Não registrado';
    final completed = scheduledDone != null || didTrain;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: isToday ? AppColors.primaryActionSurface : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('aluno_dia_${day.weekday}'),
          borderRadius: BorderRadius.circular(12),
          onTap: scheduled == null ? null : () => _abrirFicha(context, scheduled),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completed ? AppColors.successSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_dias[day.weekday - 1].substring(0, 3).toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600)),
                if (didTrain)
                  Text(finished.first.routineName == label ? 'Registrado no histórico'
                      : 'Fez ${finished.first.routineName}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              const SizedBox(width: 7),
              _chip(status, foreground: completed ? AppColors.success : AppColors.textBody,
                background: completed ? AppColors.successSurface : Colors.white),
              if (scheduled != null) const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _rotinaCard(BuildContext context, TreinoUi treino) {
    final preview = treino.exercicios.isNotEmpty ? treino.exercicios.first.imageUrl : null;
    return _panel(padding: const EdgeInsets.all(12), child: Column(
      children: [
        Row(children: [
          StudentExercisePhoto(url: preview, size: 74),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(treino.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text('${treino.quantidadeExercicios} exercícios  •  ${treino.duracaoMinutos} min',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (treino.descricao.trim().isNotEmpty)
              Text(treino.descricao, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          ])),
          _chip('Treino ${treino.letra}'),
        ]),
        const SizedBox(height: 10),
        Text(treino.exercicios.take(3).map((e) => e.nome).join(' • '),
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          key: Key('aluno_ver_ficha_${treino.id}'),
          onPressed: () => _abrirFicha(context, treino),
          icon: const Icon(Icons.list_alt_outlined, size: 18),
          label: const Text('Ver ficha completa'),
        )),
      ],
    ));
  }

  Widget _registro(BuildContext context, TrainingSession session) {
    final date = (session.finishedAt ?? session.startedAt).toLocal();
    final day = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _panel(child: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(session.routineName, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('$day às $time  •  ${session.completedSets}/${session.totalSets} séries',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        TextButton(onPressed: onHistorico, child: const Text('Detalhes')),
      ])),
    );
  }
}
