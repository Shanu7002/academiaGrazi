import 'package:academiagrazi/models/training/training_session.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
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

  const AlunoSessaoTreinoView({
    super.key,
    required this.studentId,
    required this.planId,
    required this.routineId,
    this.existingSessionId,
    this.service,
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
            title: const Text('Finalizar treino?'),
            content: const Text(
              'A sessão será salva no histórico. Depois de finalizar, '
              'as séries não poderão ser alteradas.',
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
      appBar: AppBar(
        title: Text(session?.routineName ?? 'Executar treino'),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
      ),
      backgroundColor: AppColors.trainingListBackground,
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
              : session == null
              ? const Center(child: Text('Sessão indisponível.'))
              : _conteudo(session),
    );
  }

  Widget _conteudo(TrainingSession session) {
    final progress =
        session.totalSets == 0
            ? 0.0
            : session.completedSets / session.totalSets;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              if (_salvando) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seu progresso',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${session.completedSets} de ${session.totalSets} séries concluídas',
                              key: const Key('progresso_series'),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              key: const Key('marcar_aquecimento'),
                              title: const Text('Aquecimento realizado'),
                              value: session.warmupDone,
                              contentPadding: EdgeInsets.zero,
                              onChanged:
                                  _salvando
                                      ? null
                                      : (value) =>
                                          _marcarAquecimento(value ?? false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...session.exercises.map(_exercicio),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('finalizar_treino'),
                    onPressed: _salvando ? null : _finalizar,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('FINALIZAR TREINO'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exercicio(TrainingSessionExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
            if (exercise.muscleGroup.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(exercise.muscleGroup),
            ],
            const SizedBox(height: 8),
            Text(
              '${exercise.repetitions} repetições · ${exercise.restSeconds}s descanso · ${exercise.technique}',
            ),
            if (exercise.instructions.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(exercise.instructions),
            ],
            const Divider(height: 24),
            ...exercise.sets.map((set) => _serie(exercise, set)),
          ],
        ),
      ),
    );
  }

  Widget _serie(TrainingSessionExercise exercise, TrainingSetResult set) {
    final key = _key(exercise.itemId, set.number);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              '${set.number}ª série',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              key: Key('carga_${exercise.itemId}_${set.number}'),
              initialValue: _cargasDigitadas[key] ?? '',
              onChanged: (value) => _cargasDigitadas[key] = value,
              enabled: !_salvando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Carga (kg)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            key: Key('salvar_serie_${exercise.itemId}_${set.number}'),
            tooltip: 'Salvar carga',
            onPressed:
                _salvando
                    ? null
                    : () =>
                        _salvarSerie(exercise, set, concluida: set.completed),
            icon: const Icon(Icons.save_outlined),
          ),
          Checkbox(
            key: Key('serie_concluida_${exercise.itemId}_${set.number}'),
            value: set.completed,
            onChanged:
                _salvando
                    ? null
                    : (checked) => _salvarSerie(
                      exercise,
                      set,
                      concluida: checked ?? false,
                    ),
          ),
        ],
      ),
    );
  }
}
