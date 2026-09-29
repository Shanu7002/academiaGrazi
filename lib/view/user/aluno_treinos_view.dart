import 'package:academiagrazi/view/user/aluno_treino_detalhe_view.dart';
import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoTreinosView extends StatefulWidget {
  const AlunoTreinosView({super.key});

  @override
  State<AlunoTreinosView> createState() => _AlunoTreinosViewState();
}

class _AlunoTreinosViewState extends State<AlunoTreinosView> {
  static const Color _background = Color(0xFFF0F5F9);
  static const Color _verde = Color(0xFF005A4F);
  static const Color _verdeEscuro = Color(0xFF003D36);
  static const Color _verdeTexto = Color(0xFF277B60);
  static const Color _laranja = Color(0xFFFF7943);
  static const Color _laranjaEscuro = Color(0xFFC94F25);
  static const Color _azulEscuro = Color(0xFF092837);
  static const Color _cinzaTexto = Color(0xFF64748B);
  static const Color _cinzaBorda = Color(0xFFE2E8F0);
  static const Color _cinzaClaro = Color(0xFFF8FAFC);

  bool _fichaPresencialSelecionada = true;

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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCabecalhoTela(),
                        const SizedBox(height: 16),
                        _buildTipoTreinoTabs(),
                        const SizedBox(height: 16),
                        _buildCicloAtual(),
                        const SizedBox(height: 20),
                        _buildCabecalhoDivisao(),
                        const SizedBox(height: 16),
                        _buildTreinoDestaque(TreinosFrontData.treinoA),
                        const SizedBox(height: 16),
                        _buildTreinoConcluido(TreinosFrontData.treinoB),
                        const SizedBox(height: 16),
                        _buildTreinoProgramado(TreinosFrontData.treinoC),
                        const SizedBox(height: 28),
                        _buildComplementares(),
                        const SizedBox(height: 20),
                        _buildHistoricoButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFEFE),
        border: Border(
          bottom: BorderSide(color: Color(0xCCE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _verde,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAZI BRAZ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.anton(
                    color: _verde,
                    fontSize: 24,
                    letterSpacing: 0.6,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'METODOLOGIA & PERFORMANCE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: _azulEscuro,
                    size: 23,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 7,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _laranja,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF5F2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFDDF5F2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _verde,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoTela() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        final titulo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALUNO: ${TreinosFrontData.alunoNome.toUpperCase()}',
              style: GoogleFonts.inter(
                color: _verdeTexto,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'MEUS TREINOS',
              style: GoogleFonts.barlowCondensed(
                color: _azulEscuro,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.75,
                height: 1.25,
              ),
            ),
          ],
        );

        final semana = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF99F6E4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _laranja,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                TreinosFrontData.semana,
                style: GoogleFonts.inter(
                  color: _verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact) ...[
              titulo,
              const SizedBox(height: 8),
              semana,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titulo),
                  const SizedBox(width: 8),
                  semana,
                ],
              ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: _cinzaTexto,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Prescrição ${TreinosFrontData.professorNome} '
                    '• ${TreinosFrontData.ultimaAtualizacao}',
                    style: GoogleFonts.inter(
                      color: _cinzaTexto,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipoTreinoTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCCE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              selecionado: _fichaPresencialSelecionada,
              icone: Icons.fitness_center_rounded,
              titulo: 'FICHA PRESENCIAL',
              onTap: () {
                setState(() => _fichaPresencialSelecionada = true);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTab(
              selecionado: !_fichaPresencialSelecionada,
              icone: Icons.home_outlined,
              titulo: 'TREINAR EM CASA',
              onTap: () {
                setState(() => _fichaPresencialSelecionada = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required bool selecionado,
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selecionado ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 16,
                color: selecionado ? _verde : _cinzaTexto,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: selecionado ? _verde : _cinzaTexto,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCicloAtual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cinzaBorda),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CICLO ATUAL',
                      style: GoogleFonts.inter(
                        color: _verdeTexto,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      TreinosFrontData.cicloNome,
                      style: GoogleFonts.barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF047857),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Em dia',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF047857),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetrica(
                  icon: Icons.event_repeat_rounded,
                  titulo: 'FREQ.',
                  valor: TreinosFrontData.frequencia,
                  legenda: TreinosFrontData.frequenciaLegenda,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetrica(
                  icon: Icons.access_time_rounded,
                  titulo: 'DURAÇÃO',
                  valor: TreinosFrontData.duracaoMedia,
                  legenda: TreinosFrontData.duracaoLegenda,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetrica(
                  icon: Icons.event_available_outlined,
                  titulo: 'VALIDADE',
                  valor: TreinosFrontData.validade,
                  legenda: TreinosFrontData.validadeLegenda,
                  destaque: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrica({
    required IconData icon,
    required String titulo,
    required String valor,
    required String legenda,
    bool destaque = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destaque ? const Color(0x1AFF7943) : _cinzaClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destaque
              ? const Color(0x33FF7943)
              : const Color(0xB3E2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: destaque ? _laranjaEscuro : _verdeTexto,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            legenda,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 9,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoDivisao() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            'DIVISÃO DE FICHAS',
            style: GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '3 rotinas prescritas',
          style: GoogleFonts.inter(
            color: _cinzaTexto,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTreinoDestaque(TreinoUi treino) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF2FBF8)],
                  ),
                  border: Border.all(
                    color: const Color(0x66005A4F),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: _laranjaEscuro),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _laranja,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              treino.statusTexto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _duracaoPill(treino.duracaoMinutos),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _letraTreino(treino.letra, _verdeEscuro),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          treino.nome,
                          style: GoogleFonts.barlowCondensed(
                            color: _azulEscuro,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    treino.descricao,
                    style: GoogleFonts.inter(
                      color: _cinzaTexto,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _badge(
                        '${treino.quantidadeExercicios} exercícios',
                        background: const Color(0xFFE7F7F1),
                        foreground: _verde,
                      ),
                      _badge(
                        treino.nivel,
                        background: const Color(0xFFF1F5F9),
                        foreground: const Color(0xFF475569),
                      ),
                      _badge(
                        treino.estrategia,
                        background: const Color(0xFFFFEEE7),
                        foreground: _laranjaEscuro,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildResumoExercicios(treino, destaque: true),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7943), Color(0xFFC94F25)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _abrirTreino(treino),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'INICIAR TREINO ${treino.letra} AGORA',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _abrirTreino(treino),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE8F6F2),
                        foregroundColor: _verde,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'VER FICHA DETALHADA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreinoConcluido(TreinoUi treino) {
    return _buildTreinoSecundario(
      treino: treino,
      statusBackground: const Color(0xFFECFDF5),
      statusForeground: const Color(0xFF047857),
      letraColor: const Color(0xFF475569),
      segundoBadge: treino.estrategia,
      primeiroBotao: 'VER FICHA',
      segundoBotao: 'REFAZER TREINO',
    );
  }

  Widget _buildTreinoProgramado(TreinoUi treino) {
    return _buildTreinoSecundario(
      treino: treino,
      statusBackground: const Color(0xFFEFF6FF),
      statusForeground: const Color(0xFF1D4ED8),
      letraColor: const Color(0xFF115E59),
      primeiroBotao: 'VER FICHA COMPLETA',
    );
  }

  Widget _buildTreinoSecundario({
    required TreinoUi treino,
    required Color statusBackground,
    required Color statusForeground,
    required Color letraColor,
    required String primeiroBotao,
    String? segundoBotao,
    String? segundoBadge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cinzaBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      treino.statusTexto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: statusForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _duracaoPill(treino.duracaoMinutos),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _letraTreino(treino.letra, letraColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treino.nome,
                      style: GoogleFonts.barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    if (segundoBadge != null) ...[
                      const SizedBox(height: 7),
                      _badge(
                        segundoBadge,
                        background: const Color(0xFFF1F5F9),
                        foreground: const Color(0xFF475569),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            treino.descricao,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildResumoExercicios(treino),
          const SizedBox(height: 14),
          if (segundoBotao != null)
            Row(
              children: [
                Expanded(
                  child: _secondaryActionButton(
                    primeiroBotao,
                    () => _abrirTreino(treino),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _secondaryActionButton(
                    segundoBotao,
                    () => _abrirTreino(treino),
                    outlined: true,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: _secondaryActionButton(
                primeiroBotao,
                () => _abrirTreino(treino),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComplementares() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TREINOS COMPLEMENTARES',
          style: GoogleFonts.barlowCondensed(
            color: _azulEscuro,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'VÍDEOS GUIADOS',
          style: GoogleFonts.inter(
            color: _cinzaTexto,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final empilhar = constraints.maxWidth < 330;
            final cards = TreinosFrontData.complementares
                .map((treino) => _buildComplementarCard(treino))
                .toList();

            if (empilhar) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i < cards.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildComplementarCard(TreinoComplementarUi treino) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cinzaBorda),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.self_improvement_rounded,
            color: _verde,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            treino.nome,
            style: GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            treino.descricao,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${treino.duracaoMinutos} min',
            style: GoogleFonts.inter(
              color: _verde,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: _verde,
          backgroundColor: Colors.white,
          side: const BorderSide(color: _cinzaBorda),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'VER FICHAS E CICLOS ANTERIORES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildResumoExercicios(
    TreinoUi treino, {
    bool destaque = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destaque ? const Color(0xE6FFFFFF) : _cinzaClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destaque
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  destaque ? 'PRINCIPAIS EXERCÍCIOS' : 'RESUMO DA FICHA:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: destaque
                        ? _verdeTexto
                        : const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (destaque) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    treino.seriesResumo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      color: _cinzaTexto,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            treino.principaisExercicios,
            style: GoogleFonts.inter(
              color: destaque ? _azulEscuro : const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _duracaoPill(int minutos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 12,
            color: _cinzaTexto,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutos min',
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

  Widget _letraTreino(String letra, Color cor) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letra,
        style: GoogleFonts.anton(
          color: Colors.white,
          fontSize: 17,
          height: 1,
        ),
      ),
    );
  }

  Widget _badge(
    String texto, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: GoogleFonts.inter(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _secondaryActionButton(
    String texto,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        height: 42,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _verde,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFB7D8D2)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFE8F6F2),
          foregroundColor: _verde,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _abrirTreino(TreinoUi treino) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlunoTreinoDetalheView(treino: treino),
      ),
    );
  }
}
