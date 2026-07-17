import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// Friendly, highly readable type. Nunito carries everything — rounded enough to
/// feel warm, calm enough to stay legible in dense lists. Heavy weights give the
/// hero numbers presence without needing a separate display face.
TextTheme appTextTheme(AppPalette p) {
  const f = 'Nunito';
  TextStyle s(double size, FontWeight w, {double spacing = 0, Color? color}) =>
      TextStyle(fontFamily: f, fontSize: size, fontWeight: w, letterSpacing: spacing, color: color ?? p.textStrong);
  return TextTheme(
    displayLarge: s(57, FontWeight.w800, spacing: -1),
    displayMedium: s(45, FontWeight.w800, spacing: -0.5),
    displaySmall: s(36, FontWeight.w800),
    headlineLarge: s(32, FontWeight.w800),
    headlineMedium: s(28, FontWeight.w700),
    headlineSmall: s(23, FontWeight.w700),
    titleLarge: s(21, FontWeight.w700),
    titleMedium: s(16, FontWeight.w700),
    titleSmall: s(14, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w500),
    bodyMedium: s(14, FontWeight.w500),
    bodySmall: s(12.5, FontWeight.w500, color: p.textMuted),
    labelLarge: s(15, FontWeight.w700),
    labelMedium: s(13, FontWeight.w700),
    labelSmall: s(11.5, FontWeight.w700, color: p.textMuted),
  );
}

/// Builds the friendly-flat [ThemeData] for a palette. Component themes carry
/// the rounded shapes and flat surfaces so the look propagates app-wide; depth
/// lives in the [AppCard] widget rather than in heavy elevation here.
ThemeData buildAppTheme(AppPalette p) {
  final scheme = p.colorScheme;
  final text = appTextTheme(p);
  const pill = StadiumBorder();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.canvas,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: Dimens.borderRadiusL,
        side: BorderSide(color: p.border, width: Dimens.hairline),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: p.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.textStrong,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withValues(alpha: 0.16),
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: pill,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        minimumSize: const Size(64, Dimens.minTouchTarget),
        shape: pill,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: text.labelLarge,
        shape: pill,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: p.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16, vertical: Dimens.spacing12),
      border: const OutlineInputBorder(borderRadius: Dimens.borderRadiusM, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderRadius: Dimens.borderRadiusM, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: Dimens.borderRadiusM,
        borderSide: BorderSide(color: p.accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: p.surfaceMuted,
      side: BorderSide.none,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Dimens.borderRadiusL),
    ),
    listTileTheme: const ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: Dimens.borderRadiusM)),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimens.radiusXL)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
