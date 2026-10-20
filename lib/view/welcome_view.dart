import 'dart:async';
import 'dart:math' as math;

import 'package:academiagrazi/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ================================================================
// ASSETS DA TELA INICIAL
// ================================================================

const String _logoAsset = 'assets/welcometela/grazi_braz.png';

const String _runningAsset = 'assets/welcometela/corrida.png';

const String _progressAsset = 'assets/welcometela/evolucao.png';

const String _trainingAsset = 'assets/welcometela/treino.png';

const String _foodAsset = 'assets/welcometela/alimentacao.png';

const String _sheetAsset = 'assets/welcometela/ficha.png';

const String _gradientAsset = 'assets/welcometela/faixa_gradiente.png';

const List<String> _imageAssets = [
  _logoAsset,
  _runningAsset,
  _progressAsset,
  _trainingAsset,
  _foodAsset,
  _sheetAsset,
  _gradientAsset,
];

/*
  Flor extraída de assets/ICONE.svg:

  - flor_contorno.svg: só o contorno (primeiro quadro)
  - petala_N.svg: o preenchimento de cada pétala (último quadro)

  Todos usam o mesmo viewBox, então ficam sobrepostos certinho.
*/

const String _flowerOutlineAsset = 'assets/welcometela/flor_contorno.svg';

// Pétalas no sentido horário, começando pela de cima.
const List<String> _petalAssets = [
  'assets/welcometela/petala_0.svg',
  'assets/welcometela/petala_1.svg',
  'assets/welcometela/petala_2.svg',
  'assets/welcometela/petala_3.svg',
  'assets/welcometela/petala_4.svg',
  'assets/welcometela/petala_5.svg',
  'assets/welcometela/petala_6.svg',
  'assets/welcometela/petala_7.svg',
];

const List<String> _svgAssets = [_flowerOutlineAsset, ..._petalAssets];

// ================================================================
// LINHA DO TEMPO DA ANIMAÇÃO
// ================================================================

/*
  Toda a abertura roda em um único controller (0.0 → 1.0):

  0.00 - 0.30  entrada: logo, contorno da flor, frase, ícones e faixa
  0.24 - 0.36  a flor "respira" uma vez
  0.36 - 0.80  as pétalas são pintadas em sequência
  0.80 - 0.90  a flor completa dá um pulso
  0.86 - 1.00  o conteúdo some e vamos para o login
*/

abstract final class _Timeline {
  static const Duration duration = Duration(milliseconds: 4400);

  static const double budStart = 0.04;
  static const double budEnd = 0.22;

  static const double breathStart = 0.24;

  static const double fillStart = 0.36;
  static const double fillEnd = 0.80;

  static const double popEnd = 0.90;

  static const double exitStart = 0.86;
  static const double exitEnd = 0.97;
}

// Converte o valor global em progresso de 0 a 1 dentro do intervalo.
double _interval(
  double value,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  if (value <= begin) return curve.transform(0);
  if (value >= end) return curve.transform(1);

  return curve.transform((value - begin) / (end - begin));
}

// ================================================================
// TELA INICIAL
// ================================================================

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _started = false;

  bool _navigated = false;

  // Garante o início da animação se o carregamento demorar.
  Timer? _startFallback;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _Timeline.duration,
    );

    // Ao terminar a animação, vai sozinho para o login.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToLogin();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_started) {
      _started = true;
      _precacheAndStart();
    }
  }

  // ==============================================================
  // INÍCIO AUTOMÁTICO
  // ==============================================================

  Future<void> _precacheAndStart() async {
    // Carrega as imagens antes de animar, assim nada
    // "pisca" ou aparece atrasado no primeiro frame.
    final List<Future<void>> loading = [
      for (final String asset in _imageAssets)
        precacheImage(AssetImage(asset), context),
      for (final String asset in _svgAssets) _precacheSvg(asset),
    ];

    // Se algo demorar demais, a animação começa mesmo assim.
    _startFallback = Timer(const Duration(milliseconds: 800), _startAnimation);

    await Future.wait(loading);

    _startAnimation();
  }

  void _startAnimation() {
    _startFallback?.cancel();

    if (!mounted || _controller.isAnimating || _controller.value > 0) return;

    _controller.forward();
  }

  Future<void> _precacheSvg(String asset) async {
    final SvgAssetLoader loader = SvgAssetLoader(asset);

    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  }

  // ==============================================================
  // TOQUE NA TELA: PULA DIRETO PARA A PINTURA DAS PÉTALAS
  // ==============================================================

  void _skipToFilling() {
    if (_controller.value < _Timeline.fillStart) {
      _controller.forward(from: _Timeline.fillStart);
    }
  }

  // ==============================================================
  // TRANSIÇÃO PARA LOGIN
  // ==============================================================

  void _goToLogin() {
    if (_navigated || !mounted) return;

    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginView();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _startFallback?.cancel();
    _controller.dispose();

    super.dispose();
  }

  // ==============================================================
  // TELA
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02594F),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // Tocar em qualquer lugar adianta a animação.
        onTap: _skipToFilling,

        child: Stack(
          fit: StackFit.expand,

          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),

                child: SafeArea(
                  bottom: false,

                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool compact = constraints.maxHeight < 700;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),

                        child: Column(
                          children: [
                            SizedBox(height: compact ? 28 : 42),

                            // ======================================
                            // LOGO GRAZI BRAZ
                            // ======================================
                            _Reveal(
                              animation: _controller,
                              begin: 0.0,
                              end: 0.14,
                              slide: const Offset(0, -16),

                              child: Image.asset(
                                _logoAsset,
                                width: compact ? 110 : 125,
                                fit: BoxFit.contain,
                              ),
                            ),

                            SizedBox(height: compact ? 45 : 60),

                            // ======================================
                            // FLOR CENTRAL
                            // ======================================
                            Padding(
                              padding: const EdgeInsets.only(top: 28),

                              child: RepaintBoundary(
                                child: AnimatedFlower(
                                  animation: _controller,
                                  size: compact ? 240 : 280,
                                ),
                              ),
                            ),

                            const Spacer(),

                            // ======================================
                            // FRASE
                            // ======================================
                            _Reveal(
                              animation: _controller,
                              begin: 0.10,
                              end: 0.24,
                              slide: const Offset(0, 14),

                              child: Text(
                                'Olá, vamos começar seu treino?',

                                textAlign: TextAlign.center,

                                style: GoogleFonts.barlowCondensed(
                                  color: Colors.white,

                                  fontSize: compact ? 20 : 23,

                                  fontWeight: FontWeight.w300,

                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                            SizedBox(height: compact ? 45 : 60),

                            // ======================================
                            // ÍCONES (entram um após o outro)
                            // ======================================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                for (int i = 0; i < _iconAssets.length; i++)
                                  _Reveal(
                                    animation: _controller,
                                    begin: 0.14 + (i * 0.025),
                                    end: 0.24 + (i * 0.025),
                                    slide: const Offset(0, 18),
                                    curve: Curves.easeOutBack,

                                    child: _buildIcon(_iconAssets[i]),
                                  ),
                              ],
                            ),

                            SizedBox(height: compact ? 65 : 90),
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

              child: _Reveal(
                animation: _controller,
                begin: 0.16,
                end: 0.30,
                slide: const Offset(0, 32),

                child: Image.asset(_gradientAsset, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _iconAssets = [
    _runningAsset,
    _progressAsset,
    _trainingAsset,
    _foodAsset,
    _sheetAsset,
  ];

  // ==============================================================
  // ÍCONE
  // ==============================================================

  Widget _buildIcon(String path) {
    return SizedBox(
      width: 43,
      height: 48,

      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
}

// ==================================================================
// ENTRADA / SAÍDA DOS ELEMENTOS DA TELA
// ==================================================================

class _Reveal extends StatelessWidget {
  final Animation<double> animation;

  // Intervalo de entrada dentro da linha do tempo.
  final double begin;
  final double end;

  // Deslocamento inicial (em pixels) antes de entrar.
  final Offset slide;

  final Curve curve;

  final Widget child;

  const _Reveal({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.slide = Offset.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,

      builder: (context, child) {
        final double value = animation.value;

        final double enter = _interval(value, begin, end, curve);

        final double exit = _interval(
          value,
          _Timeline.exitStart,
          _Timeline.exitEnd,
          Curves.easeIn,
        );

        final double opacity = (_interval(value, begin, end) * (1 - exit))
            .clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,

          child: Transform.translate(offset: slide * (1 - enter), child: child),
        );
      },
    );
  }
}

// ==================================================================
// FLOR ANIMADA
// ==================================================================

class AnimatedFlower extends StatelessWidget {
  final Animation<double> animation;

  final double size;

  const AnimatedFlower({
    super.key,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Os SVGs não mudam durante a animação; só são
    // criados uma vez e reaproveitados a cada frame.
    final Widget outline = SvgPicture.asset(
      _flowerOutlineAsset,
      width: size,
      height: size,
    );

    final List<Widget> petals = [
      for (final String asset in _petalAssets)
        SvgPicture.asset(asset, width: size, height: size),
    ];

    return SizedBox(
      width: size,
      height: size,

      child: AnimatedBuilder(
        animation: animation,

        builder: (context, child) {
          final double value = animation.value;

          // ============================================
          // ENTRADA DO CONTORNO (gira e cresce)
          // ============================================
          final double budIn = _interval(
            value,
            _Timeline.budStart,
            _Timeline.budEnd,
          );

          final double budScale = Curves.easeOutBack.transform(budIn);

          final double budTurn =
              (1 - Curves.easeOutCubic.transform(budIn)) * -0.9;

          final double budOpacity = _interval(
            value,
            _Timeline.budStart,
            _Timeline.budStart + 0.08,
            Curves.easeOut,
          );

          // ============================================
          // RESPIRAÇÃO ANTES DE PINTAR
          // ============================================
          final double breath = _interval(
            value,
            _Timeline.breathStart,
            _Timeline.fillStart,
          );

          final double breathWave = _bump(breath);

          // ============================================
          // PINTURA DAS PÉTALAS
          // ============================================
          final double filling = _interval(
            value,
            _Timeline.fillStart,
            _Timeline.fillEnd,
          );

          // ============================================
          // PULSO DA FLOR COMPLETA
          // ============================================
          final double pop = _bump(
            _interval(value, _Timeline.fillEnd, _Timeline.popEnd),
          );

          // ============================================
          // SAÍDA (leve zoom enquanto a tela troca)
          // ============================================
          final double exit = _interval(
            value,
            _Timeline.exitStart,
            1.0,
            Curves.easeInOut,
          );

          final double groupScale =
              budScale *
              (1 + (0.06 * breathWave) + (0.07 * pop)) *
              (1 + (0.06 * exit));

          // Brilho suave atrás da flor.
          final double glow =
              (0.12 * breathWave) +
              (0.16 * math.sin(filling * math.pi)) +
              (0.22 * pop);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,

            children: [
              _buildGlow(opacity: glow * budOpacity, radius: size * 0.5),

              Opacity(
                opacity: budOpacity,

                child: Transform.rotate(
                  angle: budTurn,

                  child: Transform.scale(
                    scale: groupScale,

                    child: Stack(
                      alignment: Alignment.center,

                      children: [
                        outline,

                        for (int i = 0; i < petals.length; i++)
                          _buildPetal(
                            index: i,
                            filling: filling,
                            petal: petals[i],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sobe e desce suavemente: 0 → 1 → 0.
  static double _bump(double t) {
    return math.pow(math.sin(t * math.pi), 2).toDouble();
  }

  // =================================================================
  // BRILHO
  // =================================================================

  Widget _buildGlow({required double opacity, required double radius}) {
    if (opacity <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        width: radius * 2.4,
        height: radius * 2.4,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // UMA PÉTALA
  // =================================================================

  Widget _buildPetal({
    required int index,
    required double filling,
    required Widget petal,
  }) {
    /*
      Cada pétala começa um pouco depois da anterior,
      no sentido horário.

      A tinta "escorre" do centro da flor até a ponta
      da pétala, com um recorte circular que cresce.
    */

    final double start = index * 0.09;

    final double progress = _interval(
      filling,
      start,
      start + 0.37,
      Curves.easeOutCubic,
    );

    if (progress <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: (progress * 1.6).clamp(0.0, 1.0),

      child: ClipOval(clipper: _GrowingCircleClipper(progress), child: petal),
    );
  }
}

// ==================================================================
// RECORTE CIRCULAR QUE CRESCE A PARTIR DO CENTRO
// ==================================================================

class _GrowingCircleClipper extends CustomClipper<Rect> {
  final double progress;

  _GrowingCircleClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // Raio suficiente para cobrir a ponta das pétalas.
    final double maxRadius = size.shortestSide * 0.52;

    return Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: maxRadius * progress,
    );
  }

  @override
  bool shouldReclip(covariant _GrowingCircleClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
