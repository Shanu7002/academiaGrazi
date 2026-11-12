import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'dart:typed_data';

import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:academiagrazi/controller/teachers/training_plan_composer.dart';
import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/training/training_exercise.dart';
import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/models/training/training_routine.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/service/training/student_exercise_presentation.dart';
import 'package:academiagrazi/service/training/home_workout_service.dart';
import 'package:academiagrazi/view/teacher/professor_treino_em_casa_view.dart';
import 'package:academiagrazi/service/training/training_media_service.dart';
import 'package:academiagrazi/service/training/training_routine_template_service.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/training/training_session_service.dart';
import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/components/exercise_details_sheet.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:academiagrazi/view/teacher/professor_historico_aluno_view.dart';
import 'package:academiagrazi/view/teacher/professor_resumo_treinos_aluno.dart';
import 'package:academiagrazi/view/teacher/services/seletor_imagem_exercicio.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:academiagrazi/view/teacher/widgets/cadastrar_exercicio_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fluxo principal do professor: alunos -> ficha do aluno -> leitura/edicao.
///
/// Reaproveita integralmente o TrainingPlanService e o TrainingPlanComposer.
/// Nunca edita um plano publicado: a revisao copia os dados para um NOVO
/// rascunho, preservando a ficha e o historico do aluno.
class ProfessorFichaTreinosView extends StatefulWidget {
  final String? instructorId;
  final TeacherUserSearcher? searcher;
  final TrainingPlanService? service;
  final ExerciseCatalogService? catalogService;
  final TrainingRoutineTemplateService? templateService;
  final TrainingMediaService? mediaService;
  final TrainingSessionService? sessionService;
  final VoidCallback? onVoltarInicio;

  const ProfessorFichaTreinosView({
    super.key,
    this.instructorId,
    this.searcher,
    this.service,
    this.catalogService,
    this.templateService,
    this.mediaService,
    this.sessionService,
    this.onVoltarInicio,
  });

  @override
  State<ProfessorFichaTreinosView> createState() =>
      _ProfessorFichaTreinosViewState();
}

enum _TelaProfessorTreinos { alunos, resumo, fichaPublicada, editor }

class _ProfessorFichaTreinosViewState extends State<ProfessorFichaTreinosView> {
  // Quatro movimentos offline para o ambiente sem catalogo importado.
  // A busca real utiliza exerciseCatalog no Firestore.
  static const _catalogoBase = <ExerciseCatalogEntry>[
    ExerciseCatalogEntry(id: 'c1', name: 'Supino Reto', muscleGroup: 'Peito'),
    ExerciseCatalogEntry(id: 'c2', name: 'Agachamento Livre', muscleGroup: 'Pernas'),
    ExerciseCatalogEntry(id: 'c3', name: 'Puxada Frontal', muscleGroup: 'Costas'),
    ExerciseCatalogEntry(id: 'c4', name: 'Rosca Direta', muscleGroup: 'Bíceps'),
  ];

  static const _dias = <String>[
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
  ];

  late final TrainingPlanService _service;
  late final TeacherUserSearcher _searcher;
  late final ExerciseCatalogService _catalogService;
  late final TrainingRoutineTemplateService _templateService;
  late final TrainingMediaService _mediaService;
  late final TrainingSessionService _sessionService;
  String? _instructorId;
  String? _studentId;
  String? _selectedRoutineId;
  String? _publishedRoutineId;
  final Map<String, TrainingPlanComposer> _drafts = {};
  final Map<String, TrainingPlan?> _published = {};
  List<UserSummary> _students = const [];
  _TelaProfessorTreinos _screen = _TelaProfessorTreinos.alunos;
  bool _loadingStudents = true;
  bool _loadingStudent = false;
  bool _saving = false;
  int _selectionToken = 0;
  int _newExerciseNumber = 0;
  String _searchText = '';
  String? _error;
  String? _validationMessage;

  TrainingPlanComposer? get _composer =>
      _studentId == null ? null : _drafts[_studentId!];

  TrainingPlan? get _activePlan =>
      _studentId == null ? null : _published[_studentId!];

  UserSummary? get _student {
    for (final student in _students) {
      if (student.id == _studentId) return student;
    }
    return null;
  }

  TrainingRoutine? get _editingRoutine {
    final composer = _composer;
    if (composer == null) return null;
    for (final routine in composer.routines) {
      if (routine.id == _selectedRoutineId) return routine;
    }
    return composer.routines.isEmpty ? null : composer.routines.first;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrainingPlanService();
    _searcher = widget.searcher ?? TeacherUserSearcher();
    _catalogService = widget.catalogService ??
        ExerciseCatalogService(db: _service.firestore);
    _templateService = widget.templateService ??
        TrainingRoutineTemplateService(db: _service.firestore);
    _mediaService = widget.mediaService ?? TrainingMediaService();
    _sessionService = widget.sessionService ?? TrainingSessionService(
      db: _service.firestore, planService: _service);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loadingStudents = true;
      _searchText = '';
      _error = null;
    });
    try {
      final teacherId =
          widget.instructorId ?? locator<FirebaseAuth>().currentUser?.uid;
      if (teacherId == null || teacherId.isEmpty) {
        throw StateError('Entre na conta do professor para gerenciar fichas.');
      }
      final students = await _searcher.streamLinkedUsers(teacherId).first;
      if (!mounted) return;
      students.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _instructorId = teacherId;
        _students = students;
        _loadingStudents = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        debugPrint('Erro ao carregar alunos da montagem: $error');
        _error = 'Não conseguimos carregar seus alunos agora. Tente novamente.';
        _loadingStudents = false;
      });
    }
  }

  Future<void> _openStudent(String studentId) async {
    final token = ++_selectionToken;
    setState(() {
      _studentId = studentId;
      _screen = _TelaProfessorTreinos.resumo;
      _loadingStudent = true;
      _error = null;
    });
    await _loadStudentDetails(studentId, token);
  }

  Future<void> _loadStudentDetails(String studentId, int token) async {
    try {
      // Apenas o aluno selecionado e consultado. Evita N+1 na lista.
      final active = await _service.getActivePlan(studentId);
      // Nao ressuscitar rascunhos antigos de versoes ja publicadas.
      // Uma edicao iniciada nesta sessao pode continuar na memoria ate publicar.
      final drafts = active == null
          ? await _service.getDraftsForStudent(
              studentId: studentId,
              instructorId: _instructorId!,
            )
          : <TrainingPlan>[];
      if (!mounted || token != _selectionToken) return;
      drafts.sort((a, b) => b.version.compareTo(a.version));
      setState(() {
        _published[studentId] = active;
        if (!_drafts.containsKey(studentId) && drafts.isNotEmpty) {
          _drafts[studentId] = TrainingPlanComposer.fromDraft(drafts.first);
        }
        _loadingStudent = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || token != _selectionToken) return;
      setState(() {
        _loadingStudent = false;
        debugPrint('Erro ao consultar fichas: $error');
        _error = 'Não conseguimos abrir as fichas deste aluno agora. Tente novamente.';
      });
    }
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_screen == _TelaProfessorTreinos.alunos) {
      if (widget.onVoltarInicio != null) {
        widget.onVoltarInicio!();
      } else {
        Navigator.maybePop(context);
      }
      return;
    }
    setState(() {
      if (_screen == _TelaProfessorTreinos.resumo) {
        _selectionToken++;
        _studentId = null;
        _screen = _TelaProfessorTreinos.alunos;
        _error = null;
      } else {
        _screen = _TelaProfessorTreinos.resumo;
      }
    });
  }

  TrainingPlanComposer _emptyDraft(String studentId) {
    final composer = TrainingPlanComposer(
      studentId: studentId,
      instructorId: _instructorId!,
      name: 'Ficha semanal',
    );
    composer.addRoutine(letter: 'A', name: 'Treino A');
    for (var day = 1; day <= 7; day++) {
      composer.assignDay(day, null);
    }
    return composer;
  }

  Future<void> _newDraft({bool fromPublished = false}) async {
    final studentId = _studentId;
    if (studentId == null || _saving) return;
    if (_drafts.containsKey(studentId)) {
      _openDraft();
      _notice('A ficha já está em edição. Continue as alterações.');
      return;
    }
    final active = _activePlan;
    final composer = fromPublished && active != null
        ? TrainingPlanComposer.fromDraft(active.copyWith(
            id: '',
            version: 1,
            status: TrainingPlanStatus.draft,
          ))
        : _emptyDraft(studentId);
    if (composer.routines.isEmpty) {
      composer.addRoutine(letter: 'A', name: 'Treino A');
    }
    if (fromPublished) {
      try {
        final ids = composer.routines
            .expand((routine) => routine.exercises)
            .map((exercise) => exercise.catalogExerciseId)
            .where((id) => id.startsWith('repdb-'));
        final entries = await _catalogService.findByIds(ids);
        if (!mounted || _studentId != studentId) return;
        for (final routine in composer.routines) {
          for (final exercise in routine.exercises) {
            final localized = entries[exercise.catalogExerciseId];
            if (localized == null || !localized.hasPortugueseName) continue;
            composer.updateExercise(routine.id, TrainingExercise(
              id: exercise.id,
              catalogExerciseId: exercise.catalogExerciseId,
              name: localized.name,
              muscleGroup: localized.muscleGroup,
              // Nome revisado nao implica que a instrucao foi traduzida.
              instructions: localized.language == 'pt-BR'
                  ? localized.instructions : exercise.instructions,
              imageUrl: exercise.imageUrl ?? localized.imageUrl,
              sets: exercise.sets,
              repetitions: exercise.repetitions,
              restSeconds: exercise.restSeconds,
              technique: exercise.technique,
              targetLoadKg: exercise.targetLoadKg,
            ));
          }
        }
      } catch (error) {
        if (!mounted) return;
        debugPrint('Erro ao atualizar nomes do catálogo: $error');
        _notice('A ficha abriu, mas não conseguimos atualizar os nomes dos exercícios.');
      }
    }
    if (!mounted) return;
    setState(() {
      _drafts[studentId] = composer;
      _selectedRoutineId = composer.routines.first.id;
      _validationMessage = null;
      _screen = _TelaProfessorTreinos.editor;
    });
  }

  void _openDraft() {
    final composer = _composer;
    if (composer == null) return;
    setState(() {
      _selectedRoutineId = composer.routines.isNotEmpty
          ? composer.routines.first.id : null;
      _validationMessage = null;
      _screen = _TelaProfessorTreinos.editor;
    });
  }

  void _openPublished() {
    final plan = _activePlan;
    if (plan == null) return;
    setState(() {
      _publishedRoutineId = plan.routines.isNotEmpty
          ? plan.routines.first.id : null;
      _screen = _TelaProfessorTreinos.fichaPublicada;
    });
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _persist({required bool publish}) async {
    final composer = _composer;
    final studentId = _studentId;
    if (_saving || composer == null || studentId == null) return;
    final draft = composer.buildDraft();
    if (publish) {
      try {
        draft.validateForPublication();
      } catch (error) {
        final message = 'Revise a ficha antes de publicar. ${_publicationHint(error)}';
        setState(() => _validationMessage = message);
        _notice(message);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Publicar ficha para o aluno?'),
          content: const Text(
            'A ficha ficará disponível no aplicativo do aluno. '
            'Depois de publicada, não poderá ser editada diretamente. '
            'Uma alteração exigirá uma nova versão.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar publicação'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }

    setState(() {
      _saving = true;
      _validationMessage = null;
    });
    try {
      var planId = draft.id;
      if (planId.isEmpty) {
        planId = await _service.createDraft(draft);
      } else {
        await _service.saveDraft(draft);
      }
      // Guarda o ID e a versao efetivamente gravados ANTES de publicar.
      // Se a publicacao falhar, podemos tentar novamente sem duplicar fichas.
      final saved = draft.copyWith(
        id: planId,
        version: draft.id.isEmpty ? 1 : draft.version + 1,
      );
      _drafts[studentId] = TrainingPlanComposer.fromDraft(saved);
      // Guarda a rotina na biblioteca pessoal, sem alterar a ficha do aluno.
      // Falha de um modelo nao impede salvar/publicar a prescricao.
      for (final routine in composer.routines) {
        await _saveTemplate(routine);
      }
      if (publish) {
        await _service.publishDraft(
          studentId: studentId,
          instructorId: _instructorId!,
          planId: planId,
        );
        _drafts.remove(studentId);
        if (!mounted) return;
        setState(() {
          _screen = _TelaProfessorTreinos.resumo;
          _loadingStudent = true;
        });
        await _loadStudentDetails(studentId, _selectionToken);
        _notice('Ficha publicada! O aluno já poderá consultar os treinos.');
      } else {
        _notice('Alterações salvas no Firebase.');
      }
    } catch (error) {
      debugPrint('Erro ao ${publish ? 'publicar' : 'salvar'} ficha: $error');
      _notice('Não conseguimos ${publish ? 'publicar' : 'salvar'} a ficha agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // A criacao abre o formulario com foto antes de inserir o treino na ficha.
  Future<void> _addRoutine(String letter) async {
    await _editRoutine(null, newLetter: letter);
  }

  Future<void> _saveTemplate(TrainingRoutine routine) async {
    final teacherId = _instructorId;
    final studentId = _studentId;
    if (teacherId == null || studentId == null) return;
    try {
      await _templateService.save(
        teacherId: teacherId,
        studentId: studentId,
        routine: routine,
      );
    } catch (error) {
      debugPrint('Erro ao salvar modelo de treino: $error');
      _notice('A ficha continua aqui, mas não conseguimos salvar o modelo reutilizável.');
    }
  }

  Future<String> _uploadPhoto(Uint8List bytes, String kind) async {
    final teacherId = _instructorId;
    if (teacherId == null || teacherId.isEmpty) {
      throw StateError('Não identificamos seu acesso. Entre novamente.');
    }
    return _mediaService.upload(
      bytes: bytes,
      teacherId: teacherId,
      kind: kind,
    );
  }

  Widget _exerciseImage(String? url, {double size = 48}) {
    if (url == null || !url.startsWith('https://')) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryChipSurface,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.fitness_center, color: AppColors.primary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size, height: size,
          alignment: Alignment.center,
          color: AppColors.primaryChipSurface,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.primary),
        ),
      ),
    );
  }

  void _addNextRoutine() {
    final composer = _composer;
    if (composer == null) return;
    for (final letter in 'FGHIJKL'.split('')) {
      if (!composer.routines.any((item) => item.letter == letter)) {
        _addRoutine(letter);
        return;
      }
    }
    _notice('Limite de treinos atingido.');
  }

  void _addExercise(ExerciseCatalogEntry item) {
    final composer = _composer;
    final routineId = _selectedRoutineId;
    if (composer == null || routineId == null) return;
    _newExerciseNumber++;
    composer.addExercise(
      routineId,
      TrainingExercise(
        id: 'item-${DateTime.now().microsecondsSinceEpoch}-$_newExerciseNumber',
        catalogExerciseId: item.id,
        name: item.name,
        muscleGroup: item.muscleGroup,
        instructions: StudentExercisePresentation.guidance('', item).text ?? '',
        imageUrl: item.imageUrl,
        sets: 3,
        repetitions: 12,
        restSeconds: 60,
      ),
    );
    setState(() {});
    _notice('${item.name} adicionado ao treino.');
  }

  Future<void> _addExerciseSheet() async {
    final search = TextEditingController();
    var query = '';
    var resultFuture = _catalogService.search();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18, right: 18, top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SizedBox(
            height: (MediaQuery.sizeOf(sheetContext).height -
                    MediaQuery.viewInsetsOf(sheetContext).bottom) * .70,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const BrandHeading('Adicionar exercício', level: BrandHeadingLevel.section),
              const SizedBox(height: 5),
              const Text('Escolha na biblioteca de exercícios com fotos. Se não encontrar, cadastre um novo.',
                style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 13),
              TextField(
                key: const Key('pesquisar-exercicio-ficha'),
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Buscar movimento ou grupo muscular',
                  prefixIcon: Icon(Icons.search), border: OutlineInputBorder(),
                ),
                onChanged: (text) => updateSheet(() {
                  query = text;
                  resultFuture = _catalogService.search(query: query);
                }),
              ),
              const SizedBox(height: 12),
              Expanded(child: FutureBuilder<List<ExerciseCatalogEntry>>(
                future: resultFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final fallback = _catalogoBase.where((item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.muscleGroup.toLowerCase().contains(query.toLowerCase()));
                  // Fonte persistida tem prioridade: nao esconder foto
                  // ilustrativa com o placeholder de fallback.
                  final items = <ExerciseCatalogEntry>[
                    ...(snapshot.data ?? const <ExerciseCatalogEntry>[]),
                  ];
                  final names = items.map((item) => item.name.toLowerCase()).toSet();
                  for (final item in fallback) {
                    if (names.add(item.name.toLowerCase())) items.add(item);
                  }
                  if (items.isEmpty) {
                    return Center(child: Text(snapshot.hasError
                      ? 'Não conseguimos abrir a biblioteca agora. Tente novamente.'
                      : 'Nenhum exercício encontrado. Cadastre um novo abaixo.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        key: Key('catalogo-${item.id}'),
                        leading: _exerciseImage(item.imageUrl, size: 48),
                        title: Text(item.name, maxLines: 2),
                        subtitle: Text(item.muscleGroup),
                        trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _addExercise(item);
                        },
                      );
                    },
                  );
                },
              )),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                key: const Key('adicionar-exercicio-manual'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _addManualWithImage();
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Cadastrar novo exercício'),
              ),
              const SizedBox(height: 5),
              const Text('Ilustracoes da biblioteca: RepDB (repdb.co)',
                style: TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
            ]),
          ),
        ),
      ),
    );
    search.dispose();
  }

  Future<void> _addManualWithImage() async {
    final manual = await showDialog<ExercicioCatalogoProfessorUi>(
      context: context,
      builder: (_) => CadastrarExercicioDialog(
        exercicioId: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        seletorImagem: SeletorImagemExercicioPadrao(),
      ),
    );
    if (!mounted || manual == null) return;
    try {
      String? imageUrl;
      if (manual.imagemBytes != null) {
        _notice('Enviando foto do exercício...');
        imageUrl = await _uploadPhoto(manual.imagemBytes!, 'exercicio');
      }
      final saved = await _catalogService.createCustom(
        teacherId: _instructorId!,
        name: manual.nome,
        muscleGroup: manual.grupoMuscular,
        instructions: manual.orientacoes,
        imageUrl: imageUrl,
      );
      if (mounted) {
        _addExercise(saved);
        _notice('Exercicio e foto salvos para reutilizar futuramente.');
      }
    } catch (error) {
      debugPrint('Erro ao salvar exercício: $error');
      _notice('Não conseguimos salvar o exercício agora. Tente novamente.');
    }
  }

  Future<void> _editExercise(TrainingExercise item, String routineId) async {
    // Nao apresentar o snapshot antigo em ingles como se fosse portugues.
    // Consultamos somente este ID, uma unica vez por abertura do editor.
    var ptInstructions = item.instructions.trim();
    var translationPending = false;
    if (ptInstructions.isEmpty || StudentExercisePresentation.looksEnglish(ptInstructions)) {
      ptInstructions = '';
      try {
        if (item.catalogExerciseId.trim().isNotEmpty) {
          final found = await _catalogService.findByIds([item.catalogExerciseId]);
          final guidance = StudentExercisePresentation.guidance(
            item.instructions, found[item.catalogExerciseId]);
          ptInstructions = guidance.text ?? '';
          translationPending = guidance.automaticTranslation;
        }
      } catch (_) {
        // Sem catalogo, o professor ainda pode escrever a orientacao manual.
      }
    }
    if (!mounted) return;
    final instructions = TextEditingController(text: ptInstructions);
    final sets = TextEditingController(text: '${item.sets}');
    final reps = TextEditingController(text: '${item.repetitions}');
    final rest = TextEditingController(text: '${item.restSeconds}');
    final load = TextEditingController(
      text: item.targetLoadKg == null
          ? ''
          : item.targetLoadKg.toString().replaceAll('.', ','),
    );
    Uint8List? selectedImageBytes;
    var technique = item.technique;
    String? errorText;
    const techniques = ['Tradicional', 'Rest-pause', 'Drop-set', 'Bi-set', 'Super-set'];
    if (!techniques.contains(technique)) technique = 'Tradicional';
    final updated = await showDialog<({TrainingExercise exercise, Uint8List? bytes})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.muscleGroup,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(
                    key: const Key('editar-series'),
                    controller: sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Séries'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    key: const Key('editar-repeticoes'),
                    controller: reps,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repetições'),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(
                    controller: rest,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Descanso (s)'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: load,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carga (kg)'),
                  )),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: technique,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Técnica'),
                  items: techniques.map((value) => DropdownMenuItem(
                    value: value, child: Text(value),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      updateDialog(() => technique = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Foto do exercício',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (selectedImageBytes != null)
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.memory(selectedImageBytes!, height: 100, fit: BoxFit.cover))
                else if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  _exerciseImage(item.imageUrl, size: 96),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final bytes = await SeletorImagemExercicioPadrao().selecionarDaGaleria();
                      if (bytes != null && dialogContext.mounted) {
                        updateDialog(() => selectedImageBytes = bytes);
                      }
                    } catch (error) {
                      debugPrint('Erro ao escolher foto do exercício: $error');
                      if (dialogContext.mounted) {
                        updateDialog(
                          () => errorText = 'Não conseguimos usar essa foto. Escolha outra.',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher foto da galeria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('editar-orientacoes-exercicio'),
                  controller: instructions,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Orientações em português',
                    hintText: 'Descreva o movimento em português antes de publicar.',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (translationPending) ...[
                  const SizedBox(height: 6),
                  const Text('Texto sugerido automaticamente. Revise antes de publicar.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(errorText!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirmar-edicao-exercicio'),
              onPressed: () {
                final nSets = int.tryParse(sets.text.trim());
                final nReps = int.tryParse(reps.text.trim());
                final nRest = int.tryParse(rest.text.trim());
                final rawLoad = load.text.trim().replaceAll(',', '.');
                final nLoad = rawLoad.isEmpty ? null : double.tryParse(rawLoad);
                if (nSets == null || nSets <= 0 ||
                    nReps == null || nReps <= 0 ||
                    nRest == null || nRest < 0 ||
                    (rawLoad.isNotEmpty && (nLoad == null || nLoad < 0))) {
                  updateDialog(() => errorText = 'Confira séries, repetições, descanso e carga.');
                  return;
                }
                Navigator.pop(dialogContext, (
                  bytes: selectedImageBytes,
                  exercise: TrainingExercise(
                  id: item.id,
                  catalogExerciseId: item.catalogExerciseId,
                  name: item.name,
                  muscleGroup: item.muscleGroup,
                  instructions: instructions.text.trim(),
                  imageUrl: item.imageUrl,
                  sets: nSets,
                  repetitions: nReps,
                  restSeconds: nRest,
                  technique: technique,
                  targetLoadKg: nLoad,
                )));
              },
              child: const Text('Salvar exercício'),
            ),
          ],
        ),
      ),
    );
    instructions.dispose();
    sets.dispose();
    reps.dispose();
    rest.dispose();
    load.dispose();
    if (!mounted || updated == null || _composer == null) return;
    var resolved = updated.exercise;
    if (updated.bytes != null) {
      try {
        _notice('Enviando foto do exercício...');
        final link = await _uploadPhoto(updated.bytes!, 'exercicio');
        resolved = TrainingExercise(
          id: resolved.id,
          catalogExerciseId: resolved.catalogExerciseId,
          name: resolved.name,
          muscleGroup: resolved.muscleGroup,
          instructions: resolved.instructions,
          imageUrl: link,
          sets: resolved.sets,
          repetitions: resolved.repetitions,
          restSeconds: resolved.restSeconds,
          technique: resolved.technique,
          targetLoadKg: resolved.targetLoadKg,
        );
      } catch (error) {
        debugPrint('Erro ao enviar foto do exercício: $error');
        _notice('Não conseguimos enviar a foto agora. Tente novamente.');
        return;
      }
    }
    if (!mounted || _composer == null) return;
    _composer!.updateExercise(routineId, resolved);
    setState(() {});
  }

  Future<void> _editRoutine(TrainingRoutine? routine, {String? newLetter}) async {
    final letter = routine?.letter ?? newLetter;
    if (letter == null || _composer == null) return;
    final name = TextEditingController(text: routine?.name ?? 'Treino $letter');
    final focus = TextEditingController(text: routine?.focus ?? '');
    final warmup = TextEditingController(text: routine?.warmupInstructions ?? '');
    final minutes = TextEditingController(text: '${routine?.estimatedMinutes ?? 45}');
    String? errorText;
    final result = await showDialog<({String name, String focus, String warmupInstructions, int minutes})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: Text(routine == null ? 'Criar Treino $letter' : 'Editar Treino $letter'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name,
                  decoration: const InputDecoration(labelText: 'Nome do treino')),
              TextField(controller: focus,
                  decoration: const InputDecoration(labelText: 'Foco (opcional)')),
              TextField(controller: minutes, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duracao prevista (min)')),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerLeft,
                child: Text('Aquecimento (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
              const SizedBox(height: 6),
              TextField(
                key: const Key('professor-aquecimento-treino'),
                controller: warmup,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Como aquecer antes deste treino?',
                  hintText: 'Ex.: 5 min de caminhada leve e mobilidade de quadril.',
                  helperText: 'Só aparece para o aluno após publicar a ficha.',
                  helperMaxLines: 2,
                ),
              ),
              if (errorText != null)
                Text(errorText!, style: const TextStyle(color: AppColors.danger)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final duration = int.tryParse(minutes.text.trim());
                if (name.text.trim().isEmpty || duration == null || duration < 0) {
                  updateDialog(() => errorText = 'Preencha nome e duração válidos.');
                  return;
                }
                Navigator.pop(dialogContext, (
                  name: name.text.trim(),
                  focus: focus.text.trim(),
                  warmupInstructions: warmup.text.trim(),
                  minutes: duration,
                ));
              },
              child: Text(routine == null ? 'Criar treino' : 'Salvar treino'),
            ),
          ],
        ),
      ),
    );
    name.dispose(); focus.dispose(); warmup.dispose(); minutes.dispose();
    if (result == null || !mounted || _composer == null) return;
    // Foto de capa de rotina descontinuada na v11.
    // O campo legado permanece no modelo para compatibilidade de fichas antigas.
    if (!mounted || _composer == null) return;
    if (routine == null) {
      final id = _composer!.addRoutine(
        letter: letter,
        name: result.name,
        focus: result.focus,
        warmupInstructions: result.warmupInstructions,
        estimatedMinutes: result.minutes,
      );
      setState(() => _selectedRoutineId = id);
      // O treino novo fica disponivel como modelo reutilizavel desde a criacao.
      await _saveTemplate(_composer!.routine(id));
    } else {
      _composer!.updateRoutine(
        routineId: routine.id,
        name: result.name,
        focus: result.focus,
        warmupInstructions: result.warmupInstructions,
        estimatedMinutes: result.minutes,
      );
      setState(() {});
    }
  }

  Future<void> _deleteExercise(TrainingExercise item, TrainingRoutine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover exercício?'),
        content: Text('${item.name} será removido desta edição. Para atualizar a ficha do aluno, publique a nova versão.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (!mounted || confirmed != true || _composer == null) return;
    _composer!.removeExercise(routine.id, item.id);
    setState(() {});
  }

  Future<void> _deleteRoutine(TrainingRoutine routine) async {
    final composer = _composer;
    if (composer == null || composer.routines.length <= 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover Treino ${routine.letter}?'),
        content: const Text(
          'O treino será removido da edição. A ficha do aluno só mudará depois que você tocar em Publicar ficha.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover treino')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    composer.removeRoutine(routine.id);
    setState(() => _selectedRoutineId = composer.routines.first.id);
    _notice('Treino removido da edição. Publique a ficha para atualizar o aluno.');
  }

  Future<void> _deleteEntireSheet() async {
    final studentId = _studentId;
    final instructorId = _instructorId;
    if (_saving || studentId == null || instructorId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ficha completa?'),
        content: const Text(
          'O aluno ficará sem ficha ativa. As alterações não publicadas '
          'também serão descartadas. Os treinos já realizados e as '
          'versões publicadas anteriormente permanecerão no histórico '
          'para preservar os registros.\n\nDeseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-excluir-ficha'),
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir ficha'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    setState(() => _saving = true);
    try {
      await _service.removeStudentSheet(
        studentId: studentId,
        instructorId: instructorId,
      );
      if (!mounted) return;
      _drafts.remove(studentId);
      _published.remove(studentId);
      setState(() {
        _screen = _TelaProfessorTreinos.resumo;
        _publishedRoutineId = null;
        _selectedRoutineId = null;
        _validationMessage = null;
        _loadingStudent = true;
      });
      await _loadStudentDetails(studentId, _selectionToken);
      _notice('Ficha retirada do aluno. Histórico preservado.');
    } catch (error) {
      debugPrint('Erro ao excluir ficha: $error');
      _notice('Não conseguimos excluir a ficha agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openHistory() {
    final student = _student;
    if (student == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ProfessorHistoricoAlunoView(
        studentId: student.id,
        studentName: student.name,
        service: _sessionService,
      ),
    ));
  }

  // --------------------------- Apresentacao ----------------------------

  TextStyle _titleStyle(double size) => GoogleFonts.barlowCondensed(
    fontWeight: FontWeight.w800,
    fontSize: size,
    color: AppColors.textPrimary,
  );

  // Material fornece a superficie para ListTile/InkWell pintar os efeitos
  // de toque sem serem ocultados pela decoracao do cartao.
  Widget _panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) =>
      Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );

  /// O que falta na ficha, sem mostrar o erro técnico da validação.
  static String _publicationHint(Object error) {
    final text = error is StateError ? error.message.toString() : '';
    if (text.contains('programacao semanal')) {
      return 'Defina em quais dias o aluno treina.';
    }
    return 'Confira se cada treino tem nome e pelo menos um exercício.';
  }

  Widget _heading(String title, {String? description, VoidCallback? onBack}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null) ...[
              IconButton.filledTonal(
                tooltip: 'Voltar',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandHeading(title),
                  if (description != null)
                    Text(description, style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tag(String text, {Color background = AppColors.primaryChipSurface,
      Color foreground = AppColors.primary}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: TextStyle(fontSize: AppFontSize.caption,
        fontWeight: FontWeight.w700, color: foreground)),
  );

  Widget _studentsList() {
    final filtered = _students.where((student) =>
        student.name.toLowerCase().contains(_searchText.toLowerCase().trim())).toList();
    return ListView(
      key: const Key('professor_lista_alunos_treinos'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _heading('Meus alunos',
            description: 'Selecione um aluno vinculado para visualizar ou montar a ficha.'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('atualizar-alunos-treinos'),
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Atualizar lista'),
          ),
        ),
        TextField(
          key: const Key('pesquisar_aluno_treinos'),
          onChanged: (text) => setState(() => _searchText = text),
          decoration: InputDecoration(
            hintText: 'Buscar aluno...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        const SizedBox(height: 18),
        Text('${filtered.length} aluno(s)', style: const TextStyle(
          color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          _panel(child: const Text('Nenhum aluno encontrado.')),
        for (final student in filtered) ...[
          _panel(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: Key('professor_aluno_${student.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              leading: UserAvatar(
                key: Key('foto_aluno_${student.id}'),
                photoUrl: student.photoUrl,
                size: 40,
                backgroundColor: AppColors.avatarBackground,
                iconColor: AppColors.primary,
              ),
              title: Text(student.name, style: const TextStyle(
                  fontSize: AppFontSize.small, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              subtitle: const Text('Ver ficha e treinos', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
              onTap: () => _openStudent(student.id),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _studentSummary() {
    final student = _student;
    if (student == null) return const SizedBox.shrink();
    final published = _activePlan;
    final draft = _composer;
    return ListView(
      key: const Key('professor_resumo_aluno'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _heading(student.name,
            description: 'Treinos e acompanhamento do aluno', onBack: _back),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('atualizar-ficha-aluno'),
            onPressed: _loadingStudent ? null : () {
              setState(() => _loadingStudent = true);
              _loadStudentDetails(student.id, _selectionToken);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Atualizar'),
          ),
        ),
        if (_loadingStudent) const Padding(
          padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
        else if (_error != null) ...[
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () {
              setState(() => _loadingStudent = true);
              _loadStudentDetails(student.id, _selectionToken);
            }, child: const Text('Tentar novamente')),
          ])),
        ] else ...[
          if (published != null)
            _panel(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text('Ficha atual', style: _titleStyle(AppFontSize.subtitle))),
                  _tag('Publicada'),
                ]),
                const SizedBox(height: 8),
                Text(published.name, style: const TextStyle(
                    fontSize: AppFontSize.body, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('${published.routines.length} treino(s) • '
                    '${published.weeklySchedule.values.where((id) => id != null).length} dia(s) programados',
                    style: const TextStyle(color: AppColors.textBody)),
                if (draft != null) ...[
                  const SizedBox(height: 8),
                  const Text('Há alterações ainda não publicadas.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
                ],
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  key: const Key('professor_ver_ficha_atual'),
                  onPressed: _openPublished,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver ficha atual'),
                )),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  key: const Key('revisar-ficha-publicada'),
                  onPressed: draft == null
                      ? () => _newDraft(fromPublished: true)
                      : _openDraft,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar ficha'),
                )),
              ],
            ))
          else
            _panel(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft == null ? 'Nenhuma ficha publicada' : 'Ficha em montagem',
                    style: _titleStyle(AppFontSize.subtitle)),
                const SizedBox(height: 8),
                Text(draft == null
                    ? 'Este aluno ainda não tem uma ficha ativa.'
                    : 'Continue a montagem e publique quando estiver pronta.',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  key: Key(draft == null ? 'criar-ficha-aluno' : 'continuar-rascunho'),
                  onPressed: draft == null ? () => _newDraft() : _openDraft,
                  icon: Icon(draft == null ? Icons.add : Icons.edit_outlined),
                  label: Text(draft == null ? 'Criar ficha' : 'Continuar montagem'),
                )),
              ],
            )),
          if (published != null || draft != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const Key('excluir-ficha-completa'),
              onPressed: _saving ? null : _deleteEntireSheet,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Excluir ficha completa'),
            ),
          ],
          const SizedBox(height: 14),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Treinar em casa', style: _titleStyle(AppFontSize.subtitle)),
            const SizedBox(height: 5),
            const Text('Opcional: publique exercícios para este aluno fazer em casa. '
                'Se não houver prescrição, nada aparecerá para ele.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              key: const Key('professor_gerenciar_treino_casa'),
              onPressed: _saving ? null : () async {
                final teacherId = _instructorId;
                if (teacherId == null) return;
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ProfessorTreinoEmCasaView(
                    studentId: student.id,
                    studentName: student.name,
                    instructorId: teacherId,
                    service: HomeWorkoutService(db: _service.firestore),
                    catalogService: _catalogService,
                  ),
                ));
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Criar ou editar treinos em casa'),
            )),
          ])),
          const SizedBox(height: 16),
          ProfessorResumoTreinosAluno(
            key: ValueKey('professor_status_${student.id}'),
            studentId: student.id,
            service: _sessionService,
            onHistorico: _openHistory,
          ),
        ],
      ],
    );
  }

  Widget _routineSelector(List<TrainingRoutine> routines, String? selectedId, {
    required void Function(String letter, String? id) onSelected,
    bool allowAdd = false,
  }) {
    final letters = <String>{'A', 'B', 'C', 'D', 'E'};
    for (final routine in routines) {
      letters.add(routine.letter);
    }
    return Wrap(
      spacing: 7,
      runSpacing: 8,
      children: [
        for (final letter in letters)
          Builder(builder: (_) {
            TrainingRoutine? existing;
            for (final routine in routines) {
              if (routine.letter == letter) existing = routine;
            }
            final isSelected = existing?.id == selectedId;
            return ChoiceChip(
              key: Key('treino-$letter'),
              selected: isSelected,
              label: Text(existing == null ? '+ $letter' : letter),
              tooltip: existing == null ? 'Criar Treino $letter' : 'Abrir Treino $letter',
              onSelected: existing != null || allowAdd
                  ? (_) => onSelected(letter, existing?.id)
                  : null,
              selectedColor: AppColors.primaryChipSurface,
              labelStyle: TextStyle(fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary),
              side: BorderSide(color: isSelected
                  ? AppColors.primary : AppColors.border),
              showCheckmark: false,
            );
          }),
        if (allowAdd && routines.length >= 5 && routines.length < 12)
          ActionChip(
            key: const Key('adicionar-treino'),
            label: const Text('+ Outro'),
            onPressed: _addNextRoutine,
          ),
      ],
    );
  }

  Widget _publishedDetails() {
    final plan = _activePlan;
    if (plan == null) return const SizedBox.shrink();
    TrainingRoutine? selected;
    for (final routine in plan.routines) {
      if (routine.id == _publishedRoutineId) selected = routine;
    }
    if (selected == null && plan.routines.isNotEmpty) selected = plan.routines.first;
    return ListView(
      key: const Key('professor_ficha_publicada'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _heading('Ficha atual', description: _student?.name, onBack: _back),
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(plan.name, style: _titleStyle(AppFontSize.title))),
            _tag('Publicada'),
          ]),
          const SizedBox(height: 8),
          const Text('Esta é a ficha que o aluno utiliza. Ela não pode ser alterada diretamente.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          _routineSelector(plan.routines, selected?.id,
              onSelected: (_, id) => setState(() => _publishedRoutineId = id)),
        ])),
        if (selected != null) ...[
          const SizedBox(height: 12),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selected.name, style: _titleStyle(AppFontSize.title)),
            if (selected.focus.isNotEmpty)
              Text(selected.focus, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('${selected.exercises.length} exercícios • ${selected.estimatedMinutes} min estimados',
                style: const TextStyle(color: AppColors.textBody)),
            const SizedBox(height: 14),
            for (var i = 0; i < selected.exercises.length; i++) ...[
              _exerciseItem(selected.exercises[i], i + 1),
              if (i < selected.exercises.length - 1) const Divider(height: 1),
            ],
          ])),
        ],
        const SizedBox(height: 12),
        _weeklyCard(plan.routines, plan.weeklySchedule, editable: false),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('editar-ficha-atual'),
          onPressed: _composer == null
              ? () => _newDraft(fromPublished: true)
              : _openDraft,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar ficha'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          key: const Key('excluir-ficha-na-visualizacao'),
          onPressed: _saving ? null : _deleteEntireSheet,
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Excluir ficha completa'),
        ),
      ],
    );
  }

  Widget _exerciseItem(TrainingExercise item, int index, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    Widget? dragHandle,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primaryChipSurface,
            borderRadius: BorderRadius.circular(9)),
        child: Text('$index', style: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 8),
      // Tocar na foto ou no nome abre os detalhes do exercício (GB-014).
      Expanded(child: InkWell(
        key: Key('card_detalhes_exercicio_${item.id}'),
        borderRadius: BorderRadius.circular(9),
        onTap: () => showExerciseDetailsSheet(
          context,
          name: item.name,
          muscleGroup: item.muscleGroup,
          instructions: item.instructions,
          imageUrl: item.imageUrl,
        ),
        child: Row(children: [
          _exerciseImage(item.imageUrl, size: 43),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700)),
            Text('${item.sets} séries • ${item.repetitions} reps • ${item.restSeconds}s',
                style: const TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
            if (item.targetLoadKg != null)
              Text('Carga sugerida: ${item.targetLoadKg} kg', style: const TextStyle(
                  fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
          ])),
        ]),
      )),
      if (onEdit != null)
        IconButton(
          key: Key('editar-exercicio-${item.id}'),
          onPressed: onEdit, tooltip: 'Editar exercício',
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
        ),
      if (onDelete != null)
        IconButton(onPressed: onDelete, tooltip: 'Remover exercício',
            icon: const Icon(Icons.close, color: AppColors.textSecondary)),
      if (dragHandle != null) dragHandle,
    ]),
  );

  Widget _weeklyCard(List<TrainingRoutine> routines, Map<int, String?> schedule, {
    required bool editable,
  }) => _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const BrandHeading('Programação', complement: 'Semanal', level: BrandHeadingLevel.section),
    const SizedBox(height: 5),
    Text(editable
        ? 'Escolha qual treino o aluno fará em cada dia.'
        : 'Dias programados para o aluno.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
    const SizedBox(height: 12),
    for (var day = 1; day <= 7; day++) ...[
      Row(children: [
        SizedBox(width: 83, child: Text(_dias[day - 1],
            style: const TextStyle(color: AppColors.textBody))),
        Expanded(child: editable
            ? DropdownButtonFormField<String>(
                key: ValueKey('dia-$day-${schedule[day]}'),
                initialValue: schedule[day] ?? 'descanso',
                isExpanded: true,
                decoration: const InputDecoration(isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: 'descanso', child: Text('Descanso')),
                  ...routines.map((r) => DropdownMenuItem(value: r.id,
                      child: Text('Treino ${r.letter}'))),
                ],
                onChanged: _saving ? null : (id) {
                  _composer!.assignDay(day, id == 'descanso' ? null : id);
                  setState(() {});
                },
              )
            : Text(
                schedule[day] == null
                    ? 'Descanso'
                    : _routineLabel(routines, schedule[day]!),
                style: const TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              )),
      ]),
      if (day < 7) const SizedBox(height: 9),
    ],
  ]));

  String _routineLabel(List<TrainingRoutine> routines, String routineId) {
    for (final routine in routines) {
      if (routine.id == routineId) return 'Treino ${routine.letter}';
    }
    return 'Treino não encontrado';
  }

  Widget _editor() {
    final composer = _composer;
    if (composer == null) return const SizedBox.shrink();
    final routine = _editingRoutine;
    return ListView(
      key: const Key('professor_editor_ficha'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _heading('Montar ficha',
          description: 'Aluno: ${_student?.name ?? ''}', onBack: _back),
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('1. Identificação da ficha', style: _titleStyle(AppFontSize.subtitle)),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('nome-ficha-$_studentId'),
            initialValue: composer.name,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Nome ou objetivo da ficha',
                border: OutlineInputBorder()),
            onChanged: (text) => composer.name = text,
          ),
          const SizedBox(height: 8),
          const Text('Os treinos A/B/C/D/E fazem parte da mesma ficha semanal.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
        ])),
        const SizedBox(height: 12),
        if (_activePlan != null) ...[
          _panel(child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text(
              'Você está editando uma nova versão. O aluno ainda vê a ficha antiga. '
              'Para aplicar alterações ou remoções, toque em Publicar ficha.',
              style: TextStyle(color: AppColors.textBody, fontSize: AppFontSize.caption),
            )),
          ])),
          const SizedBox(height: 12),
        ],
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('2. Escolha o treino', style: _titleStyle(AppFontSize.subtitle)),
          const SizedBox(height: 10),
          _routineSelector(composer.routines, routine?.id,
              allowAdd: !_saving,
              onSelected: (letter, id) {
                if (id == null) {
                  _addRoutine(letter);
                } else {
                  setState(() => _selectedRoutineId = id);
                }
              }),
          const SizedBox(height: 9),
          const Text('Toque na letra para abrir, criar ou configurar o aquecimento de um treino.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.caption)),
        ])),
        if (routine != null) ...[
          const SizedBox(height: 12),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(routine.name, style: _titleStyle(AppFontSize.title)),
                if (routine.focus.isNotEmpty)
                  Text(routine.focus, style: const TextStyle(
                      color: AppColors.textSecondary)),
                Text('${routine.estimatedMinutes} min estimados',
                    style: const TextStyle(fontSize: AppFontSize.caption,
                        color: AppColors.textSecondary)),
                if (routine.warmupInstructions.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const Text('Aquecimento prescrito',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 3),
                  Text(routine.warmupInstructions,
                    style: const TextStyle(color: AppColors.textBody, fontSize: AppFontSize.caption)),
                ],
              ])),
              IconButton(
                key: const Key('editar-dados-treino'),
                tooltip: 'Editar treino e aquecimento',
                onPressed: _saving ? null : () => _editRoutine(routine),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
            ]),
            const Divider(height: 22),
            Row(children: [
              Expanded(child: Text('3. Exercícios do Treino ${routine.letter}',
                  style: _titleStyle(AppFontSize.subtitle))),
              _tag('${routine.exercises.length} itens'),
            ]),
            const SizedBox(height: 10),
            if (routine.exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Nenhum exercício ainda. Adicione um da biblioteca para começar.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: routine.exercises.length,
                // O Flutter ja ajusta newIndex ao mover um item para baixo.
                onReorderItem: (oldIndex, newIndex) {
                  if (_saving) {
                    return;
                  }
                  composer.moveExercise(routine.id, oldIndex, newIndex);
                  setState(() {});
                },
                itemBuilder: (_, index) {
                  final exercise = routine.exercises[index];
                  return Container(
                    key: ValueKey(exercise.id),
                    decoration: BoxDecoration(
                      border: Border(bottom: index == routine.exercises.length - 1
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.border)),
                    ),
                    child: _exerciseItem(exercise, index + 1,
                      onEdit: _saving ? null : () => _editExercise(exercise, routine.id),
                      onDelete: _saving ? null : () => _deleteExercise(exercise, routine),
                      dragHandle: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                          child: Icon(Icons.drag_indicator,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              key: const Key('abrir-catalogo-exercicios'),
              onPressed: _saving ? null : _addExerciseSheet,
              icon: const Icon(Icons.add),
              label: Text('Adicionar exercício ao Treino ${routine.letter}'),
            )),
            if (composer.routines.length > 1) ...[
              const SizedBox(height: 5),
              Align(alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving ? null : () => _deleteRoutine(routine),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Remover Treino ${routine.letter}'),
                )),
            ],
          ])),
        ],
        const SizedBox(height: 12),
        _weeklyCard(composer.routines, composer.weeklySchedule, editable: true),
        const SizedBox(height: 16),
        if (_validationMessage != null) ...[
          _panel(child: Semantics(
            liveRegion: true,
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(_validationMessage!,
                style: const TextStyle(color: AppColors.danger))),
            ]),
          )),
          const SizedBox(height: 12),
        ],
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('publicar-ficha-aluno'),
              onPressed: () => _persist(publish: true),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Publicar ficha para o aluno'),
            ),
          ),
        const SizedBox(height: 8),
        const Text('As alterações substituem a ficha do aluno somente depois de publicar. A versão anterior fica preservada no histórico.',
            textAlign: TextAlign.center, style: TextStyle(
                fontSize: AppFontSize.caption, color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Grazi Braz', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : (_screen == _TelaProfessorTreinos.alunos)
                  ? (_students.isEmpty && _error != null)
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(_error!, textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger)),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _loadStudents,
                                child: const Text('Tentar novamente')),
                          ]),
                        ))
                      : (_students.isEmpty)
                          ? Center(child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('Você não possui alunos vinculados.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                OutlinedButton(onPressed: _loadStudents,
                                    child: const Text('Atualizar lista')),
                              ]),
                            ))
                          : _studentsList()
                  : _screen == _TelaProfessorTreinos.resumo
                      ? _studentSummary()
                      : _screen == _TelaProfessorTreinos.fichaPublicada
                          ? _publishedDetails()
                          : _editor(),
        ),
      ),
    );
  }
}
