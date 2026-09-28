import 'package:academiagrazi/view/user/aluno_treino_detalhe_view.dart';
import 'package:academiagrazi/view/user/treino_ui_data.dart';
import 'package:academiagrazi/view/user/widgets/treinos_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlunoTreinosView extends StatelessWidget {
  const AlunoTreinosView({
    super.key,
  });

  static const Color _laranja = Color(0xFFFF7545);
  static const Color _azul = Color(0xFF242E5B);
  static const Color _fundo = Color(0xFFF8F8F6);
  static const Color _card = Color(0xFFF0F4F2);
  static const Color _texto = Color(0xFF101817);
  static const Color _textoSecundario = Color(0xFF4D5754);

  @override
  Widget build(BuildContext context) {
    final TreinoUi recomendacao =
        TreinosFrontData.recomendacao;

    final List<TreinoUi> treinos =
        TreinosFrontData.treinos;

    return Scaffold(
      backgroundColor: _fundo,
      body: Column(
        children: [
          const TreinosHeader(),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildRecomendacao(
                        context,
                        recomendacao,
                      ),

                      const SizedBox(height: 20),

                      _buildTituloOutrosTreinos(),

                      const SizedBox(height: 16),

                      ...treinos.map(
                        (treino) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: _buildTreinoCard(
                              context,
                              treino,
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

  Widget _buildRecomendacao(
    BuildContext context,
    TreinoUi treino,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        10,
      ),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(
                'Recomendação',
                _azul,
              ),
              const SizedBox(width: 10),
              _badge(
                '${treino.exercicios.length} exercícios',
                _laranja,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            treino.nome,
            style: GoogleFonts.barlowCondensed(
              color: _texto,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            treino.descricao,
            style: const TextStyle(
              color: _texto,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                _abrirTreino(
                  context,
                  treino,
                );
              },
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: 20,
              ),
              label: const Text(
                'Iniciar treino',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _laranja,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloOutrosTreinos() {
    return Row(
      children: [
        Text(
          'OUTROS TREINOS',
          style: GoogleFonts.barlowCondensed(
            color: _texto,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF02594F),
                  Color(0xFF31B6A8),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreinoCard(
    BuildContext context,
    TreinoUi treino,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          _abrirTreino(
            context,
            treino,
          );
        },
        child: Container(
          width: double.infinity,
          constraints:
              const BoxConstraints(
            minHeight: 75,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            15,
            12,
            12,
            12,
          ),
          decoration: BoxDecoration(
            color: _card,
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      treino.nome,
                      style: GoogleFonts
                          .barlowCondensed(
                        color: _texto,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                        height: 1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      treino.descricao,
                      style: const TextStyle(
                        color:
                            _textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7D8884),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(
    String texto,
    Color cor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: cor,
        borderRadius:
            BorderRadius.circular(3),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _abrirTreino(
    BuildContext context,
    TreinoUi treino,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return AlunoTreinoDetalheView(
            treino: treino,
          );
        },
      ),
    );
  }
}