/// AGB-205: cenários de apresentação, nunca o perfil/modalidade do aluno.
/// O enum mantém o nome usado anteriormente por login_view.dart.
enum TrainingMode { presencial, home }

abstract final class LoginPresentation {
  static const rotationInterval = Duration(seconds: 5);
  static const idleInterval = Duration(seconds: 8);
  static const transition = Duration(milliseconds: 550);
  static const maxWidth = 430.0;
  static const logoAsset = 'assets/logoLogin.png';

  static const presencial = LoginScene(
    mode: TrainingMode.presencial,
    label: 'Presencial',
    imageAsset: 'assets/login/agb205_presencial.webp',
    description:
        'Treine no estúdio com orientação especializada, '
        'estrutura completa e acompanhamento de perto.',
  );

  static const home = LoginScene(
    mode: TrainingMode.home,
    label: 'Treino em casa',
    imageAsset: 'assets/login/agb205_casa.webp',
    description:
        'Treine de onde estiver, com flexibilidade, autonomia '
        'e orientação que acompanha sua rotina.',
  );

  static const scenes = [presencial, home];

  static LoginScene sceneFor(TrainingMode mode) =>
      mode == TrainingMode.presencial ? presencial : home;
}

/// Dados somente visuais: não são serializados nem enviados ao Firebase.
class LoginScene {
  final TrainingMode mode;
  final String label;
  final String imageAsset;
  final String description;

  const LoginScene({
    required this.mode,
    required this.label,
    required this.imageAsset,
    required this.description,
  });
}
