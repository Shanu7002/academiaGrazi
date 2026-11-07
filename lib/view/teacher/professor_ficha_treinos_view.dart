import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/controller/teachers/training_plan_composer.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:academiagrazi/view/teacher/widgets/exercicio_montagem_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Editor de fichas completas, separado da montagem antiga.
/// O servidor e as regras do Firestore validam o vinculo professor/aluno.
/// Imagens de exercicios personalizados aguardam upload em uma etapa futura.
class ProfessorFichaTreinosView extends StatefulWidget {
  final String? instructorId;
  final TeacherUserSearcher? searcher;
  final TrainingPlanService? service;

  const ProfessorFichaTreinosView({
    super.key,
    this.instructorId,
    this.searcher,
    this.service,
  });

  @override
  State<ProfessorFichaTreinosView> createState() =>
      _ProfessorFichaTreinosViewState();
}

class _ProfessorFichaTreinosViewState extends State<ProfessorFichaTreinosView> {
  static const _catalogo = <ExercicioCatalogoProfessorUi>[
    ExercicioCatalogoProfessorUi(
      id: 'c1',
      nome: 'Supino Reto',
      grupoMuscular: 'Peito',
    ),
    ExercicioCatalogoProfessorUi(
      id: 'c2',
      nome: 'Agachamento Livre',
      grupoMuscular: 'Pernas',
    ),
    ExercicioCatalogoProfessorUi(
      id: 'c3',
      nome: 'Puxada Frontal',
      grupoMuscular: 'Costas',
    ),
    ExercicioCatalogoProfessorUi(
      id: 'c4',
      nome: 'Rosca Direta',
      grupoMuscular: 'Bíceps',
    ),
  ];

  static const _dias = <String>[
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  late final TrainingPlanService _service;
  late final TeacherUserSearcher _searcher;
  String? _instructorId;
  String? _selectedStudentId;
  String? _selectedRoutineId;
  List<UserSummary> _students = const [];
  final Map<String, TrainingPlanComposer> _drafts = {};
  final Set<String> _publishedStudents = {};
  bool _loadingStudents = true;
  bool _loadingDraft = false;
  bool _saving = false;
  int _selectionVersion = 0;
  int _nextItemId = 0;
  String? _error;

  TrainingPlanComposer? get _composer =>
      _selectedStudentId == null ? null : _drafts[_selectedStudentId!];

  bool get _published =>
      _selectedStudentId != null &&
      _publishedStudents.contains(_selectedStudentId);

  TrainingRoutine? get _routine {
    final composer = _composer;
    final routineId = _selectedRoutineId;
    if (composer == null || routineId == null) return null;
    for (final candidate in composer.routines) {
      if (candidate.id == routineId) return candidate;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrainingPlanService();
    _searcher = widget.searcher ?? TeacherUserSearcher();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final id =
          widget.instructorId ?? locator<FirebaseAuth>().currentUser?.uid;
      if (id == null || id.isEmpty) {
        throw StateError('Entre na conta do professor para montar fichas.');
      }
      _instructorId = id;
      final students = await _searcher.streamLinkedUsers(id).first;
      if (!mounted) return;
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
      if (students.isNotEmpty) {
        await _selectStudent(students.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os alunos: $e';
        _loadingStudents = false;
      });
    }
  }

  TrainingPlanComposer _newComposer(String studentId) {
    final composer = TrainingPlanComposer(
      studentId: studentId,
      instructorId: _instructorId!,
      name: 'Ficha de treino',
    );
    composer.addRoutine(letter: 'A', name: 'Treino A');
    // Os 7 dias aparecem no editor mesmo antes de existir programação.
    for (var day = 1; day <= 7; day++) {
      composer.assignDay(day, null);
    }
    return composer;
  }

  Future<void> _selectStudent(String studentId) async {
    final selectionVersion = ++_selectionVersion;
    setState(() {
      _selectedStudentId = studentId;
      _loadingDraft = true;
      _error = null;
    });
    try {
      TrainingPlanComposer composer;
      if (_drafts.containsKey(studentId)) {
        composer = _drafts[studentId]!;
      } else {
        final saved = await _service.getDraftsForStudent(
          studentId: studentId,
          instructorId: _instructorId!,
        );
        if (!mounted || selectionVersion != _selectionVersion) return;
        // Caso haja mais de um rascunho, abrimos o mais recente por versao.
        saved.sort((a, b) => b.version.compareTo(a.version));
        composer =
            saved.isEmpty
                ? _newComposer(studentId)
                : TrainingPlanComposer.fromDraft(saved.first);
        _drafts[studentId] = composer;
      }
      if (!mounted || selectionVersion != _selectionVersion) return;
      setState(() {
        _selectedRoutineId =
            composer.routines.isEmpty ? null : composer.routines.first.id;
        _loadingDraft = false;
      });
    } catch (e) {
      if (!mounted || selectionVersion != _selectionVersion) return;
      setState(() {
        _error = 'Não foi possível abrir a ficha: $e';
        _loadingDraft = false;
      });
    }
  }

  void _addRoutine() {
    final composer = _composer!;
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String? newLetter;
    for (final char in letters.split('')) {
      if (!composer.routines.any((routine) => routine.letter == char)) {
        newLetter = char;
        break;
      }
    }
    if (newLetter == null) {
      _notice('Limite de treinos atingido.');
      return;
    }
    final id = composer.addRoutine(
      letter: newLetter,
      name: 'Treino $newLetter',
    );
    setState(() => _selectedRoutineId = id);
  }

  void _removeRoutine() {
    final composer = _composer!;
    if (composer.routines.length <= 1) {
      _notice('A ficha precisa ter pelo menos um treino.');
      return;
    }
    composer.removeRoutine(_selectedRoutineId!);
    setState(() => _selectedRoutineId = composer.routines.first.id);
  }

  void _addExercise(ExercicioCatalogoProfessorUi exercicio) {
    final composer = _composer!;
    final routineId = _selectedRoutineId!;
    _nextItemId++;
    composer.addExercise(
      routineId,
      TrainingExercise(
        id: 'item-${DateTime.now().microsecondsSinceEpoch}-$_nextItemId',
        catalogExerciseId: exercicio.id,
        name: exercicio.nome,
        muscleGroup: exercicio.grupoMuscular,
        instructions: exercicio.orientacoes,
        sets: 3,
        repetitions: 12,
        restSeconds: 60,
        technique: 'Tradicional',
      ),
    );
    setState(() {});
  }

  void _updateExercise(
    TrainingExercise exercise,
    ExercicioMontadoProfessorUi edited,
  ) {
    _composer!.updateExercise(
      _selectedRoutineId!,
      TrainingExercise(
        id: exercise.id,
        catalogExerciseId: exercise.catalogExerciseId,
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        instructions: exercise.instructions,
        imageUrl: exercise.imageUrl,
        sets: edited.series,
        repetitions: edited.repeticoes,
        restSeconds: edited.descansoSegundos,
        technique: edited.tecnica,
        targetLoadKg: exercise.targetLoadKg,
      ),
    );
    setState(() {});
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _persist({required bool publish}) async {
    final composer = _composer;
    final studentId = _selectedStudentId;
    if (_saving || composer == null || studentId == null || _published) return;
    final draft = composer.buildDraft();
    if (publish) {
      try {
        draft.validateForPublication();
      } catch (e) {
        _notice('Revise a ficha antes de publicar: $e');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Publicar ficha para o aluno?'),
              content: const Text(
                'O aluno verá os treinos e dias programados. '
                'A ficha publicada não poderá ser alterada; '
                'uma correção exigirá uma nova ficha.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar publicação'),
                ),
              ],
            ),
      );
      if (!mounted || confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      var planId = draft.id;
      if (planId.isEmpty) {
        planId = await _service.createDraft(draft);
      } else {
        await _service.saveDraft(draft);
      }
      if (publish) {
        await _service.publishDraft(
          studentId: studentId,
          instructorId: _instructorId!,
          planId: planId,
        );
        _publishedStudents.add(studentId);
        _notice('Ficha publicada! O aluno poderá consultá-la no aplicativo.');
      } else {
        final saved = draft.copyWith(
          id: planId,
          version: draft.id.isEmpty ? 1 : draft.version + 1,
        );
        _drafts[studentId] = TrainingPlanComposer.fromDraft(saved);
        _notice('Rascunho salvo no Firebase.');
      }
    } catch (e) {
      _notice('Erro ao ${publish ? 'publicar' : 'salvar'} ficha: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _newRevision() {
    final studentId = _selectedStudentId;
    if (studentId == null || _saving) return;
    setState(() {
      _publishedStudents.remove(studentId);
      _drafts[studentId] = _newComposer(studentId);
      _selectedRoutineId = _drafts[studentId]!.routines.first.id;
    });
  }

  Widget _card({required String title, required Widget child}) => Card(
    elevation: 0,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  Widget _studentPicker() => _card(
    title: 'Aluno',
    child: DropdownButtonFormField<String>(
      key: ValueKey('aluno-selecionado-$_selectedStudentId'),
      initialValue: _selectedStudentId,
      isExpanded: true,
      items:
          _students
              .map(
                (student) => DropdownMenuItem(
                  value: student.id,
                  child: Text(student.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged:
          _saving
              ? null
              : (id) {
                if (id != null) _selectStudent(id);
              },
      decoration: const InputDecoration(
        labelText: 'Selecionar aluno vinculado',
      ),
    ),
  );

  Widget _routineEditor(TrainingRoutine routine) {
    final composer = _composer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          title: 'Treinos da ficha',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in composer.routines)
                    ChoiceChip(
                      key: Key('treino-${item.letter}'),
                      label: Text('Treino ${item.letter}'),
                      selected: _selectedRoutineId == item.id,
                      onSelected:
                          _saving
                              ? null
                              : (_) =>
                                  setState(() => _selectedRoutineId = item.id),
                    ),
                  ActionChip(
                    key: const Key('adicionar-treino'),
                    label: const Text('+ Novo treino'),
                    onPressed: _saving ? null : _addRoutine,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: ValueKey('nome-rotina-${routine.id}'),
                initialValue: routine.name,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Nome do treino'),
                onChanged: (name) {
                  if (name.trim().isNotEmpty) {
                    composer.updateRoutine(routineId: routine.id, name: name);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('foco-rotina-${routine.id}'),
                initialValue: routine.focus,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Grupo / objetivo',
                ),
                onChanged:
                    (focus) => composer.updateRoutine(
                      routineId: routine.id,
                      focus: focus,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('duracao-rotina-${routine.id}'),
                initialValue: '${routine.estimatedMinutes}',
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração estimada (min)',
                ),
                onChanged: (text) {
                  final minutes = int.tryParse(text);
                  if (minutes != null && minutes >= 0) {
                    composer.updateRoutine(
                      routineId: routine.id,
                      estimatedMinutes: minutes,
                    );
                  }
                },
              ),
              if (composer.routines.length > 1) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _removeRoutine,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover treino'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Exercícios — Treino ${routine.letter}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Catálogo inicial. Os exercícios com imagem personalizada '
                'serão integrados após o upload persistente.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in _catalogo)
                    ActionChip(
                      key: Key('catalogo-${item.id}'),
                      label: Text('${item.nome} +'),
                      onPressed: _saving ? null : () => _addExercise(item),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (routine.exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Adicione pelo menos um exercício neste treino.'),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: routine.exercises.length,
                  onReorder: (oldIndex, newIndex) {
                    if (_saving) return;
                    final target =
                        newIndex > oldIndex ? newIndex - 1 : newIndex;
                    _composer!.moveExercise(routine.id, oldIndex, target);
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final exercise = routine.exercises[index];
                    final displayed = ExercicioCatalogoProfessorUi(
                      id: exercise.catalogExerciseId,
                      nome: exercise.name,
                      grupoMuscular: exercise.muscleGroup,
                      orientacoes: exercise.instructions,
                    );
                    return Padding(
                      key: ValueKey(exercise.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ExercicioMontagemCard(
                        index: index,
                        exercicio: displayed,
                        item: ExercicioMontadoProfessorUi(
                          itemId: exercise.id,
                          exercicioId: exercise.catalogExerciseId,
                          series: exercise.sets,
                          repeticoes: exercise.repetitions,
                          descansoSegundos: exercise.restSeconds,
                          tecnica: exercise.technique,
                        ),
                        onChanged:
                            (edited) => _updateExercise(exercise, edited),
                        onRemove:
                            _saving
                                ? () {}
                                : () {
                                  _composer!.removeExercise(
                                    routine.id,
                                    exercise.id,
                                  );
                                  setState(() {});
                                },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weeklyCalendar(TrainingPlanComposer composer) => _card(
    title: 'Programação semanal',
    child: Column(
      children: [
        for (var day = 1; day <= 7; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(_dias[day - 1])),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('dia-$day-${composer.weeklySchedule[day]}'),
                    initialValue: composer.weeklySchedule[day] ?? 'descanso',
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    items: [
                      const DropdownMenuItem(
                        value: 'descanso',
                        child: Text('Descanso'),
                      ),
                      ...composer.routines.map(
                        (routine) => DropdownMenuItem(
                          value: routine.id,
                          child: Text('Treino ${routine.letter}'),
                        ),
                      ),
                    ],
                    onChanged:
                        _saving
                            ? null
                            : (id) {
                              setState(
                                () => composer.assignDay(
                                  day,
                                  id == 'descanso' ? null : id,
                                ),
                              );
                            },
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fichas A/B/C'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
      ),
      body:
          _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ?? 'Você ainda não possui alunos vinculados.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _studentPicker(),
                      const SizedBox(height: 12),
                      if (_loadingDraft)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red))
                      else if (_composer != null && _routine != null) ...[
                        if (_published) ...[
                          _card(
                            title: 'Ficha publicada',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'A ficha foi publicada. Para alterá-la, '
                                  'crie outra versão.',
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _newRevision,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Criar nova ficha'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _card(
                            title: 'Identificação da ficha',
                            child: TextFormField(
                              key: ValueKey('nome-ficha-$_selectedStudentId'),
                              initialValue: _composer!.name,
                              decoration: const InputDecoration(
                                labelText: 'Nome ou objetivo da ficha',
                              ),
                              onChanged: (value) => _composer!.name = value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _routineEditor(_routine!),
                          const SizedBox(height: 12),
                          _weeklyCalendar(_composer!),
                          const SizedBox(height: 12),
                          if (_saving)
                            const Center(child: CircularProgressIndicator())
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const Key('salvar-rascunho-ficha'),
                                    onPressed: () => _persist(publish: false),
                                    icon: const Icon(Icons.save_outlined),
                                    label: const Text('Salvar rascunho'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    key: const Key('publicar-ficha-aluno'),
                                    onPressed: () => _persist(publish: true),
                                    icon: const Icon(Icons.send_outlined),
                                    label: const Text('Publicar'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
