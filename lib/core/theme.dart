import 'package:flutter/material.dart';

/// Semantic colour tokens. Widgets read them through `context.gb` so light and
/// dark mode switch together and nothing hard-codes a colour.
///
/// The palette is intentionally small: warm neutrals for structure, one clay
/// accent for actions, ink for the root note, and muted green / red for
/// feedback. Everything else is expressed with hairlines and spacing.
/// Semantic colour tokens. Widgets read them through `context.gb` so light and
/// dark mode switch together and nothing hard-codes a colour.
///
/// The palette follows docs/DESIGN.md: warm paper, ink, one clay accent, and
/// muted green / red that only appear on the fretboard and the score marks.
@immutable
class GbColors extends ThemeExtension<GbColors> {
  /// Page background (paper).
  final Color canvas;

  /// Raised surfaces: dialogs, menus, note chips.
  final Color surface;

  /// Filled controls.
  final Color surfaceMuted;

  /// Fretboard background.
  final Color sunken;

  /// 1 px section rules.
  final Color hairline;

  /// Separators that must read on [hairline] areas.
  final Color strongLine;

  /// Outlined button borders.
  final Color controlLine;

  /// Borders of in-key note chips.
  final Color chip;
  final Color textPrimary;

  /// Body copy on the fretboard and in summaries.
  final Color textBody;
  final Color textSecondary;
  final Color textMuted;

  /// The one accent: primary button and the current state only.
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  /// Root note and first-try marks.
  final Color ink;
  final Color onInk;
  final Color correct;
  final Color correctSoft;
  final Color wrong;
  final Color wrongSoft;

  /// Strings 1–3.
  final Color stringPlain;

  /// Strings 4–6.
  final Color stringWound;

  /// Fret wires.
  final Color fretWire;

  /// The nut.
  final Color nut;

  /// Fret-marker inlays.
  final Color inlay;

  const GbColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.sunken,
    required this.hairline,
    required this.strongLine,
    required this.controlLine,
    required this.chip,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.ink,
    required this.onInk,
    required this.correct,
    required this.correctSoft,
    required this.wrong,
    required this.wrongSoft,
    required this.stringPlain,
    required this.stringWound,
    required this.fretWire,
    required this.nut,
    required this.inlay,
  });

  static const light = GbColors(
    canvas: Color(0xFFFAF9F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1EFE8),
    sunken: Color(0xFFF1EFE8),
    hairline: Color(0xFFE5E2D9),
    strongLine: Color(0xFFC9C5B9),
    controlLine: Color(0xFFDAD6CB),
    chip: Color(0xFFD8D4C8),
    textPrimary: Color(0xFF1F1E1B),
    textBody: Color(0xFF3A3935),
    textSecondary: Color(0xFF57554F),
    textMuted: Color(0xFF75736C),
    accent: Color(0xFFB5552F),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFF6E9E2),
    ink: Color(0xFF1F1E1B),
    onInk: Color(0xFFFFFFFF),
    correct: Color(0xFF2E6F4E),
    correctSoft: Color(0xFFE3EFE7),
    wrong: Color(0xFFA8402E),
    wrongSoft: Color(0xFFF6E4DF),
    stringPlain: Color(0xFFB4B0A5),
    stringWound: Color(0xFF9C988D),
    fretWire: Color(0xFFD3CFC3),
    nut: Color(0xFF57554F),
    inlay: Color(0xFFD3CFC3),
  );

  static const dark = GbColors(
    canvas: Color(0xFF1E1D1B),
    surface: Color(0xFF262522),
    surfaceMuted: Color(0xFF2C2B28),
    sunken: Color(0xFF262522),
    hairline: Color(0xFF34332F),
    strongLine: Color(0xFF4A4843),
    controlLine: Color(0xFF45433E),
    chip: Color(0xFF4A4843),
    textPrimary: Color(0xFFECEAE3),
    textBody: Color(0xFFD6D3CA),
    textSecondary: Color(0xFFB8B4AA),
    textMuted: Color(0xFF8F8B82),
    accent: Color(0xFFDB7C5A),
    onAccent: Color(0xFF1E1D1B),
    accentSoft: Color(0xFF3A2A23),
    ink: Color(0xFFECEAE3),
    onInk: Color(0xFF1E1D1B),
    correct: Color(0xFF74C394),
    correctSoft: Color(0xFF23332A),
    wrong: Color(0xFFEA8A78),
    wrongSoft: Color(0xFF3B2622),
    stringPlain: Color(0xFF6B6860),
    stringWound: Color(0xFF7D7A71),
    fretWire: Color(0xFF3D3B37),
    nut: Color(0xFFB8B4AA),
    inlay: Color(0xFF57554F),
  );

  @override
  GbColors copyWith() => this;

  @override
  GbColors lerp(ThemeExtension<GbColors>? other, double t) {
    if (other is! GbColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GbColors(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      sunken: l(sunken, other.sunken),
      hairline: l(hairline, other.hairline),
      strongLine: l(strongLine, other.strongLine),
      controlLine: l(controlLine, other.controlLine),
      chip: l(chip, other.chip),
      textPrimary: l(textPrimary, other.textPrimary),
      textBody: l(textBody, other.textBody),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
      correct: l(correct, other.correct),
      correctSoft: l(correctSoft, other.correctSoft),
      wrong: l(wrong, other.wrong),
      wrongSoft: l(wrongSoft, other.wrongSoft),
      stringPlain: l(stringPlain, other.stringPlain),
      stringWound: l(stringWound, other.stringWound),
      fretWire: l(fretWire, other.fretWire),
      nut: l(nut, other.nut),
      inlay: l(inlay, other.inlay),
    );
  }
}

extension GbThemeContext on BuildContext {
  GbColors get gb => Theme.of(this).extension<GbColors>() ?? GbColors.light;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Platform-neutral visual system shared by every GuitarBridge target.
class AppTheme {
  AppTheme._();

  static const String sans = 'NotoSansSC';
  static const String serif = 'NotoSerifSC';
  static const String mono = 'JetBrainsMono';

  /// Numbers, fret numbers, question counters and key hints. Chinese inside a
  /// mono run falls back to the sans family.
  static TextStyle monoStyle({
    double size = 12.5,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: mono,
    fontFamilyFallback: const [sans],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.4,
  );

  /// The serif display face used for note names and conclusions.
  static TextStyle serifStyle({
    double size = 22,
    Color? color,
    FontWeight weight = FontWeight.w600,
    double height = 1.25,
    bool italic = false,
  }) => TextStyle(
    fontFamily: serif,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  static const double contentMaxWidth = 1280;
  static const double radius = 12;
  static const double controlRadius = 8;

  static ThemeData light() => _build(Brightness.light, GbColors.light);
  static ThemeData dark() => _build(Brightness.dark, GbColors.dark);

  /// Kept for callers that predate dark mode.
  static ThemeData trainingTheme() => light();

  static ThemeData _build(Brightness brightness, GbColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.ink,
      onSecondary: c.onInk,
      secondaryContainer: c.surfaceMuted,
      onSecondaryContainer: c.textPrimary,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
      error: c.wrong,
      onError: c.onAccent,
      outline: c.strongLine,
      outlineVariant: c.hairline,
      shadow: Colors.black,
    );

    TextStyle serifStyle(double size, {double height = 1.25}) => TextStyle(
      fontFamily: AppTheme.serif,
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      letterSpacing: 0,
    );
    TextStyle sansStyle(double size, FontWeight weight, Color color) =>
        TextStyle(
          fontFamily: sans,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.5,
        );

    final textTheme = TextTheme(
      displaySmall: serifStyle(32, height: 1.2),
      headlineSmall: serifStyle(22),
      titleLarge: serifStyle(19),
      titleMedium: sansStyle(15, FontWeight.w600, c.textPrimary),
      titleSmall: sansStyle(13, FontWeight.w600, c.textPrimary),
      bodyLarge: sansStyle(15, FontWeight.w400, c.textPrimary),
      bodyMedium: sansStyle(13.5, FontWeight.w400, c.textSecondary),
      bodySmall: sansStyle(12, FontWeight.w400, c.textMuted),
      labelLarge: sansStyle(14, FontWeight.w500, c.textPrimary),
      labelMedium: sansStyle(12, FontWeight.w500, c.textSecondary),
      labelSmall: sansStyle(11, FontWeight.w500, c.textMuted),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    const buttonText = TextStyle(
      fontFamily: sans,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: sans,
      textTheme: textTheme,
      extensions: [c],
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.hairline,
      dividerTheme: DividerThemeData(color: c.hairline, space: 1, thickness: 1),
      splashFactory: InkSparkle.splashFactory,
      hoverColor: c.textPrimary.withAlpha(10),
      highlightColor: Colors.transparent,
      focusColor: c.accent.withAlpha(30),
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: serifStyle(19),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: c.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        isDense: true,
        labelStyle: TextStyle(
          fontFamily: sans,
          color: c.textMuted,
          fontSize: 13,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: sans,
          color: c.textMuted,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: c.accent, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.surfaceMuted,
          disabledForegroundColor: c.textMuted,
          minimumSize: const Size(44, 44),
          padding: buttonPadding,
          shape: controlShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          disabledForegroundColor: c.textMuted,
          minimumSize: const Size(44, 44),
          padding: buttonPadding,
          side: BorderSide(color: c.controlLine),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textSecondary,
          minimumSize: const Size(44, 44),
          shape: controlShape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: c.hairline)),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: sans, fontSize: 13),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.surfaceMuted
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textSecondary,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.hairline,
        thumbColor: c.accent,
        overlayColor: c.accent.withAlpha(30),
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onAccent : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.accent : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : c.strongLine,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.hairline,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.hairline),
        ),
        textStyle: TextStyle(
          fontFamily: sans,
          color: c.textPrimary,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: serifStyle(19),
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          fontFamily: sans,
          color: c.onInk,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(fontFamily: sans, color: c.onInk, fontSize: 12),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: c.textSecondary,
        collapsedIconColor: c.textSecondary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
