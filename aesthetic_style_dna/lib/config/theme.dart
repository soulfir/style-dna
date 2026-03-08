import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgDeepest = Color(0xFF050507);
  static const bgBase = Color(0xFF0C0C10);
  static const bgSurface = Color(0xFF141418);
  static const bgSurfaceHover = Color(0xFF1A1A20);
  static const bgElevated = Color(0xFF1E1E26);
  static const bgOverlay = Color(0xFF24242E);
  static const borderSubtle = Color(0xFF2A2A36);
  static const borderDefault = Color(0xFF3A3A48);
  static const borderFocus = Color(0xFF6E56CF);
  static const textPrimary = Color(0xFFEEEEF0);
  static const textSecondary = Color(0xFFA0A0B0);
  static const textTertiary = Color(0xFF6B6B80);
  static const textMuted = Color(0xFF4A4A5C);

  static const accentPrimary = Color(0xFF6E56CF);
  static const accentPrimaryHover = Color(0xFF7C66D9);
  static const accentPrimaryMuted = Color(0x266E56CF);
  static const accentSecondary = Color(0xFFE5484D);
  static const accentWarm = Color(0xFFF5A623);
  static const accentSuccess = Color(0xFF30A46C);
}

class StyleDNAColors {
  static const colorGrading = Color(0xFFE5484D);
  static const lighting = Color(0xFFF5A623);
  static const texture = Color(0xFF87CEAB);
  static const composition = Color(0xFF5B9EE9);
  static const contrast = Color(0xFFEEEEF0);
  static const atmosphere = Color(0xFFB07CD8);

  static const List<Color> all = [
    colorGrading,
    lighting,
    texture,
    composition,
    contrast,
    atmosphere,
  ];

  static const List<String> labels = [
    'Color',
    'Light',
    'Texture',
    'Comp',
    'Contrast',
    'Atmos',
  ];
}

class AppGradients {
  static const dnaRainbow = LinearGradient(
    colors: [
      Color(0xFFE5484D),
      Color(0xFFF5A623),
      Color(0xFF87CEAB),
      Color(0xFF5B9EE9),
      Color(0xFFB07CD8),
    ],
  );

  static const shimmer = LinearGradient(
    colors: [Color(0xFF141418), Color(0xFF1E1E26), Color(0xFF141418)],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTypography {
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMd => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingLg => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMd => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );

  static TextStyle get tag => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );
}

class GlassEffect {
  static Widget light({required Widget child, double borderRadius = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDeepest,
    canvasColor: AppColors.bgBase,
    cardColor: AppColors.bgSurface,
    dividerColor: AppColors.borderSubtle,
    primaryColor: AppColors.accentPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPrimary,
      secondary: AppColors.accentWarm,
      surface: AppColors.bgSurface,
      error: AppColors.accentSecondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headingLg,
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.accentPrimary.withValues(alpha: 0.4);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentPrimaryHover;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentPrimary.withValues(alpha: 0.85);
          }
          return AppColors.accentPrimary;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.labelLg),
        mouseCursor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return SystemMouseCursors.forbidden;
          }
          return SystemMouseCursors.click;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.textTertiary);
          }
          return const BorderSide(color: AppColors.borderDefault);
        }),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.labelLg),
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
      ),
    ),
  );
}
