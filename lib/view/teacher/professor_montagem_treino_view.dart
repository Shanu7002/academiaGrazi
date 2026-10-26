import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/view/components/app_bar.dart';
import 'package:academiagrazi/view/teacher/ui_data/montagem_treino_ui_data.dart';
import 'package:academiagrazi/view/teacher/ui_models/montagem_treino_ui_models.dart';
import 'package:academiagrazi/view/teacher/widgets/exercicio_montagem_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';

class ProfessorMontagemTreinoView extends StatefulWidget {
  final VoidCallback? onVoltarInicio;

  const ProfessorMontagemTreinoView({super.key, this.onVoltarInicio});

  @override
  State<ProfessorMontagemTreinoView> createState() =>
      _ProfessorMontagemTreinoViewState();
}

class _ProfessorMontagemTreinoViewState
    extends State<ProfessorMontagemTreinoView> {
  final FirebaseAuth _authInstance = locator<FirebaseAuth>();
  bool _isLoading = true;
  MontagemTreinoProfessorUiData? _data;

  late final List<ExercicioCatalogoProfessorUi> _catalogo;
  late List<ExercicioMontadoProfessorUi> _exercicios;
  late String _alunoId;
  late String _nomeTreino;
  String _busca = '';
  String? _grupoFiltrado;
  int _proximoNumero = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final teacherUID = _authInstance.currentUser!.uid;
      final searcher = locator<TeacherUserSearcher>();

      final usersFirestore = await searcher.streamLinkedUsers(teacherUID).first;

      if (usersFirestore.isEmpty && mounted) {
        _mostrarAviso('Nenhum aluno vinculado encontrado.');
      }

      final alunosReais =
          usersFirestore.map((u) {
            return AlunoResumoProfessorUi(id: u.id, nome: u.name);
          }).toList();

      final fetchedData = MontagemTreinoProfessorUiData(
        nomeTreino: 'Nova Série',
        alunoSelecionadoId: alunosReais.isNotEmpty ? alunosReais.first.id : '',
        alunos: alunosReais,
        catalogo: [
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
        ],
        exerciciosIniciais: [],
        dicaExecucao: 'Mantenha a postura e foque na contração.',
        duracaoEstimadaMinutos: 45,
        volume: 'Médio',
      );

      if (!mounted) return;

      setState(() {
        _data = fetchedData;
        _catalogo = List.of(fetchedData.catalogo);
        _exercicios = List.of(fetchedData.exerciciosIniciais);
        _alunoId = fetchedData.alunoSelecionadoId;
        _nomeTreino = fetchedData.nomeTreino;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar dados do Firebase: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarAviso('Erro de conexão ao carregar os dados.');
      }
    }
  }

  AlunoResumoProfessorUi get _alunoAtual => _data!.alunos.firstWhere(
    (a) => a.id == _alunoId,
    orElse:
        () =>
            _data!.alunos.isNotEmpty
                ? _data!.alunos.first
                : AlunoResumoProfessorUi(id: '', nome: 'Sem Aluno'),
  );

  ExercicioCatalogoProfessorUi _encontrarExercicio(String id) =>
      _catalogo.firstWhere((e) => e.id == id);

  void _adicionar(ExercicioCatalogoProfessorUi exercicio) {
    setState(() {
      _proximoNumero++;
      _exercicios.add(
        ExercicioMontadoProfessorUi(
          itemId: 'novo-$_proximoNumero',
          exercicioId: exercicio.id,
          series: 3,
          repeticoes: 12,
          descansoSegundos: 60,
          tecnica: 'Tradicional',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${exercicio.nome} adicionado ao treino.')),
    );
  }

  void _atualizar(ExercicioMontadoProfessorUi alterado) {
    setState(() {
      final indice = _exercicios.indexWhere((e) => e.itemId == alterado.itemId);
      if (indice >= 0) _exercicios[indice] = alterado;
    });
  }

  void _remover(String itemId) {
    setState(() => _exercicios.removeWhere((e) => e.itemId == itemId));
  }

  void _reordenar(int antigo, int novo) {
    setState(() {
      final item = _exercicios.removeAt(antigo);
      _exercicios.insert(novo, item);
    });
  }

  Future<void> _adicionarManual() async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Adicionar exercício manual'),
            content: TextField(
              key: const Key('nome_exercicio_manual'),
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do exercício',
                hintText: 'Ex.: Elevação lateral',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Adicionar'),
              ),
            ],
          ),
    );
    controller.dispose();

    if (!mounted || nome == null || nome.isEmpty) return;
    _proximoNumero++;
    final exercicio = ExercicioCatalogoProfessorUi(
      id: 'manual-$_proximoNumero',
      nome: nome,
      grupoMuscular: 'Exercício manual',
    );
    _catalogo.add(exercicio);
    _adicionar(exercicio);
  }

  Future<void> _editarNomeTreino() async {
    final controller = TextEditingController(text: _nomeTreino);
    final novoNome = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Nome da série'),
            content: TextField(
              key: const Key('nome_treino'),
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Ex.: Treino A'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (!mounted || novoNome == null || novoNome.isEmpty) return;
    setState(() => _nomeTreino = novoNome);
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _salvarModelo() {
    _mostrarAviso(
      'Prévia do modelo pronta. O salvamento no Firebase ainda não foi implementado.',
    );
  }

  Future<void> _atribuirAoAluno() async {
    if (_exercicios.isEmpty) {
      _mostrarAviso('Adicione pelo menos um exercício para atribuir o treino.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Conferência de atribuição'),
            content: Text(
              'Aluno: ${_alunoAtual.nome}\n'
              'Série: $_nomeTreino\n'
              'Exercícios: ${_exercicios.length}\n\n'
              'Esta é uma prévia. Nenhum treino será salvo ou atribuído no Firebase nesta etapa.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'GRAZI BRAZ'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _data == null || _data!.alunos.isEmpty
              ? _estadoVazio()
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    children: [
                      _cabecalho(),
                      const SizedBox(height: 14),
                      _acoesPrincipais(),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 22),
                      _buscaCatalogo(),
                      const SizedBox(height: 16),
                      _serieAtual(),
                      const SizedBox(height: 24),
                      _cardInteligenciaArtificial(),
                      const SizedBox(height: 18),
                      _indicadores(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: AppColors.textBody),
          const SizedBox(height: 16),
          const Text(
            'Você não possui alunos vinculados.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              if (widget.onVoltarInicio != null) {
                widget.onVoltarInicio!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          key: const Key('voltar_ao_dashboard'),
          tooltip: 'Voltar',
          onPressed: () {
            if (widget.onVoltarInicio != null) {
              widget.onVoltarInicio!();
            } else {
              Navigator.maybePop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Montagem de Treino',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('selecionar_aluno'),
                tooltip: 'Escolher aluno',
                onSelected: (id) => setState(() => _alunoId = id),
                itemBuilder:
                    (_) =>
                        _data!.alunos
                            .map(
                              (aluno) => PopupMenuItem<String>(
                                value: aluno.id,
                                child: Text(aluno.nome),
                              ),
                            )
                            .toList(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Editando: ${_alunoAtual.nome}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _acoesPrincipais() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('salvar_como_modelo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _salvarModelo,
            icon: const Icon(Icons.save_outlined, size: 17),
            label: const Text(
              'Salvar como\nmodelo',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            key: const Key('atribuir_ao_aluno'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _atribuirAoAluno,
            icon: const Icon(Icons.send_outlined, size: 17),
            label: const Text(
              'Atribuir ao\naluno',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  List<ExercicioCatalogoProfessorUi> get _sugestoes {
    final filtro = _busca.trim().toLowerCase();
    final base = _catalogo.where((exercicio) {
      final porTexto =
          filtro.isEmpty ||
          exercicio.nome.toLowerCase().contains(filtro) ||
          exercicio.grupoMuscular.toLowerCase().contains(filtro);
      final porGrupo =
          _grupoFiltrado == null ||
          exercicio.grupoMuscular.contains(_grupoFiltrado!);
      return porTexto && porGrupo;
    });
    return (filtro.isEmpty ? base.take(2) : base).toList();
  }

  Widget _buscaCatalogo() {
    final grupos =
        _catalogo.map((exercicio) => exercicio.grupoMuscular).toSet().toList();
    return _cartao(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('pesquisar_exercicio'),
            onChanged: (value) => setState(() => _busca = value),
            decoration: InputDecoration(
              hintText: 'Pesquisar exercício',
              prefixIcon: const Icon(Icons.search, color: AppColors.textBody),
              suffixIcon: PopupMenuButton<String>(
                tooltip: 'Filtrar grupo muscular',
                icon: const Icon(Icons.tune, color: AppColors.textBody),
                onSelected:
                    (grupo) => setState(
                      () =>
                          _grupoFiltrado = grupo == "__todos__" ? null : grupo,
                    ),
                itemBuilder:
                    (_) => [
                      const PopupMenuItem<String>(
                        value: "__todos__",
                        child: Text('Todos os grupos'),
                      ),
                      ...grupos.map(
                        (grupo) => PopupMenuItem<String>(
                          value: grupo,
                          child: Text(grupo),
                        ),
                      ),
                    ],
              ),
              filled: true,
              fillColor: AppColors.trainingListBackground,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_sugestoes.isEmpty)
            const Text(
              'Nenhum exercício encontrado.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _sugestoes.map((exercicio) {
                    return ActionChip(
                      key: Key('catalogo-${exercicio.id}'),
                      label: Text('${exercicio.nome} +'),
                      backgroundColor: AppColors.primaryChipSurface,
                      side: BorderSide.none,
                      onPressed: () => _adicionar(exercicio),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _serieAtual() {
    return _cartao(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('editar_nome_treino'),
                  onTap: _editarNomeTreino,
                  child: Text(
                    'Série Atual – $_nomeTreino',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Arraste para\nreordenar',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textBody,
                ),
              ),
              const Icon(
                Icons.drag_indicator,
                size: 20,
                color: AppColors.textBody,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          if (_exercicios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Adicione exercícios para começar a montar a série.'),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _exercicios.length,
              onReorderItem: _reordenar,
              itemBuilder: (context, index) {
                final item = _exercicios[index];
                return Padding(
                  key: ValueKey(item.itemId),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExercicioMontagemCard(
                    index: index,
                    item: item,
                    exercicio: _encontrarExercicio(item.exercicioId),
                    onChanged: _atualizar,
                    onRemove: () => _remover(item.itemId),
                  ),
                );
              },
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('adicionar_exercicio_manual'),
              onPressed: _adicionarManual,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.completedBorder,
                  width: 1.5,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Exercício Manual'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInteligenciaArtificial() {
    return _cartao(
      Opacity(
        opacity: 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sugestão com IA',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  color: AppColors.infoSurface,
                  child: const Text(
                    'RECURSO FUTURO',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'No futuro, sugestões poderão considerar o histórico do aluno e a recuperação muscular.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Em breve'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicadores() {
    return Row(
      children: [
        Expanded(
          child: _indicador(
            Icons.timer_outlined,
            '${_data!.duracaoEstimadaMinutos} min',
            'Est. Duração',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _indicador(
            Icons.local_fire_department_outlined,
            _data!.volume,
            'Volume',
          ),
        ),
      ],
    );
  }

  Widget _indicador(IconData icone, String titulo, String subtitulo) {
    return _cartao(
      Column(
        children: [
          Icon(icone, color: AppColors.accent, size: 26),
          const SizedBox(height: 6),
          Text(
            titulo,
            style: GoogleFonts.barlowCondensed(
              fontSize: 21,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: AppColors.textBody),
          ),
        ],
      ),
    );
  }

  Widget _cartao(Widget filho) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: filho,
    );
  }
}
