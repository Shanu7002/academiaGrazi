import 'package:flutter/material.dart';

/// Cores do app, todas derivadas do manual de marca Grazi Braz (AGENTS.md
/// §7.1). Única fonte de cor: nenhuma tela usa `Color(0x…)` direto.
///
/// Paleta oficial: laranja `#E37747` (impacto), verde `#02594F`
/// (institucional), amarelo `#F2BE48` (ponto de luz) e azul `#2A327B`
/// (atenção/respiro), mais o cinza de texto e o off-white de fundo. Os
/// demais tokens são nuances claras (misturadas com branco) ou escuras
/// dessas cores, para superfícies, bordas e contraste de leitura.
abstract final class AppColors {
  // Paleta oficial da marca
  static const Color brandOrange = Color(0xFFE37747);
  static const Color brandGreen = Color(0xFF02594F);
  static const Color brandYellow = Color(0xFFF2BE48);
  static const Color brandIndigo = Color(0xFF2A327B);
  static const Color brandGray = Color(0xFF707070);
  static const Color brandOffWhite = Color(0xFFEBE8E6);

  // Marca (papéis)
  static const Color primary = brandGreen;
  static const Color primaryDark = Color(0xFF013E37);
  static const Color primaryText = brandGreen;
  static const Color accent = brandOrange;
  static const Color accentDark = Color(0xFF8D4A2C);

  /// Texto e ícones sobre o laranja (botões, selos). Use em negrito ou
  /// tamanho grande: branco sobre laranja tem contraste 3:1.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Ponto de luz: só sobre o verde ou como detalhe (sobre fundo claro o
  /// amarelo fica ilegível).
  static const Color highlight = brandYellow;

  // Fundos e superfícies
  static const Color background = brandOffWhite;
  static const Color trainingListBackground = brandOffWhite;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF5F4F2);
  static const Color headerSurface = Color(0xFFFFFFFF);
  static const Color slateSurface = Color(0xFFF5F4F2);

  // Texto
  /// Títulos, números e texto de destaque.
  static const Color textPrimary = brandGreen;

  /// Texto corrido do manual. Só sobre superfícies brancas (cartões).
  static const Color textBody = brandGray;

  /// Legendas e rótulos; tom mais escuro que o cinza do manual para
  /// também ser legível sobre o fundo off-white.
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color slateText = Color(0xFF5C5C5C);

  /// Placeholders e estados desabilitados (não usar em texto essencial).
  static const Color textMuted = Color(0xFF8C8C8C);

  // Bordas e estados neutros
  static const Color border = Color(0xFFDCD8D5);
  static const Color borderTranslucent = Color(0xCCDCD8D5);
  static const Color borderSoftAlpha = Color(0xB3DCD8D5);
  static const Color inactive = Color(0xFFC4BFBC);

  // Verde / sucesso
  static const Color success = brandGreen;
  static const Color successSurface = Color(0xFFEDF3F3);
  static const Color successBorder = Color(0xFFCCDEDC);
  static const Color completedBorder = Color(0xFF9ABDB9);
  static const Color primaryGradientEnd = Color(0xFFEDF3F3);
  static const Color primaryBorderAlpha = Color(0x6602594F);
  static const Color primaryBadgeSurface = Color(0xFFE1EBEA);
  static const Color primaryActionSurface = Color(0xFFE1EBEA);
  static const Color primaryActionBorder = Color(0xFFCCDEDC);
  static const Color primarySoftBorder = Color(0xFFCCDEDC);
  static const Color primaryChipSurface = Color(0xFFE1EBEA);
  static const Color primaryChipBorder = Color(0xFFCCDEDC);
  static const Color progressTrack = Color(0xFFE1EBEA);
  static const Color avatarBackground = Color(0xFFE1EBEA);
  static const Color mintBorderBright = Color(0xFF9ABDB9);
  static const Color teal = brandGreen;

  // Laranja / destaque
  static const Color accentSurface = Color(0xFFFCEFE9);
  static const Color accentSurfaceTransparent = Color(0x1AE37747);
  static const Color accentBorderTransparent = Color(0x33E37747);

  /// Texto sobre as superfícies laranja-claras (alertas).
  static const Color accentText = Color(0xFF8D4A2C);
  static const Color accentAlertSurface = Color(0xFFFCEFE9);
  static const Color accentAlertBorder = Color(0xFFF4C9B5);

  // Informação / atenção (azul do manual, com moderação)
  static const Color info = brandIndigo;
  static const Color infoSurface = Color(0xFFF0F1F6);
  static const Color infoSoftSurface = Color(0xFFE5E6EF);

  // Erro / ação destrutiva. Única cor fora da paleta: erro precisa ser
  // reconhecível e não pode se confundir com o laranja dos botões.
  static const Color danger = Color(0xFF93000A);
  static const Color dangerSurface = Color(0xFFFFDAD6);

  // Gráficos
  static const Color chartBar = Color(0xFF9ABDB9);
  static const Color chartBarInactive = Color(0xFFE1EBEA);

  // Thumbnails
  static const Color thumbnailStart = Color(0xFFE1EBEA);

  // Sombras e overlays
  static const Color shadowFaint = Color(0x0A02594F);
  static const Color shadowCard = Color(0x0F02594F);
  static const Color shadowSoft = Color(0x1402594F);
  static const Color white90 = Color(0xE6FFFFFF);

  /// Mantido por compatibilidade: era o azul-marinho, agora o verde escuro.
  static const Color navy = primaryDark;
}
