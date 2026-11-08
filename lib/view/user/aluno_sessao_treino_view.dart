import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:academiagrazi/view/user/student_exercise_photo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Execucao real de uma rotina A/B/C, persistida no Firestore.
/// Nao altera a ficha publicada pelo professor.
class AlunoSessaoTreinoView extends StatefulWidget {
  final String studentId;
  final String planId;
  final String routineId;
  final String? existingSessionId;
  final TrainingSessionService? service;
  final TrainingPlanService? planService;

  const AlunoSessaoTreinoView({
    super.key,
    required this.studentId,
    required this.planId,
    required this.routineId,
    this.existingSessionId,
    this.service,
    this.planService,
  });

  @override
  State<AlunoSessaoTreinoView> createState() => _AlunoSessaoTreinoViewState();
}

class _AlunoSessaoTreinoViewState extends State<AlunoSessaoTreinoView> {
  late final TrainingSessionService _service;
  final Map<String, String> _cargasDigitadas = {};
  TrainingSession? _session;
  String? _erro;
  bool _carregando = true;
  bool _salvando = false;
  Map<String, ExerciseCatalogEntry> _catalog = const {};
  String _warmupInstructions = '';

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrainingSessionService();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final TrainingSession session;
      if (widget.existingSessionId != null) {
        final existing = await _service.getSession(
          widget.studentId,
          widget.existingSessionId!,
        );
        if (existing == null ||
            existing.studentId != widget.studentId ||
            existing.status != TrainingSessionStatus.inProgress) {
          throw StateError('Nao foi possivel retomar o treino.');
        }
        session = existing;
      } else {
        session = await _service.startSession(
          studentId: widget.studentId,
          planId: widget.planId,
          routineId: widget.routineId,
        );
      }
      if (!mounted) return;
      _cargasDigitadas.clear();
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          final load = set.loadKg ?? exercise.suggestedLoadKg;
          if (load != null) {
            _cargasDigitadas[_key(exercise.itemId, set.number)] = _formatLoad(
              load,
            );
          }
        }
      }
      setState(() {
        _session = session;
        _carregando = false;
      });
      // Consulta em lotes, somente para apresentacao; nao regrava snapshots.
      _carregarCatalogo(session);
      _carregarAquecimento(session);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro =
            'Não foi possível abrir este treino. '
            'Verifique sua conexão ou retome a sessão anterior.';
        _carregando = false;
      });
    }
  }

  Future<void> _carregarCatalogo(TrainingSession session) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final entries = await ExerciseCatalogService().findByIds(
        session.exercises.map((e) => e.catalogExerciseId),
      );
      if (mounted && _session?.id == session.id) {
        setState(() => _catalog = entries);
      }
    } catch (_) {
      // O historico deve continuar utilizavel mesmo sem a biblioteca.
    }
  }

  /// Lido da ficha publicada original; nao altera documento de sessao,
  /// nao precisa de campo novo nas regras atuais do Firestore.
  Future<void> _carregarAquecimento(TrainingSession session) async {
    if (Firebase.apps.isEmpty && widget.planService == null) return;
    try {
      final plan = await (widget.planService ?? TrainingPlanService())
          .getPublishedPlanById(widget.studentId, session.planId);
      final matching = plan?.routines.where((r) => r.id == session.routineId);
      final warmup = matching == null || matching.isEmpty
          ? '' : matching.first.warmupInstructions.trim();
      if (mounted && _session?.id == session.id) {
        setState(() => _warmupInstructions = warmup);
      }
    } catch (_) {
      // Exercicios e cargas continuam disponiveis sem esta informacao extra.
    }
  }

  static String _key(String itemId, int setNumber) => '$itemId/$setNumber';

  static String _formatLoad(double kg) =>
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

  double? _parseLoad(String? raw) {
    final value = raw?.trim().replaceAll(',', '.') ?? '';
    if (value.isEmpty) return null;
    final amount = double.tryParse(value);
    if (amount == null || !amount.isFinite || amount < 0) {
      throw const FormatException('Informe uma carga válida em kg.');
    }
    return amount;
  }

  void _avisar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _salvarSerie(
    TrainingSessionExercise exercise,
    TrainingSetResult set, {
    required bool concluida,
  }) async {
    final session = _session;
    if (_salvando || session == null) return;
    late final double? carga;
    try {
      carga = _parseLoad(
        _cargasDigitadas[_key(exercise.itemId, set.number)] ??
            (set.loadKg == null ? null : _formatLoad(set.loadKg!)),
      );
    } on FormatException catch (error) {
      _avisar(error.message);
      return;
    }
    setState(() => _salvando = true);
    try {
      final updated = await _service.recordSet(
        studentId: widget.studentId,
        sessionId: session.id,
        exerciseItemId: exercise.itemId,
        setNumber: set.number,
        completed: concluida,
        loadKg: carga,
      );
      if (!mounted) return;
      setState(() => _session = updated);
    } catch (_) {
      _avisar('Não foi possível salvar esta série. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _marcarAquecimento(bool done) async {
    final session = _session;
    if (_salvando || session == null) return;
    setState(() => _salvando = true);
    try {
      final updated = await _service.setWarmup(
        studentId: widget.studentId,
        sessionId: session.id,
        done: done,
      );
      if (!mounted) return;
      setState(() => _session = updated);
    } catch (_) {
      _avisar('Não foi possível atualizar o aquecimento.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _finalizar() async {
    final session = _session;
    if (session == null || _salvando) return;
    if (session.completedSets == 0) {
      _avisar('Conclua pelo menos uma série antes de finalizar.');
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(session.completedSets < session.totalSets
                ? 'Finalizar com séries pendentes?' : 'Finalizar treino?'),
            content: Text(
              session.completedSets < session.totalSets
                  ? 'Você realizou ${session.completedSets} de ${session.totalSets} séries. '
                    'O professor verá este treino como parcialmente concluído. '
                    'Depois de finalizar, não poderá editar as séries.'
                  : 'A sessão será salva no histórico e o professor poderá '
                    'acompanhar o resultado. As séries não poderão ser alteradas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Continuar treino'),
              ),
              FilledButton(
                key: const Key('confirmar_finalizacao'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Finalizar'),
              ),
            ],
          ),
    );
    if (!mounted || confirmado != true) return;
    setState(() => _salvando = true);
    try {
      await _service.finishSession(
        studentId: widget.studentId,
        sessionId: session.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _avisar('Não foi possível finalizar o treino. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      backgroundColor: AppColors.trainingListBackground,
      appBar: AppBar(
        title: Text(session?.routineName ?? 'Meu treino',
          style: GoogleFonts.barlowCondensed(fontSize: 24,
            fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_erro!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _carregar,
                        child: const Text('Tentar novamente')),
                  ])))
              : session == null
                  ? const Center(child: Text('Sessão indisponível.'))
                  : _conteudo(session),
    );
  }

  Widget _conteudo(TrainingSession session) {
    final progress = session.totalSets == 0 ? 0.0
        : session.completedSets / session.totalSets;
    return SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(children: [
        if (_salvando) const LinearProgressIndicator(minHeight: 3),
        Expanded(child: ListView(
          key: const Key('aluno_execucao_real'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('SEU PROGRESSO', style:
                      GoogleFonts.barlowCondensed(fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                  Container(padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(color: AppColors.primaryActionSurface,
                      shape: BoxShape.circle),
                    child: Text('${(progress * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                          color: AppColors.primary))),
                ]),
                const SizedBox(height: 8),
                Text('${session.completedSets} de ${session.totalSets} séries concluídas',
                    key: const Key('progresso_series'),
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(value: progress, minHeight: 9,
                    backgroundColor: AppColors.progressTrack,
                    color: AppColors.primary)),
                if (_warmupInstructions.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text('AQUECIMENTO ORIENTADO PELO PROFESSOR',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
                const SizedBox(height: 5),
                Text(_warmupInstructions,
                  style: const TextStyle(color: AppColors.textBody, fontSize: 13)),
                CheckboxListTile(
                  key: const Key('marcar_aquecimento'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Aquecimento realizado',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Marque somente depois de concluir as orientações acima.'),
                  value: session.warmupDone,
                  activeColor: AppColors.primary,
                  onChanged: _salvando ? null : (value) =>
                      _marcarAquecimento(value ?? false),
                ),
                ],
              ]),
            ),
            const SizedBox(height: 22),
            Text('EXERCÍCIOS', style: GoogleFonts.barlowCondensed(
              fontSize: 25, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            for (var i = 0; i < session.exercises.length; i++)
              _exercicio(session.exercises[i], i + 1),
            const SizedBox(height: 6),
            const Text('Suas séries são salvas no Firebase quando você '
                'marca a conclusão ou salva a carga. Pode sair e retomar depois.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(width: double.infinity, child: FilledButton.icon(
            key: const Key('finalizar_treino'),
            onPressed: _salvando ? null : _finalizar,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15)),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Finalizar treino',
                style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ),
      ]),
    )));
  }

  Widget _exercicio(TrainingSessionExercise exercise, int number) {
    final entry = _catalog[exercise.catalogExerciseId];
    final name = StudentExercisePresentation.name(exercise.name, entry);
    final image = StudentExercisePresentation.image(exercise.imageUrl, entry);
    final guidance = StudentExercisePresentation.guidance(exercise.instructions, entry);
    final instructions = guidance.text;
    final done = exercise.sets.where((set) => set.completed).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border)),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StudentExercisePhoto(url: image, size: 84),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$number. ', style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: AppColors.primary)),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
              ]),
              const SizedBox(height: 4),
              Text(StudentExercisePresentation.muscleGroup(exercise.muscleGroup),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 7),
              Text('$done/${exercise.sets.length} séries  •  ${exercise.repetitions} repetições',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700,
                  fontSize: 12)),
              Text('${exercise.restSeconds}s de descanso',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
            Icon(exercise.completed ? Icons.check_circle : Icons.circle_outlined,
              color: exercise.completed ? AppColors.success : AppColors.inactive),
          ]),
          const SizedBox(height: 12),
          if (instructions != null) ...[
            const Text('ORIENTAÇÕES DE EXECUÇÃO',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(instructions,
              style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
            if (guidance.automaticTranslation) ...[
              const SizedBox(height: 6),
              const Text('Tradução automática não revisada. Confirme com seu professor.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
            const SizedBox(height: 8),
          ] else ...[
            const Text('Orientações em revisão. Consulte o professor '
                'antes de executar este movimento.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
          ],
          const Divider(height: 14),
          for (final set in exercise.sets) _serie(exercise, set),
        ])),
    );
  }

  Widget _serie(TrainingSessionExercise exercise, TrainingSetResult set) {
    final key = _key(exercise.itemId, set.number);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 57,
          child: Text('${set.number}ª série',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(width: 7),
        Expanded(child: TextFormField(
          key: Key('carga_${exercise.itemId}_${set.number}'),
          initialValue: _cargasDigitadas[key] ?? '',
          onChanged: (value) => _cargasDigitadas[key] = value,
          enabled: !_salvando,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Carga (kg)',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
            suffixIcon: IconButton(
              key: Key('salvar_serie_${exercise.itemId}_${set.number}'),
              tooltip: 'Salvar carga desta série',
              icon: const Icon(Icons.save_outlined, size: 20),
              onPressed: _salvando ? null : () => _salvarSerie(
                exercise, set, concluida: set.completed,
              ),
            ),
          ),
        )),
        const SizedBox(width: 6),
        Checkbox(
          key: Key('serie_concluida_${exercise.itemId}_${set.number}'),
          value: set.completed,
          activeColor: AppColors.primary,
          onChanged: _salvando ? null : (checked) => _salvarSerie(
            exercise, set, concluida: checked ?? false,
          ),
        ),
      ]),
    );
  }
}
