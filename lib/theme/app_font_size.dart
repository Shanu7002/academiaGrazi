/// Escala única de tamanhos de fonte do app (AGENTS.md §7.1).
///
/// Nenhuma tela usa `fontSize` com número solto: escolha o degrau pelo
/// papel do texto. Barlow Condensed é estreita, por isso o menor degrau é
/// 13, para continuar legível.
abstract final class AppFontSize {
  /// Rótulos pequenos, sobretítulos em caixa alta, selos e badges.
  static const double caption = 13;

  /// Legendas, texto secundário e informações de apoio.
  static const double small = 15;

  /// Texto corrido, nomes em listas, campos.
  static const double body = 17;

  /// Título de cartão ou de item de destaque.
  static const double subtitle = 20;

  /// Título de seção.
  static const double title = 24;

  /// Título da página.
  static const double headline = 30;

  /// Números grandes de métrica (dashboards, contadores).
  static const double display = 44;
}
