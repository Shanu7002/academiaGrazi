import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nível do título: da página (topo da tela) ou de uma seção.
enum BrandHeadingLevel { page, section }

/// Título no padrão do manual de marca: `PALAVRA EM CAIXA ALTA /
/// Complemento em itálico` (AGENTS.md §7.1).
///
/// O [title] sempre aparece em caixa alta, verde e SemiBold; o
/// [complement], quando houver, vem depois da barra, em itálico leve.
/// Uma [description] opcional entra abaixo, como texto de apoio.
class BrandHeading extends StatelessWidget {
  final String title;
  final String? complement;
  final String? description;
  final BrandHeadingLevel level;

  /// Cor do título sobre fundos escuros (ex.: branco sobre o verde).
  final Color color;

  const BrandHeading(
    this.title, {
    super.key,
    this.complement,
    this.description,
    this.level = BrandHeadingLevel.page,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final size =
        level == BrandHeadingLevel.page
            ? AppFontSize.headline
            : AppFontSize.title;
    final heading = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title.toUpperCase(),
            style: GoogleFonts.barlowCondensed(
              fontSize: size,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              height: 1.1,
              color: color,
            ),
          ),
          if (complement != null && complement!.trim().isNotEmpty)
            TextSpan(
              text: ' / ${complement!.trim()}',
              style: GoogleFonts.barlowCondensed(
                fontSize: size,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.4,
                height: 1.1,
                color: color,
              ),
            ),
        ],
      ),
    );
    if (description == null || description!.trim().isEmpty) return heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        const SizedBox(height: 6),
        Text(
          description!,
          style: GoogleFonts.barlowCondensed(
            fontSize: AppFontSize.small,
            height: 1.35,
            letterSpacing: 0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
