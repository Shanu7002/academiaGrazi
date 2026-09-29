import 'package:academiagrazi/view/user/aluno_exercicio_detalhe_view.dart';
import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoTreinoDiaView extends StatefulWidget {
  final TreinoUi treino;

  const AlunoTreinoDiaView({
    super.key,
    required this.treino,
  });

  @override
  State<AlunoTreinoDiaView> createState() => _AlunoTreinoDiaViewState();
}

class _AlunoTreinoDiaViewState extends State<AlunoTreinoDiaView> {
  static const Color _background = Color(0xFFF4F7FA);
  static const Color _verde = Color(0xFF005A4F);
  static const Color _verdeEscuro = Color(0xFF003D36);
  static const Color _laranja = Color(0xFFFF7943);
  static const Color _azulEscuro = Color(0xFF092837);
  static const Color _cinzaTexto = Color(0xFF64748B);
  static const Color _cinzaBorda = Color(0xFFE2E8F0);
  static const Color _cinzaClaro = Color(0xFFF8FAFC);

  final Set<String> _concluidos = <String>{};
  bool _aquecimentoConcluido = false;

  @override
  void initState() {
    super.initState();

    // Estado temporário para reproduzir o protótipo do Figma.
    // Depois o progresso virá do backend/Firebase.
    final quantidadeInicial = widget.treino.exercicios.length >= 2
        ? 2
        : widget.treino.exercicios.length;

    for (var i = 0; i < quantidadeInicial; i++) {
      _concluidos.add(widget.treino.exercicios[i].id);
    }
  }

  int get _totalExercicios => widget.treino.exercicios.length;

  int get _quantidadeConcluida => _concluidos.length;

  double get _progresso {
    if (_totalExercicios == 0) {
      return 0;
    }

    return _quantidadeConcluida / _totalExercicios;
  }

  int get _percentualProgresso => (_progresso * 100).round();

  String get _tituloTreino {
    final partes = widget.treino.nome.split('—');

    if (partes.length < 2) {
      return widget.treino.nome;
    }

    final descricao = partes.last.trim().toLowerCase();

    if (descricao.isEmpty) {
      return widget.treino.nome;
    }

    return descricao[0].toUpperCase() + descricao.substring(1);
  }

  void _alternarExercicio(ExercicioTreinoUi exercicio) {
    setState(() {
      if (_concluidos.contains(exercicio.id)) {
        _concluidos.remove(exercicio.id);
      } else {
        _concluidos.add(exercicio.id);
      }
    });
  }

  void _abrirExercicio(
    ExercicioTreinoUi exercicio,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlunoExercicioDetalheView(
          exercicio: exercicio,
        ),
      ),
    );
  }

  void _continuarTreino() {
    ExercicioTreinoUi? primeiroPendente;

    for (final exercicio in widget.treino.exercicios) {
      if (!_concluidos.contains(exercicio.id)) {
        primeiroPendente = exercicio;
        break;
      }
    }

    if (primeiroPendente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todos os exercícios deste treino foram concluídos.',
          ),
        ),
      );
      return;
    }

    _abrirExercicio(primeiroPendente);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgresso(),
                        const SizedBox(height: 24),
                        _buildTituloSecao('AQUECIMENTO'),
                        const SizedBox(height: 10),
                        _buildAquecimentoCard(),
                        const SizedBox(height: 26),
                        _buildTituloSecao('SÉRIE PRINCIPAL'),
                        const SizedBox(height: 10),
                        ...widget.treino.exercicios.map(
                          (exercicio) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _buildExercicioCard(exercicio),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: _cinzaBorda,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 398,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _continuarTreino,
                      style: FilledButton.styleFrom(
                        backgroundColor: _laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _quantidadeConcluida == _totalExercicios &&
                                _totalExercicios > 0
                            ? 'FINALIZAR TREINO'
                            : 'CONTINUAR TREINO',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _cinzaBorda,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 46,
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: IconButton(
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _verde,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'GRAZI BRAZ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.anton(
                          color: _verde,
                          fontSize: 23,
                          letterSpacing: 0.6,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: _azulEscuro,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  48,
                  0,
                  48,
                  2,
                ),
                child: Column(
                  children: [
                    Text(
                      'Treino: $_tituloTreino',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _azulEscuro,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TreinosFrontData.professorNome,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _cinzaTexto,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgresso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _cinzaBorda,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu Progresso',
                  style: GoogleFonts.barlowCondensed(
                    color: _azulEscuro,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_quantidadeConcluida de $_totalExercicios '
                  'exercícios concluídos',
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: _progresso,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFFE8F1F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _verde,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '$_percentualProgresso%',
                  style: GoogleFonts.barlowCondensed(
                    color: _azulEscuro,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSecao(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.barlowCondensed(
        color: _azulEscuro,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildAquecimentoCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _aquecimentoConcluido = !_aquecimentoConcluido;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _aquecimentoConcluido
                  ? const Color(0xFF99D5CA)
                  : _cinzaBorda,
            ),
          ),
          child: Row(
            children: [
              _buildThumb(
                icon: Icons.self_improvement_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobilidade de quadril',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1 série • 60 seg',
                      style: GoogleFonts.inter(
                        color: _cinzaTexto,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusButton(
                concluido: _aquecimentoConcluido,
                onTap: () {
                  setState(() {
                    _aquecimentoConcluido =
                        !_aquecimentoConcluido;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercicioCard(
    ExercicioTreinoUi exercicio,
  ) {
    final concluido = _concluidos.contains(exercicio.id);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _abrirExercicio(exercicio);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: concluido
                  ? const Color(0xFF99D5CA)
                  : _cinzaBorda,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildThumb(
                icon: Icons.fitness_center_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          _seriesText(exercicio.series),
                          destaque: true,
                        ),
                        _buildBadge(
                          _repeticoesText(exercicio.series),
                        ),
                        if (exercicio.carga.trim().isNotEmpty &&
                            exercicio.carga.trim() != '-')
                          _buildBadge(
                            exercicio.carga,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusButton(
                concluido: concluido,
                onTap: () {
                  _alternarExercicio(exercicio);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumb({
    required IconData icon,
  }) {
    return Container(
      width: 82,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE1EEEC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: _verde,
            size: 31,
          ),
          Positioned(
            right: 7,
            bottom: 7,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _verdeEscuro,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required bool concluido,
    required VoidCallback onTap,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: concluido ? _verde : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: concluido
                ? _verde
                : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        child: Icon(
          concluido
              ? Icons.check_rounded
              : Icons.circle_outlined,
          color: concluido
              ? Colors.white
              : const Color(0xFFCBD5E1),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBadge(
    String texto, {
    bool destaque = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0xFFE5F6F2)
            : _cinzaClaro,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: destaque
              ? const Color(0xFFB9E5DC)
              : _cinzaBorda,
        ),
      ),
      child: Text(
        texto,
        style: GoogleFonts.inter(
          color: destaque ? _verde : _cinzaTexto,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _seriesText(String series) {
    final valor = series.trim();

    if (valor.contains('x')) {
      final partes = valor.split('x');
      return '${partes.first.trim()} SÉRIES';
    }

    return valor.toUpperCase();
  }

  String _repeticoesText(String series) {
    final valor = series.trim();

    if (!valor.contains('x')) {
      return 'REPS';
    }

    final partes = valor.split('x');

    if (partes.length < 2) {
      return 'REPS';
    }

    final repeticoes = partes[1].trim();

    if (repeticoes.toLowerCase().endsWith('s')) {
      return repeticoes.toUpperCase();
    }

    return '$repeticoes REPS';
  }
}
