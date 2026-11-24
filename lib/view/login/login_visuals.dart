import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:academiagrazi/view/login/login_scene.dart';
import 'package:flutter/material.dart';

/// As duas imagens permanecem montadas: a troca não recria o formulário.
/// O degradê é uma máscara neutra de legibilidade, não o gradiente da marca.
class LoginScenery extends StatelessWidget {
  final TrainingMode mode;
  final bool reduceMotion;

  const LoginScenery({
    super.key,
    required this.mode,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final duration =
        reduceMotion ? Duration.zero : LoginPresentation.transition;
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.background),
          for (final scene in LoginPresentation.scenes)
            RepaintBoundary(
              child: AnimatedOpacity(
                key: ValueKey('fundo_login_${scene.mode.name}'),
                opacity: scene.mode == mode ? 1 : 0,
                duration: duration,
                curve: Curves.easeInOutCubic,
                child: Image.asset(
                  scene.imageAsset,
                  fit: BoxFit.cover,
                  alignment:
                      scene.mode == TrainingMode.presencial
                          ? const Alignment(0.15, -0.25)
                          : const Alignment(0, -0.15),
                  filterQuality: FilterQuality.medium,
                  errorBuilder:
                      (_, _, _) =>
                          const ColoredBox(color: AppColors.background),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.30, 0.56, 0.78, 1],
                colors: [
                  AppColors.background.withValues(alpha: 0.94),
                  AppColors.background.withValues(alpha: 0.8),
                  AppColors.background.withValues(alpha: 0.11),
                  AppColors.background.withValues(alpha: 0.3),
                  AppColors.background.withValues(alpha: 0.97),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginBrand extends StatelessWidget {
  const LoginBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Grazi Braz',
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          LoginPresentation.logoAsset,
          key: const Key('logo_login'),
          height: 64,
          fit: BoxFit.contain,
          color: AppColors.primary,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder:
              (_, _, _) => const SizedBox(
                height: 64,
                child: Center(
                  child: Text(
                    'GRAZI BRAZ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// Os dois textos participam do layout, mas só um aparece. Assim a altura
/// permanece idêntica ao alternar, inclusive com texto ampliado pelo sistema.
class LoginSceneCopy extends StatelessWidget {
  final TrainingMode mode;
  final bool reduceMotion;

  const LoginSceneCopy({
    super.key,
    required this.mode,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        for (final scene in LoginPresentation.scenes)
          ExcludeSemantics(
            excluding: scene.mode != mode,
            child: AnimatedOpacity(
              opacity: scene.mode == mode ? 1 : 0,
              duration:
                  reduceMotion ? Duration.zero : LoginPresentation.transition,
              child: Text(
                scene.description,
                key: ValueKey('texto_login_${scene.mode.name}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppFontSize.body,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoginModeSelector extends StatelessWidget {
  final TrainingMode mode;
  final bool enabled;
  final bool reduceMotion;
  final ValueChanged<TrainingMode> onChanged;

  const LoginModeSelector({
    super.key,
    required this.mode,
    required this.enabled,
    required this.reduceMotion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.surface),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final scene in LoginPresentation.scenes)
              Expanded(
                child: Semantics(
                  key: ValueKey('modo_login_${scene.mode.name}'),
                  selected: mode == scene.mode,
                  child: AnimatedContainer(
                    duration:
                        reduceMotion
                            ? Duration.zero
                            : LoginPresentation.transition,
                    curve: Curves.easeInOutCubic,
                    decoration: BoxDecoration(
                      color:
                          mode == scene.mode
                              ? AppColors.primaryDark
                              : AppColors.surface.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: TextButton(
                      onPressed: enabled ? () => onChanged(scene.mode) : null,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        foregroundColor:
                            mode == scene.mode
                                ? AppColors.surface
                                : AppColors.textSecondary,
                        disabledForegroundColor:
                            mode == scene.mode
                                ? AppColors.surface
                                : AppColors.textSecondary,
                        shape: const StadiumBorder(),
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(
                          fontSize: AppFontSize.small,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(scene.label, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoginFormSurface extends StatelessWidget {
  final Widget child;

  const LoginFormSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surface),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: child,
      ),
    );
  }
}
