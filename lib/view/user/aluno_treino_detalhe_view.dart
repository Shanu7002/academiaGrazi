import 'dart:async';

import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:academiagrazi/view/user/widgets/treinos_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoTreinoDetalheView
    extends StatefulWidget {
  final TreinoUi treino;

  const AlunoTreinoDetalheView({
    super.key,
    required this.treino,
  });

  @override
  State<AlunoTreinoDetalheView>
      createState() =>
          _AlunoTreinoDetalheViewState();
}

class _AlunoTreinoDetalheViewState
    extends State<AlunoTreinoDetalheView> {
  static const Color _verde =
      Color(0xFF006052);

  static const Color _laranja =
      Color(0xFFFF7545);

  static const Color _fundo =
      Color(0xFFF8F8F6);

  static const Color _card =
      Color(0xFFEEF2F0);

  static const Color _video =
      Color(0xFF707070);

  static const Color _texto =
      Color(0xFF111817);

  static const Color _textoSecundario =
      Color(0xFF414A47);

  bool _treinoIniciado = false;

  Duration _tempo = Duration.zero;

  Timer? _timer;

  final Set<String> _concluidos = {};

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  String get _tempoFormatado {
    final minutos =
        _tempo.inMinutes.remainder(60);

    final segundos =
        _tempo.inSeconds.remainder(60);

    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundos.toString().padLeft(2, '0')}';
  }

  void _iniciarTreino() {
    if (_treinoIniciado) {
      return;
    }

    setState(() {
      _treinoIniciado = true;
      _tempo = Duration.zero;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _tempo +=
              const Duration(seconds: 1);
        });
      },
    );
  }

  void _concluir(
    ExercicioTreinoUi exercicio,
  ) {
    setState(() {
      _concluidos.add(
        exercicio.id,
      );
    });
  }

  void _reabrir(
    ExercicioTreinoUi exercicio,
  ) {
    setState(() {
      _concluidos.remove(
        exercicio.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: Column(
        children: [
          const TreinosHeader(),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 440,
                ),
                child:
                    SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildResumo(),

                      const SizedBox(
                        height: 14,
                      ),

                      _buildTitulo(),

                      const SizedBox(
                        height: 11,
                      ),

                      ...widget
                          .treino.exercicios
                          .map(
                        (exercicio) {
                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 9,
                            ),
                            child:
                                _buildExercicio(
                              exercicio,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius:
            BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            widget.treino.nome,
            style:
                GoogleFonts.barlowCondensed(
              color: _texto,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            widget.treino.descricao,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed:
                  _treinoIniciado
                      ? null
                      : _iniciarTreino,
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    _laranja,
                disabledBackgroundColor:
                    _laranja,
                foregroundColor:
                    Colors.white,
                disabledForegroundColor:
                    Colors.white,
                padding: EdgeInsets.zero,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              child: _treinoIniciado
                  ? Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          _tempoFormatado,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Icon(
                          Icons
                              .access_time_outlined,
                          size: 14,
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .play_arrow_rounded,
                          size: 18,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'Iniciar treino',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    return Row(
      children: [
        Text(
          'EXERCÍCIOS',
          style:
              GoogleFonts.barlowCondensed(
            color: _texto,
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  _verde,
                  Color(0xFF26B0A1),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExercicio(
    ExercicioTreinoUi exercicio,
  ) {
    final bool concluido =
        _concluidos.contains(
      exercicio.id,
    );

    if (_treinoIniciado &&
        concluido) {
      return _buildConcluido(
        exercicio,
      );
    }

    final double altura =
        _treinoIniciado
            ? 124
            : 100;

    return Container(
      width: double.infinity,
      height: altura,
      decoration: BoxDecoration(
        color: _card,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                8,
                7,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nome
                        .toUpperCase(),
                    style: GoogleFonts
                        .barlowCondensed(
                      color: _texto,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                      height: 1,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  if (exercicio
                          .aquecimento !=
                      null)
                    _info(
                      'Aquecimento: '
                      '${exercicio.aquecimento}',
                    ),

                  _info(
                    'Séries: '
                    '${exercicio.series}',
                  ),

                  _info(
                    'Carga: '
                    '${exercicio.carga}',
                  ),

                  const Spacer(),

                  if (_treinoIniciado)
                    SizedBox(
                      width: double.infinity,
                      height: 23,
                      child: Material(
                        color: _laranja,
                        borderRadius:
                            BorderRadius.circular(
                          3,
                        ),
                        child: InkWell(
                          onTap: () {
                            _concluir(
                              exercicio,
                            );
                          },
                          child:
                              const Center(
                            child: Icon(
                              Icons
                                  .check_circle_outline,
                              color:
                                  Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: 88,
            height: double.infinity,
            child: Material(
              color: _video,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vídeo de '
                        '${exercicio.nome}',
                      ),
                    ),
                  );
                },
                child: const Center(
                  child: _PlayVideo(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcluido(
    ExercicioTreinoUi exercicio,
  ) {
    return Material(
      color: _verde,
      borderRadius:
          BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          _reabrir(
            exercicio,
          );
        },
        borderRadius:
            BorderRadius.circular(8),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              const Icon(
                Icons
                    .check_circle_outline,
                color: Colors.white,
                size: 16,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  exercicio.nome
                      .toUpperCase(),
                  style: GoogleFonts
                      .barlowCondensed(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(
    String texto,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 2,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: _texto,
          fontSize: 9,
          height: 1.05,
        ),
      ),
    );
  }
}

class _PlayVideo
    extends StatelessWidget {
  const _PlayVideo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 15,
      ),
    );
  }
}