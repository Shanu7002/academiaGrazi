import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Editor opcional. Nada fica visivel para o aluno antes de "Publicar".
/// Nao modifica trainingPlans nem a programacao semanal presencial.
class ProfessorTreinoEmCasaView extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String instructorId;
  final HomeWorkoutService service;
  final ExerciseCatalogService catalogService;

  const ProfessorTreinoEmCasaView({super.key, required this.studentId,
    required this.studentName, required this.instructorId,
    required this.service, required this.catalogService});

  @override
  State<ProfessorTreinoEmCasaView> createState() => _ProfessorTreinoEmCasaViewState();
}

class _ProfessorTreinoEmCasaViewState extends State<ProfessorTreinoEmCasaView> {
  final List<TrainingRoutine> _routines = [];
  bool _loading = true;
  bool _saving = false;
  bool _published = false;
  int _sequence = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final current = await widget.service.getCurrent(widget.studentId);
      if (!mounted) return;
      setState(() {
        _routines
          ..clear()
          ..addAll(current?.routines ?? const <TrainingRoutine>[]);
        _published = current != null;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível consultar os treinos em casa. Confira as permissões.';
          _loading = false;
        });
      }
    }
  }

  String _newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';

  void _replaceRoutine(TrainingRoutine updated) {
    final index = _routines.indexWhere((r) => r.id == updated.id);
    if (index >= 0) setState(() => _routines[index] = updated);
  }

  TrainingRoutine _copy(TrainingRoutine r, {String? name, String? focus,
    String? warmup, int? minutes, List<TrainingExercise>? exercises}) =>
      TrainingRoutine(id: r.id, letter: r.letter, name: name ?? r.name,
        focus: focus ?? r.focus, warmupInstructions: warmup ?? r.warmupInstructions,
        estimatedMinutes: minutes ?? r.estimatedMinutes,
        imageUrl: null, exercises: exercises ?? r.exercises);

  Future<void> _editRoutine([TrainingRoutine? current]) async {
    final name = TextEditingController(text: current?.name ?? 'Treino em casa ${_routines.length + 1}');
    final focus = TextEditingController(text: current?.focus ?? '');
    final warmup = TextEditingController(text: current?.warmupInstructions ?? '');
    final duration = TextEditingController(text: '${current?.estimatedMinutes ?? 30}');
    final result = await showDialog<({String name, String focus, String warmup, int duration})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(current == null ? 'Novo treino em casa' : 'Editar treino em casa'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome do treino')),
          TextField(controller: focus, decoration: const InputDecoration(labelText: 'Foco (opcional)')),
          TextField(controller: duration, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duração prevista (min)')),
          TextField(controller: warmup, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Aquecimento (opcional)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final mins = int.tryParse(duration.text.trim());
            if (name.text.trim().isEmpty || mins == null || mins < 0) return;
            Navigator.pop(dialogContext, (name: name.text.trim(), focus: focus.text.trim(),
              warmup: warmup.text.trim(), duration: mins));
          }, child: const Text('Confirmar')),
        ],
      ),
    );
    name.dispose(); focus.dispose(); warmup.dispose(); duration.dispose();
    if (!mounted || result == null) return;
    if (current != null) {
      _replaceRoutine(_copy(current, name: result.name, focus: result.focus,
        warmup: result.warmup, minutes: result.duration));
    } else {
      if (_routines.length >= 8) { _notice('Limite de 8 treinos em casa.'); return; }
      setState(() => _routines.add(TrainingRoutine(
        id: _newId('casa'), letter: String.fromCharCode(65 + _routines.length),
        name: result.name, focus: result.focus,
        warmupInstructions: result.warmup, estimatedMinutes: result.duration,
        exercises: const [],
      )));
    }
  }

  Future<ExerciseCatalogEntry?> _pickCatalog() async {
    final search = TextEditingController();
    var results = widget.catalogService.search(limit: 50);
    final selected = await showModalBottomSheet<ExerciseCatalogEntry>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (ctx, updateModal) =>
        SizedBox(height: MediaQuery.of(ctx).size.height * .75,
          child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Text('Biblioteca de exercícios', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: search,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar exercício', border: OutlineInputBorder()),
              onChanged: (text) => updateModal(() => results =
                  widget.catalogService.search(query: text, limit: 50))),
            const SizedBox(height: 10),
            Expanded(child: FutureBuilder<List<ExerciseCatalogEntry>>(
              future: results, builder: (ctx, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Não foi possível consultar a biblioteca.'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text('Nenhum exercício encontrado.'));
                return ListView.builder(itemCount: snapshot.data!.length,
                  itemBuilder: (ctx, index) {
                    final entry = snapshot.data![index];
                    return ListTile(title: Text(entry.name), subtitle: Text(entry.muscleGroup),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(sheetContext, entry));
                  });
              },
            )),
          ]))),
      ),
    );
    search.dispose();
    return selected;
  }

  Future<void> _addCatalogExercise(TrainingRoutine routine) async {
    final catalog = await _pickCatalog();
    if (!mounted || catalog == null) return;
    final exercise = TrainingExercise(id: _newId('item-casa'),
      catalogExerciseId: catalog.id, name: catalog.name,
      muscleGroup: StudentExercisePresentation.muscleGroup(catalog.muscleGroup),
      instructions: StudentExercisePresentation.guidance('', catalog).text ?? '',
      imageUrl: StudentExercisePresentation.image(null, catalog),
      sets: 3, repetitions: 12, restSeconds: 60);
    _replaceRoutine(_copy(routine, exercises: [...routine.exercises, exercise]));
  }

  Future<void> _addManualExercise(TrainingRoutine routine) async {
    final name = TextEditingController();
    final muscle = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<({String name, String muscle, String notes})>(
      context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Exercício personalizado'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: muscle, decoration: const InputDecoration(labelText: 'Grupo muscular')),
          TextField(controller: notes, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Orientações em português')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar')), FilledButton(onPressed: () {
            if (name.text.trim().isEmpty || muscle.text.trim().isEmpty) return;
            Navigator.pop(dialogContext, (name: name.text.trim(),
              muscle: muscle.text.trim(), notes: notes.text.trim()));
          }, child: const Text('Adicionar'))],
      ),
    );
    name.dispose(); muscle.dispose(); notes.dispose();
    if (!mounted || result == null) return;
    final id = _newId('item-manual');
    final exercise = TrainingExercise(id: id, catalogExerciseId: id,
      name: result.name, muscleGroup: result.muscle, instructions: result.notes,
      sets: 3, repetitions: 12, restSeconds: 60);
    _replaceRoutine(_copy(routine, exercises: [...routine.exercises, exercise]));
  }

  Future<void> _editExercise(TrainingRoutine routine, TrainingExercise exercise) async {
    final sets = TextEditingController(text: '${exercise.sets}');
    final reps = TextEditingController(text: '${exercise.repetitions}');
    final rest = TextEditingController(text: '${exercise.restSeconds}');
    final notes = TextEditingController(text: exercise.instructions);
    final result = await showDialog<({int sets, int reps, int rest, String notes})>(
      context: context, builder: (ctx) => AlertDialog(
        title: Text(exercise.name),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: sets, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Séries')),
          TextField(controller: reps, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetições')),
          TextField(controller: rest, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Descanso em segundos')),
          TextField(controller: notes, maxLines: 5,
            decoration: const InputDecoration(labelText: 'Orientações em português')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar')), FilledButton(onPressed: () {
            final s = int.tryParse(sets.text.trim());
            final r = int.tryParse(reps.text.trim());
            final d = int.tryParse(rest.text.trim());
            if (s == null || s <= 0 || r == null || r <= 0 || d == null || d < 0) return;
            Navigator.pop(ctx, (sets: s, reps: r, rest: d, notes: notes.text.trim()));
          }, child: const Text('Salvar'))],
      ),
    );
    sets.dispose(); reps.dispose(); rest.dispose(); notes.dispose();
    if (!mounted || result == null) return;
    final updated = TrainingExercise(
      id: exercise.id, catalogExerciseId: exercise.catalogExerciseId,
      name: exercise.name, muscleGroup: exercise.muscleGroup,
      imageUrl: exercise.imageUrl, instructions: result.notes,
      sets: result.sets, repetitions: result.reps, restSeconds: result.rest,
      technique: exercise.technique, targetLoadKg: exercise.targetLoadKg,
    );
    _replaceRoutine(_copy(routine, exercises: [
      for (final item in routine.exercises) item.id == updated.id ? updated : item,
    ]));
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _publish() async {
    if (_saving) return;
    if (_routines.isEmpty) { _notice('Crie um treino antes de publicar.'); return; }
    try {
      for (final routine in _routines) { routine.validate(); }
    } catch (_) { _notice('Todos os treinos precisam ter ao menos um exercício válido.'); return; }
    setState(() => _saving = true);
    try {
      await widget.service.publish(studentId: widget.studentId,
        instructorId: widget.instructorId, routines: _routines);
      if (!mounted) return;
      setState(() => _published = true);
      _notice('Treinos em casa publicados para ${widget.studentName}.');
    } catch (error) {
      _notice('Não foi possível publicar: $error');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _deleteAll() async {
    if (_saving || !_published) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Retirar treinos em casa?'),
      content: const Text('A opção desaparecerá para o aluno. O histórico de treinos concluídos será preservado.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirar treinos'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.service.remove(studentId: widget.studentId, instructorId: widget.instructorId);
      if (!mounted) return;
      setState(() { _routines.clear(); _published = false; });
      _notice('Treinos em casa retirados. Histórico preservado.');
    } catch (error) { _notice('Não foi possível retirar: $error'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.trainingListBackground,
    appBar: AppBar(title: const Text('Treinos em casa')),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Aluno: ${widget.studentName}', style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Prescrição opcional e independente da ficha presencial. '
              'Só aparece para o aluno depois de publicar.'),
          const SizedBox(height: 5),
          const Text('Revise tecnicamente as orientações antes de disponibilizar '
              'uma nova prescrição.', style: TextStyle(fontSize: 12,
                color: AppColors.textSecondary)),
          if (_error != null) ...[const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger))],
          const SizedBox(height: 12),
          for (final routine in _routines) Card(color: Colors.white, child: ExpansionTile(
            key: Key('casa_routine_${routine.id}'), initiallyExpanded: true,
            title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${routine.exercises.length} exercícios • ${routine.estimatedMinutes} min'),
            children: [Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (routine.warmupInstructions.isNotEmpty)
                  Text('Aquecimento: ${routine.warmupInstructions}'),
                Wrap(spacing: 8, children: [
                  TextButton.icon(onPressed: _saving ? null : () => _editRoutine(routine),
                    icon: const Icon(Icons.edit), label: const Text('Editar treino')),
                  TextButton.icon(onPressed: _saving ? null : () => setState(() =>
                    _routines.removeWhere((r) => r.id == routine.id)),
                    icon: const Icon(Icons.delete_outline), label: const Text('Remover')),
                ]),
                for (final exercise in routine.exercises) ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise.name),
                  subtitle: Text('${exercise.sets} séries • ${exercise.repetitions} rep. • ${exercise.restSeconds}s'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Editar exercício', onPressed: _saving ? null :
                      () => _editExercise(routine, exercise), icon: const Icon(Icons.edit_outlined)),
                    IconButton(tooltip: 'Remover exercício', onPressed: _saving ? null :
                      () => _replaceRoutine(_copy(routine, exercises: [
                        for (final e in routine.exercises) if (e.id != exercise.id) e,
                      ])), icon: const Icon(Icons.close)),
                  ]),
                ),
                OutlinedButton.icon(onPressed: _saving ? null : () => _addCatalogExercise(routine),
                  icon: const Icon(Icons.search), label: const Text('Adicionar da biblioteca')),
                const SizedBox(height: 6),
                OutlinedButton.icon(onPressed: _saving ? null : () => _addManualExercise(routine),
                  icon: const Icon(Icons.add), label: const Text('Exercício personalizado')),
              ],
            ))],
          )),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _saving || _routines.length >= 8 ? null :
              () => _editRoutine(), icon: const Icon(Icons.add),
            label: const Text('Adicionar treino em casa')),
          const SizedBox(height: 12),
          FilledButton.icon(key: const Key('publicar_treinos_casa'),
            onPressed: _saving ? null : _publish,
            icon: const Icon(Icons.send_outlined),
            label: Text(_saving ? 'Salvando...' : 'Publicar treinos em casa')),
          if (_published) TextButton.icon(onPressed: _saving ? null : _deleteAll,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Retirar treinos em casa do aluno')),
          const SizedBox(height: 20),
        ]))),
  );
}
