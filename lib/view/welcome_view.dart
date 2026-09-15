import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_view.dart';

// ================================================================
// ASSETS DA TELA INICIAL
// ================================================================

const String _logoAsset =
    'assets/welcometela/grazi_braz.png';

const String _flowerAsset =
    'assets/welcometela/flor.png';

const String _runningAsset =
    'assets/welcometela/corrida.png';

const String _progressAsset =
    'assets/welcometela/evolucao.png';

const String _trainingAsset =
    'assets/welcometela/treino.png';

const String _foodAsset =
    'assets/welcometela/alimentacao.png';

const String _sheetAsset =
    'assets/welcometela/ficha.png';

const String _gradientAsset =
    'assets/welcometela/faixa_gradiente.png';


// ================================================================
// TELA INICIAL
// ================================================================

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() =>
      _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  // Animação de abertura das pétalas.
  late final AnimationController _openController;

  // Animação da flor pulsando antes do clique.
  late final AnimationController _pulseController;

  // Opacidade do conteúdo da tela.
  late final Animation<double> _contentOpacity;

  // Escala do pulso.
  late final Animation<double> _pulseScale;

  // Opacidade do pulso.
  late final Animation<double> _pulseOpacity;

  bool _opening = false;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // ABERTURA DAS PÉTALAS
    // ============================================================

    _openController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1900,
      ),
    );

    // O restante da tela desaparece somente
    // perto do final da abertura da flor.
    _contentOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(
          0.82,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    // ============================================================
    // PULSO DA FLOR
    // ============================================================

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1100,
      ),
    );

    // Cresce e diminui levemente.
    _pulseScale = Tween<double>(
      begin: 0.95,
      end: 1.09,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Pequena variação de opacidade.
    _pulseOpacity = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulso infinito enquanto o usuário
    // ainda não tocou na tela.
    _pulseController.repeat(
      reverse: true,
    );
  }

  // ==============================================================
  // CLIQUE NA TELA
  // ==============================================================

  Future<void> _openLogin() async {
    if (_opening) return;

    setState(() {
      _opening = true;
    });

    // Para o pulso.
    _pulseController.stop();

    // Abre as pétalas.
    await _openController.forward(
      from: 0,
    );

    // Pequena pausa mostrando
    // a flor completamente aberta.
    await Future.delayed(
      const Duration(
        milliseconds: 120,
      ),
    );

    if (!mounted) return;

    // ============================================================
    // TRANSIÇÃO PARA LOGIN
    // ============================================================

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(
          milliseconds: 450,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LoginView();
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  // ==============================================================
  // TELA
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF02594F),

      body: GestureDetector(
        behavior:
            HitTestBehavior.opaque,

        // Pode clicar em qualquer lugar da tela.
        onTap: _openLogin,

        child: Stack(
          fit: StackFit.expand,

          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 430,
                ),

                child: SafeArea(
                  bottom: false,

                  child: LayoutBuilder(
                    builder:
                        (context, constraints) {
                      final bool compact =
                          constraints.maxHeight <
                              700;

                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 28,
                        ),

                        child: Column(
                          children: [
                            SizedBox(
                              height:
                                  compact
                                      ? 28
                                      : 42,
                            ),

                            // ======================================
                            // LOGO GRAZI BRAZ
                            // ======================================

                            FadeTransition(
                              opacity:
                                  _contentOpacity,

                              child: Image.asset(
                                _logoAsset,
                                width:
                                    compact
                                        ? 110
                                        : 125,
                                fit:
                                    BoxFit
                                        .contain,
                              ),
                            ),

                            SizedBox(
                              height:
                                  compact
                                      ? 45
                                      : 60,
                            ),

                            // ======================================
                            // FLOR CENTRAL
                            // ======================================

                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 28,
                              ),

                              child:
                                  AnimatedFlower(
                                controller:
                                    _openController,

                                pulseScale:
                                    _pulseScale,

                                pulseOpacity:
                                    _pulseOpacity,

                                size:
                                    compact
                                        ? 240
                                        : 280,
                              ),
                            ),

                            const Spacer(),

                            // ======================================
                            // FRASE
                            // ======================================

                            FadeTransition(
                              opacity:
                                  _contentOpacity,

                              child: Text(
                                'Olá, vamos começar seu treino?',

                                textAlign:
                                    TextAlign
                                        .center,

                                style:
                                    GoogleFonts
                                        .barlowCondensed(
                                  color:
                                      Colors
                                          .white,

                                  fontSize:
                                      compact
                                          ? 20
                                          : 23,

                                  fontWeight:
                                      FontWeight
                                          .w300,

                                  letterSpacing:
                                      0.3,
                                ),
                              ),
                            ),

                            SizedBox(
                              height:
                                  compact
                                      ? 45
                                      : 60,
                            ),

                            // ======================================
                            // ÍCONES
                            // ======================================

                            FadeTransition(
                              opacity:
                                  _contentOpacity,

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,

                                children: [
                                  _buildIcon(
                                    _runningAsset,
                                  ),

                                  _buildIcon(
                                    _progressAsset,
                                  ),

                                  _buildIcon(
                                    _trainingAsset,
                                  ),

                                  _buildIcon(
                                    _foodAsset,
                                  ),

                                  _buildIcon(
                                    _sheetAsset,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(
                              height:
                                  compact
                                      ? 65
                                      : 90,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ================================================
            // FAIXA COLORIDA INFERIOR
            // ================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 32,

              child: FadeTransition(
                opacity:
                    _contentOpacity,

                child: Image.asset(
                  _gradientAsset,
                  fit:
                      BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // ÍCONE
  // ==============================================================

  Widget _buildIcon(
    String path,
  ) {
    return SizedBox(
      width: 43,
      height: 48,

      child: Image.asset(
        path,
        fit:
            BoxFit.contain,
      ),
    );
  }
}


// ==================================================================
// FLOR ANIMADA
// ==================================================================

class AnimatedFlower
    extends StatelessWidget {
  final AnimationController controller;

  final Animation<double>
      pulseScale;

  final Animation<double>
      pulseOpacity;

  final double size;

  const AnimatedFlower({
    super.key,
    required this.controller,
    required this.pulseScale,
    required this.pulseOpacity,
    required this.size,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    /*
           ORDEM DAS PÉTALAS

                   0
             7           1

          6                   2

             5           3
                   4


      0 = cima

      Depois segue no sentido horário.

      A última é a superior esquerda.
    */

    final List<double>
        petalAngles = [
      -math.pi / 2,

      -math.pi / 4,

      0,

      math.pi / 4,

      math.pi / 2,

      3 * math.pi / 4,

      math.pi,

      -3 * math.pi / 4,
    ];

    return SizedBox(
      width: size,
      height: size,

      child: AnimatedBuilder(
        animation:
            controller,

        builder: (
          context,
          child,
        ) {
          final double
              animationValue =
              controller.value;

          return Stack(
            alignment:
                Alignment.center,

            children: [
              // ==============================================
              // FLOR INICIAL PULSANDO
              // ==============================================

              Opacity(
                opacity:
                    _closedFlowerOpacity(
                  animationValue,
                ),

                child:
                    FadeTransition(
                  opacity:
                      pulseOpacity,

                  child:
                      ScaleTransition(
                    scale:
                        pulseScale,

                    child:
                        Transform.scale(
                      // Tamanho inicial da flor.
                      scale:
                          0.46,

                      child:
                          Image.asset(
                        _flowerAsset,

                        width:
                            size,

                        height:
                            size,

                        fit:
                            BoxFit
                                .contain,
                      ),
                    ),
                  ),
                ),
              ),

              // ==============================================
              // PÉTALAS ANIMADAS
              // ==============================================

              for (
                int i = 0;
                i <
                    petalAngles
                        .length;
                i++
              )
                _buildPetal(
                  index:
                      i,

                  angle:
                      petalAngles[i],

                  value:
                      animationValue,
                ),
            ],
          );
        },
      ),
    );
  }

  // =================================================================
  // UMA PÉTALA
  // =================================================================

  Widget _buildPetal({
    required int index,
    required double angle,
    required double value,
  }) {
    /*
      Uma pétala começa depois
      da pétala anterior.

      Isso cria o efeito sequencial.
    */

    final double start =
        0.04 +
            (index *
                0.085);

    final double end =
        start +
            0.27;

    final double
        rawProgress =
        _interval(
      value,
      start,
      end,
    );

    /*
      easeOutBack faz a pétala passar
      levemente do ponto final e voltar.

      Isso deixa a abertura mais natural.
    */

    final double progress =
        Curves.easeOutBack
            .transform(
      rawProgress,
    );

    // ================================================
    // ESCALA
    // ================================================

    final double scale =
        0.12 +
            (0.88 *
                progress);

    // ================================================
    // ROTAÇÃO
    // ================================================

    final double rotation =
        (1 -
                progress) *
            0.48;

    // ================================================
    // MOVIMENTO PARA FORA
    // ================================================

    final double
        inwardDistance =
        15 *
            (1 -
                progress);

    final Offset offset =
        Offset(
      -math.cos(angle) *
          inwardDistance,

      -math.sin(angle) *
          inwardDistance,
    );

    // ================================================
    // OPACIDADE
    // ================================================

    final double opacity =
        rawProgress.clamp(
      0.0,
      1.0,
    );

    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity:
              opacity,

          child:
              Transform.translate(
            offset:
                offset,

            child:
                Transform.rotate(
              angle:
                  rotation,

              alignment:
                  Alignment
                      .center,

              child:
                  Transform.scale(
                scale:
                    scale,

                alignment:
                    Alignment
                        .center,

                child:
                    ClipPath(
                  clipper:
                      PetalClipper(
                    angle:
                        angle,
                  ),

                  child:
                      Image.asset(
                    _flowerAsset,

                    width:
                        size,

                    height:
                        size,

                    fit:
                        BoxFit
                            .contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================================================================
  // INTERVALO DE ANIMAÇÃO
  // =================================================================

  double _interval(
    double value,
    double start,
    double end,
  ) {
    if (value <= start) {
      return 0;
    }

    if (value >= end) {
      return 1;
    }

    return (value - start) /
        (end - start);
  }

  // =================================================================
  // FADE DA FLOR ORIGINAL
  // =================================================================

  double _closedFlowerOpacity(
    double value,
  ) {
    // Antes de clicar:
    // flor totalmente visível.
    if (value <= 0.02) {
      return 1;
    }

    // Quando as pétalas começam:
    // flor original desaparece.
    if (value >= 0.12) {
      return 0;
    }

    return 1 -
        ((value - 0.02) /
            0.10);
  }
}


// ==================================================================
// RECORTE DAS PÉTALAS
// ==================================================================

class PetalClipper
    extends CustomClipper<Path> {
  final double angle;

  PetalClipper({
    required this.angle,
  });

  @override
  Path getClip(
    Size size,
  ) {
    final Offset center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.sqrt(
      (size.width *
              size.width) +
          (size.height *
              size.height),
    );

    /*
      Flor com 8 pétalas.

      360° / 8 = 45°.
    */

    const double
        petalSector =
        math.pi / 4;

    /*
      Pequena sobreposição
      para não cortar o contorno
      branco das pétalas.
    */

    const double overlap =
        0.06;

    final double
        startAngle =
        angle -
            (petalSector /
                2) -
            (overlap /
                2);

    final double
        sweepAngle =
        petalSector +
            overlap;

    final Rect rect =
        Rect.fromCircle(
      center:
          center,
      radius:
          radius,
    );

    final Path path =
        Path();

    path.moveTo(
      center.dx,
      center.dy,
    );

    path.arcTo(
      rect,
      startAngle,
      sweepAngle,
      false,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant PetalClipper
        oldClipper,
  ) {
    return oldClipper.angle !=
        angle;
  }
}