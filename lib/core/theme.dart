import 'package:flutter/material.dart';

/// Platform-neutral visual system shared by every GuitarBridge target.
///
/// The app deliberately avoids platform-specific chrome so Windows, macOS,
/// Linux, mobile, and web all present the same training workspace.
class AppTheme {
  AppTheme._();

  // A warm, paper-like canvas keeps the training surface calm and lets the
  // few meaningful colors (root, answer and feedback) carry the hierarchy.
  // These values intentionally stay platform-neutral so desktop and mobile
  // share the same visual language.
  static const Color backgroundColor = Color(0xFFF3F0E9);
  static const Color surfaceColor = Color(0xFFFFFCF7);
  static const Color raisedSurfaceColor = Color(0xFFF0ECE4);
  static const Color subtleSurfaceColor = Color(0xFFF8F5EF);
  static const Color primaryColor = Color(0xFFD7614D);
  static const Color secondaryColor = Color(0xFF245C58);
  static const Color accentColor = Color(0xFFE3A34B);
  static const Color correctColor = Color(0xFF3D8B67);
  static const Color wrongColor = Color(0xFFC84E57);
  static const Color textPrimary = Color(0xFF1D2A2B);
  static const Color textSecondary = Color(0xFF536365);
  static const Color textMuted = Color(0xFF7C8989);
  static const Color outlineColor = Color(0xFFD8D3C8);
  static const Color fretboardWood = Color(0xFFE8D9C6);
  static const Color stringColor = Color(0xFF88928F);
  static const Color fretMarkerColor = Color(0xFFC7B9A5);

  static const double contentMaxWidth = 1440;
  static const double panelRadius = 22;

  static Color toneColor(String toneMode) {
    switch (toneMode.toLowerCase()) {
      case 'overdrive':
        return const Color(0xFFFFB86B);
      case 'distortion':
        return const Color(0xFFFF7185);
      default:
        return primaryColor;
    }
  }

  static ThemeData trainingTheme(String toneMode) {
    final tone = toneColor(toneMode);
    final scheme = ColorScheme.light(
      primary: tone,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
      error: wrongColor,
      onError: Colors.white,
      outline: outlineColor,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(panelRadius),
      side: const BorderSide(color: outlineColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: outlineColor,
      splashColor: tone.withAlpha(24),
      highlightColor: tone.withAlpha(14),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 34,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13, height: 1.45),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: roundedShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: subtleSurfaceColor,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tone, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tone,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tone,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: outlineColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtleSurfaceColor,
        selectedColor: tone.withAlpha(32),
        disabledColor: subtleSurfaceColor,
        side: const BorderSide(color: outlineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        secondaryLabelStyle: TextStyle(
          color: tone,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tone,
        inactiveTrackColor: outlineColor,
        thumbColor: tone,
        overlayColor: tone.withAlpha(24),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? tone : outlineColor,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tone,
        linearTrackColor: outlineColor,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: raisedSurfaceColor,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
