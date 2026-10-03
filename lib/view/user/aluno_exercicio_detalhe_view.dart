import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoExercicioDetalheView extends StatefulWidget {
  final ExercicioTreinoUi exercicio;

  const AlunoExercicioDetalheView({
    super.key,
    required this.exercicio,
  });

  @override
  State<AlunoExercicioDetalheView> createState() =>
      _AlunoExercicioDetalheViewState();
}

class _AlunoExercicioDetalheViewState
    extends State<AlunoExercicioDetalheView> {
  static const Color _background = Color(0xFFF4F7FA);
  static const Color _verde = Color(0xFF005A4F);
  static const Color _verdeEscuro = Color(0xFF003D36);
  static const Color _laranja = Color(0xFFFF7943);
  static const Color _azulEscuro = Color(0xFF092837);
  static const Color _cinzaTexto = Color(0xFF64748B);
  static const Color _cinzaBorda = Color(0xFFE2E8F0);
  static const Color _cinzaClaro = Color(0xFFF8FAFC);

  late final List<TextEditingController> _cargaControllers;
  final Set<int> _seriesConcluidas = <int>{};

  @override
  void initState() {
    super.initState();

    final cargaInicial = _cargaInicial;

    _cargaControllers = List.generate(
      _quantidadeSeries,
      (_) => TextEditingController(text: cargaInicial),
    );
  }

  @override
  void dispose() {
    for (final controller in _cargaControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  int get _quantidadeSeries {
    final valor = widget.exercicio.series.trim();

    if (valor.contains('x')) {
      final partes = valor.split('x');
      final quantidade = int.tryParse(partes.first.trim());

      if (quantidade != null && quantidade > 0) {
        return quantidade;
      }
    }

    return 1;
  }

  String get _repeticoes {
    final valor = widget.exercicio.series.trim();

    if (!valor.contains('x')) {
      return valor;
    }

    final partes = valor.split('x');

    if (partes.length < 2) {
      return valor;
    }

    return partes[1].trim();
  }

  String get _cargaInicial {
    final somenteNumeros = widget.exercicio.carga
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');

    return somenteNumeros;
  }

  String get _descanso {
    if (widget.exercicio.id == 'agachamento') {
      return '75s';
    }

    return '—';
  }

  String get _orientacoes {
    if (widget.exercicio.id == 'agachamento') {
      return 'Mantenha as costas retas e o core contraído. '
          'Posicione os pés na largura dos ombros, apontando '
          'ligeiramente para fora. Desça flexionando joelhos '
          'e quadril, como se fosse sentar em uma cadeira, '
          'até que as coxas fiquem paralelas ao chão.';
    }

    return 'As orientações específicas deste exercício serão '
        'exibidas aqui quando estiverem cadastradas na prescrição.';
  }

  int? get _proximaSeriePendente {
    for (var i = 0; i < _quantidadeSeries; i++) {
      if (!_seriesConcluidas.contains(i)) {
        return i;
      }
    }

    return null;
  }

  void _alternarSerie(int indice) {
    setState(() {
      if (_seriesConcluidas.contains(indice)) {
        _seriesConcluidas.remove(indice);
      } else {
        _seriesConcluidas.add(indice);
      }
    });
  }

  void _concluirProximaSerie() {
    final proxima = _proximaSeriePendente;

    if (proxima == null) {
      Navigator.maybePop(context);
      return;
    }

    setState(() {
      _seriesConcluidas.add(proxima);
    });

    final terminou =
        _seriesConcluidas.length == _quantidadeSeries;

    if (terminou) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício concluído.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximaSerie = _proximaSeriePendente;

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
                    padding: const EdgeInsets.only(
                      bottom: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideo(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            18,
                            16,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildTitulo(),
                              const SizedBox(height: 16),
                              _buildMetricas(),
                              const SizedBox(height: 26),
                              _buildOrientacoes(),
                              const SizedBox(height: 26),
                              _buildSeries(),
                            ],
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
                      onPressed: _concluirProximaSerie,
                      style: FilledButton.styleFrom(
                        backgroundColor: _laranja,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        proximaSerie == null
                            ? 'VOLTAR AO TREINO'
                            : 'CONCLUIR SÉRIE ${proximaSerie + 1}',
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
      height: 64,
      width: double.infinity,
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
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
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
                  widget.exercicio.nome,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlowCondensed(
                    color: _azulEscuro,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                height: 52,
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
      ),
    );
  }

  Widget _buildVideo() {
    return AspectRatio(
      aspectRatio: 390 / 219.38,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB8CBC8),
              Color(0xFF7C9691),
              Color(0xFF4E6964),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.92,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: _verdeEscuro,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: _azulEscuro,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '01:45',
                      style: GoogleFonts.inter(
                        color: _azulEscuro,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulo() {
    return Text(
      widget.exercicio.nome,
      style: GoogleFonts.barlowCondensed(
        color: _azulEscuro,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }

  Widget _buildMetricas() {
    return Row(
      children: [
        Expanded(
          child: _buildMetrica(
            valor: '$_quantidadeSeries',
            legenda: 'Séries',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetrica(
            valor: _repeticoes,
            legenda: 'Reps',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetrica(
            valor: _descanso,
            legenda: 'Descanso',
            destaque: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrica({
    required String valor,
    required String legenda,
    bool destaque = false,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 70,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0xFFFFEEE7)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destaque
              ? const Color(0x33FF7943)
              : _cinzaBorda,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlowCondensed(
              color: destaque
                  ? _laranja
                  : _azulEscuro,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            legenda,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orientações',
          style: GoogleFonts.barlowCondensed(
            color: _azulEscuro,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _cinzaBorda,
            ),
          ),
          child: Text(
            _orientacoes,
            style: GoogleFonts.inter(
              color: const Color(0xFF334155),
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Séries',
          style: GoogleFonts.barlowCondensed(
            color: _azulEscuro,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _cinzaBorda,
            ),
          ),
          child: Column(
            children: [
              _buildTabelaHeader(),
              for (var i = 0; i < _quantidadeSeries; i++)
                _buildSerieRow(i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabelaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              'Série',
              style: _tableHeaderStyle(),
            ),
          ),
          Expanded(
            child: Text(
              'Carga (kg)',
              textAlign: TextAlign.center,
              style: _tableHeaderStyle(),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'Status',
              textAlign: TextAlign.center,
              style: _tableHeaderStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieRow(int indice) {
    final concluida = _seriesConcluidas.contains(indice);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: indice == 0
                ? Colors.transparent
                : _cinzaBorda,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              '${indice + 1}',
              style: GoogleFonts.barlowCondensed(
                color: _azulEscuro,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 88,
                height: 40,
                child: TextField(
                  controller: _cargaControllers[indice],
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _azulEscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: _cinzaClaro,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _cinzaBorda,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _verde,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _alternarSerie(indice);
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: concluida
                        ? _verde
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: concluida
                          ? _verde
                          : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    concluida
                        ? Icons.check_rounded
                        : Icons.circle_outlined,
                    color: concluida
                        ? Colors.white
                        : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return GoogleFonts.inter(
      color: _cinzaTexto,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.35,
    );
  }
}
