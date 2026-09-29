import 'package:academiagrazi/view/user/aluno_treino_detalhe_view.dart';
import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoTreinosView extends StatefulWidget {
  const AlunoTreinosView({
    super.key,
  });

  @override
  State<AlunoTreinosView> createState() =>
      _AlunoTreinosViewState();
}

class _AlunoTreinosViewState
    extends State<AlunoTreinosView> {
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
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildCabecalhoTela(),

                        const SizedBox(height: 16),

                        _buildTipoTreinoTabs(),

                        const SizedBox(height: 16),

                        _buildCicloAtual(),

                        const SizedBox(height: 20),

                        _buildCabecalhoDivisao(),

                        const SizedBox(height: 16),

                        _buildTreinoDestaque(
                          TreinosFrontData.treinoA,
                        ),

                        const SizedBox(height: 16),

                        _buildTreinoConcluido(
                          TreinosFrontData.treinoB,
                        ),

                        const SizedBox(height: 16),

                        _buildTreinoProgramado(
                          TreinosFrontData.treinoC,
                        ),

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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFEFE),
        border: Border(
          bottom: BorderSide(
            color: Color(0xCCE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
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

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAZI BRAZ',
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
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
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

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _buildCabecalhoTela() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALUNO: '
                    '${TreinosFrontData.alunoNome.toUpperCase()}',
                    style: GoogleFonts.inter(
                      color: _verdeTexto,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 0.55,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    'MEUS TREINOS',
                    style:
                        GoogleFonts.barlowCondensed(
                      color: _azulEscuro,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -0.75,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(999),
                border: Border.all(
                  color:
                      const Color(0xFF99F6E4),
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
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
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            const Icon(
              Icons.edit_note_rounded,
              color: _cinzaTexto,
              size: 16,
            ),

            const SizedBox(width: 4),

            Expanded(
              child: Text(
                'Prescrição '
                '${TreinosFrontData.professorNome} '
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
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTipoTreinoTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCCE2E8F0),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              selecionado:
                  _fichaPresencialSelecionada,
              icone:
                  Icons.fitness_center_rounded,
              titulo: 'FICHA PRESENCIAL',
              onTap: () {
                setState(() {
                  _fichaPresencialSelecionada =
                      true;
                });
              },
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildTab(
              selecionado:
                  !_fichaPresencialSelecionada,
              icone: Icons.home_outlined,
              titulo: 'TREINAR EM CASA',
              onTap: () {
                setState(() {
                  _fichaPresencialSelecionada =
                      false;
                });
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
      color: selecionado
          ? Colors.white
          : Colors.transparent,
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 17,
                color: selecionado
                    ? _verde
                    : _cinzaTexto,
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  titulo,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      GoogleFonts.barlowCondensed(
                    color: selecionado
                        ? _verde
                        : _cinzaTexto,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CICLO ATUAL
  // ============================================================

  Widget _buildCicloAtual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xE6E2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0x66FFD8C8,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          4,
                        ),
                      ),
                      child: Text(
                        'CICLO ATUAL',
                        style:
                            GoogleFonts.inter(
                          color: _laranja,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      TreinosFrontData
                          .cicloNome,
                      style: GoogleFonts
                          .barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFECFDF5),
                  borderRadius:
                      BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color:
                          Color(0xFF047857),
                      size: 13,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      'Em dia',
                      style: GoogleFonts.inter(
                        color:
                            const Color(
                          0xFF047857,
                        ),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetrica(
                  icon:
                      Icons.event_repeat_rounded,
                  titulo: 'FREQ.',
                  valor:
                      TreinosFrontData.frequencia,
                  legenda: TreinosFrontData
                      .frequenciaLegenda,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildMetrica(
                  icon:
                      Icons.access_time_rounded,
                  titulo: 'DURAÇÃO',
                  valor: TreinosFrontData
                      .duracaoMedia,
                  legenda: TreinosFrontData
                      .duracaoLegenda,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildMetrica(
                  icon:
                      Icons.event_available_outlined,
                  titulo: 'VALIDADE',
                  valor:
                      TreinosFrontData.validade,
                  legenda: TreinosFrontData
                      .validadeLegenda,
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
      height: 76,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0x1AFF7943)
            : _cinzaClaro,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: destaque
              ? const Color(0x33FF7943)
              : const Color(0xB3E2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: destaque
                    ? _laranjaEscuro
                    : _verdeTexto,
              ),

              const SizedBox(width: 4),

              Flexible(
                child: Text(
                  titulo,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 1),

          Text(
            valor,
            style:
                GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          Text(
            legenda,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVISÃO
  // ============================================================

  Widget _buildCabecalhoDivisao() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'DIVISÃO DE FICHAS',
            style:
                GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        Text(
          '3 rotinas prescritas',
          style: GoogleFonts.inter(
            color: _cinzaTexto,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TREINO A
  // ============================================================

  Widget _buildTreinoDestaque(
    TreinoUi treino,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        30,
        18,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
            Color(0x66ECFDF5),
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(
            0x66005A4F,
          ),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            top: -30,
            bottom: -18,
            child: Container(
              width: 6,
              color: _laranjaEscuro,
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: _laranja,
                        borderRadius:
                            BorderRadius.circular(
                          999,
                        ),
                      ),
                      child: Text(
                        treino.statusTexto,
                        style:
                            GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  _smallPill(
                    icon:
                        Icons.schedule_rounded,
                    text:
                        '${treino.duracaoMinutos} min',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _letraTreino(
                    treino.letra,
                    _verdeEscuro,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      treino.nome,
                      style: GoogleFonts
                          .barlowCondensed(
                        color: _azulEscuro,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Text(
                treino.descricao,
                style: GoogleFonts.inter(
                  color: _cinzaTexto,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _badge(
                    Icons.fitness_center,
                    '${treino.quantidadeExercicios} exercícios',
                    const Color(0xFFDDF5F2),
                    _verdeEscuro,
                  ),
                  _badge(
                    Icons.speed_rounded,
                    treino.nivel,
                    const Color(0xFFF1F5F9),
                    _azulEscuro,
                  ),
                  _badge(
                    Icons.trending_up,
                    treino.estrategia,
                    const Color(0xFFFFF7ED),
                    _laranjaEscuro,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildResumoExercicios(
                treino,
                destaque: true,
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _abrirTreino(treino);
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    'INICIAR TREINO ${treino.letra} AGORA',
                    style: GoogleFonts
                        .barlowCondensed(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        _laranja,
                    foregroundColor:
                        Colors.white,
                    elevation: 2,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _abrirTreino(treino);
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                  ),
                  label: Text(
                    'VER FICHA DETALHADA',
                    style: GoogleFonts
                        .barlowCondensed(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 0.35,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: _verde,
                    backgroundColor:
                        const Color(
                      0xFFF0FDFA,
                    ),
                    side: const BorderSide(
                      color:
                          Color(0xB399F6E4),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TREINO B
  // ============================================================

  Widget _buildTreinoConcluido(
    TreinoUi treino,
  ) {
    return _buildTreinoSecundario(
      treino: treino,
      statusColor:
          const Color(0xFF065F46),
      statusBackground:
          const Color(0xFFECFDF5),
      statusBorder:
          const Color(0xFFA7F3D0),
      letraColor:
          const Color(0xFF334155),
      secundarioTexto:
          treino.estrategia,
      segundoBotao:
          'REFAZER TREINO',
    );
  }

  // ============================================================
  // TREINO C
  // ============================================================

  Widget _buildTreinoProgramado(
    TreinoUi treino,
  ) {
    return _buildTreinoSecundario(
      treino: treino,
      statusColor:
          const Color(0xFF1D4ED8),
      statusBackground:
          const Color(0xFFEFF6FF),
      statusBorder:
          const Color(0xFFBFDBFE),
      letraColor:
          const Color(0xFF115E59),
    );
  }

  Widget _buildTreinoSecundario({
    required TreinoUi treino,
    required Color statusColor,
    required Color statusBackground,
    required Color statusBorder,
    required Color letraColor,
    String? secundarioTexto,
    String? segundoBotao,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _cinzaBorda,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusBackground,
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                    border: Border.all(
                      color: statusBorder,
                    ),
                  ),
                  child: Text(
                    treino.statusTexto,
                    overflow:
                        TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (secundarioTexto !=
                  null) ...[
                const SizedBox(width: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF1F5F9,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      6,
                    ),
                  ),
                  child: Text(
                    secundarioTexto,
                    style: GoogleFonts.inter(
                      color: _cinzaTexto,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],

              if (treino.status ==
                  TreinoStatusUi
                      .programado) ...[
                const Spacer(),

                Text(
                  '${treino.duracaoMinutos} min',
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _letraTreino(
                treino.letra,
                letraColor,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  treino.nome,
                  style: GoogleFonts
                      .barlowCondensed(
                    color: _azulEscuro,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            treino.descricao,
            style: GoogleFonts.inter(
              color: _cinzaTexto,
              fontSize: 12,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          _buildResumoExercicios(
            treino,
          ),

          const SizedBox(height: 12),

          if (segundoBotao != null)
            Row(
              children: [
                Expanded(
                  child:
                      _secondaryActionButton(
                    'VER FICHA',
                    () {
                      _abrirTreino(
                        treino,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child:
                      _secondaryActionButton(
                    segundoBotao,
                    () {
                      _abrirTreino(
                        treino,
                      );
                    },
                    outlined: true,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: _secondaryActionButton(
                'VER FICHA COMPLETA',
                () {
                  _abrirTreino(treino);
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLEMENTARES
  // ============================================================

  Widget _buildComplementares() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'TREINOS COMPLEMENTARES',
          style:
              GoogleFonts.barlowCondensed(
            color: _azulEscuro,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: TreinosFrontData
              .complementares
              .map(
                (treino) => Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(
                      right: treino ==
                              TreinosFrontData
                                  .complementares
                                  .first
                          ? 8
                          : 0,
                    ),
                    child:
                        _buildComplementarCard(
                      treino,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildComplementarCard(
    TreinoComplementarUi treino,
  ) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _cinzaBorda,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.self_improvement_rounded,
            color: _verde,
            size: 22,
          ),

          const SizedBox(height: 8),

          Text(
            treino.nome,
            style:
                GoogleFonts.barlowCondensed(
              color: _azulEscuro,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: Text(
              treino.descricao,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _cinzaTexto,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),

          Text(
            '${treino.duracaoMinutos} min',
            style: GoogleFonts.inter(
              color: _verde,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Widget _buildHistoricoButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: _verde,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: _cinzaBorda,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'VER FICHAS E CICLOS ANTERIORES',
          style:
              GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildResumoExercicios(
    TreinoUi treino, {
    bool destaque = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0xE6FFFFFF)
            : _cinzaClaro,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: destaque
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                destaque
                    ? 'PRINCIPAIS EXERCÍCIOS'
                    : 'RESUMO DA FICHA:',
                style: GoogleFonts.inter(
                  color: destaque
                      ? _verdeTexto
                      : const Color(
                          0xFF94A3B8),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              if (destaque) ...[
                const Spacer(),

                Text(
                  treino.seriesResumo,
                  style: GoogleFonts.inter(
                    color: _cinzaTexto,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 5),

          Text(
            treino.principaisExercicios,
            style: GoogleFonts.inter(
              color: destaque
                  ? _azulEscuro
                  : const Color(
                      0xFF334155),
              fontSize: 12,
              fontWeight:
                  FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallPill({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF1F5F9),
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color:
                const Color(0xFF334155),
          ),

          const SizedBox(width: 4),

          Text(
            text,
            style: GoogleFonts.inter(
              color:
                  const Color(0xFF334155),
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _letraTreino(
    String letra,
    Color color,
  ) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        letra,
        style: GoogleFonts.anton(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _badge(
    IconData icon,
    String texto,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),

          const SizedBox(width: 4),

          Text(
            texto,
            style: GoogleFonts.inter(
              color: foreground,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryActionButton(
    String label,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    return SizedBox(
      height: 40,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF334155,
                ),
                side: const BorderSide(
                  color: _cinzaBorda,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts
                    .barlowCondensed(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    const Color(
                  0xFFF1F5F9,
                ),
                foregroundColor:
                    _verde,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts
                    .barlowCondensed(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
    );
  }

  // ============================================================
  // NAVEGAÇÃO TEMPORÁRIA
  // ============================================================

  void _abrirTreino(
    TreinoUi treino,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          // Esta tela ainda é a versão antiga.
          // Na próxima etapa será substituída
          // pelo novo "Treino do Dia - Aluno".
          return AlunoTreinoDetalheView(
            treino: treino,
          );
        },
      ),
    );
  }
}