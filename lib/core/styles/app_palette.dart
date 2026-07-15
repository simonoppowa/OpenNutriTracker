import 'package:flutter/material.dart';

/// The palette behind the calm friendly-flat redesign.
///
/// A warm-neutral canvas with a gentle surface ladder carries the app; depth
/// comes from hairline borders and soft shadows, not colour. A single vivid
/// [accent] (a fresh leaf-green by default, nodding to the nutrition brand) is
/// the only loud colour and is user-overridable via the accent picker / Material
/// You. The macro trio (carbs amber, fat coral, protein teal) stays fixed so the
/// dashboard always reads the same, whatever accent is chosen.
class AppPalette {
  final Brightness brightness;
  final Color canvas; // scaffold background
  final Color surface; // cards / sheets
  final Color surfaceMuted; // secondary fills, track backgrounds
  final Color border; // hairline outline
  final Color shadow; // soft shadow colour
  final Color accent; // the one vivid colour (overridable)
  final Color onAccent;
  final Color carbsColor;
  final Color fatColor;
  final Color proteinColor;
  final Color textStrong;
  final Color textMuted;

  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.shadow,
    required this.accent,
    required this.onAccent,
    required this.carbsColor,
    required this.fatColor,
    required this.proteinColor,
    required this.textStrong,
    required this.textMuted,
  });

  Color get carbs => carbsColor;
  Color get fat => fatColor;
  Color get protein => proteinColor;

  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF7F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFEAE1),
    border: Color(0xFFE7E1D6),
    shadow: Color(0x14403A2E),
    // Deepened from #1FA971 so white-on-accent and accent-as-text both clear
    // WCAG AA (~4.6:1) on the light surface — buttons, nav labels and the ring.
    accent: Color(0xFF0E7A4D),
    onAccent: Color(0xFFFFFFFF),
    carbsColor: Color(0xFFB87410),
    fatColor: Color(0xFFD05536),
    proteinColor: Color(0xFF1F8E80),
    textStrong: Color(0xFF2B2A27),
    // Darkened from #8A857C (~3.5:1) to ~4.6:1 so secondary text passes AA.
    textMuted: Color(0xFF6E685E),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF1B1A18),
    surface: Color(0xFF252320),
    surfaceMuted: Color(0xFF302D28),
    border: Color(0xFF38352F),
    shadow: Color(0x33000000),
    accent: Color(0xFF34D08A),
    onAccent: Color(0xFF06281A),
    carbsColor: Color(0xFFF2B45A),
    fatColor: Color(0xFFFF937B),
    proteinColor: Color(0xFF49C9B8),
    textStrong: Color(0xFFECE8E1),
    textMuted: Color(0xFFA39E94),
  );

  /// Returns a copy with the accent swapped for [newAccent] (accent picker or a
  /// harmonized Material You primary). The neutral canvas, surfaces and macro
  /// colours are untouched, so only the one vivid role follows the user.
  AppPalette withAccent(Color newAccent) {
    final onNew = ThemeData.estimateBrightnessForColor(newAccent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF20201C);
    return AppPalette(
      brightness: brightness,
      canvas: canvas,
      surface: surface,
      surfaceMuted: surfaceMuted,
      border: border,
      shadow: shadow,
      accent: newAccent,
      onAccent: onNew,
      carbsColor: carbsColor,
      fatColor: fatColor,
      proteinColor: proteinColor,
      textStrong: textStrong,
      textMuted: textMuted,
    );
  }

  ColorScheme get colorScheme => ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: accent,
        onPrimaryContainer: onAccent,
        secondary: proteinColor,
        onSecondary: onAccent,
        secondaryContainer: surfaceMuted,
        onSecondaryContainer: textStrong,
        tertiary: carbsColor,
        onTertiary: onAccent,
        tertiaryContainer: surfaceMuted,
        onTertiaryContainer: textStrong,
        error: brightness == Brightness.light ? const Color(0xFFC4453A) : const Color(0xFFFFB4AB),
        onError: brightness == Brightness.light ? Colors.white : const Color(0xFF690005),
        surface: surface,
        onSurface: textStrong,
        surfaceContainerLowest: canvas,
        surfaceContainerLow: canvas,
        surfaceContainer: surfaceMuted,
        surfaceContainerHigh: surfaceMuted,
        surfaceContainerHighest: surfaceMuted,
        onSurfaceVariant: textMuted,
        outline: border,
        outlineVariant: border,
        surfaceTint: Colors.transparent,
        shadow: shadow,
      );
}
