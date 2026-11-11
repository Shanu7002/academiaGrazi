import 'package:academiagrazi/theme/app_colors.dart';
import 'package:academiagrazi/theme/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema do app segundo o manual de marca (AGENTS.md §7): Barlow Condensed
/// como fonte única, verde institucional, laranja nos CTAs e fundo
/// off-white com cartões brancos.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      tertiary: AppColors.info,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    final base = GoogleFonts.barlowCondensedTextTheme();
    // Tracking levemente aberto, como pede o manual.
    final textTheme = base
        .apply(
          bodyColor: AppColors.textBody,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: AppFontSize.body,
            letterSpacing: 0.2,
            color: AppColors.textBody,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: AppFontSize.small,
            letterSpacing: 0.2,
            color: AppColors.textBody,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: AppFontSize.caption,
            letterSpacing: 0.2,
            color: AppColors.textSecondary,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: AppFontSize.title,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: AppFontSize.subtitle,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.textPrimary,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: AppFontSize.headline,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontSize: AppFontSize.display,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        );

    final buttonText = GoogleFonts.barlowCondensed(
      fontSize: AppFontSize.body,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.subtitle,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: AppColors.primary,
        ),
      ),
      // CTA principal: laranja (cor de impacto) com texto branco em negrito.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.inactive,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      // Ação secundária: contorno verde institucional.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.body,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.body,
          color: AppColors.textMuted,
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.small,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        selectedColor: AppColors.primaryChipSurface,
        side: const BorderSide(color: AppColors.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.body,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.title,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.primary,
        ),
        contentTextStyle: GoogleFonts.barlowCondensed(
          fontSize: AppFontSize.body,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.accent,
        backgroundColor: AppColors.surface,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.barlowCondensed(
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
