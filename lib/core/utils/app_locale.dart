import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The locale the app is being read in, for code that runs outside the
/// widget tree — data sources and entity factories that decide which
/// language to ask Open Food Facts and the food backend for.
///
/// Widgets read the locale from `LocaleProvider`. Off the tree the only
/// signal used to be `Platform.localeName`, which is the *device* language:
/// it follows the in-app picker only on Android 13+, where
/// `AppLocaleService` writes the choice through to the per-app setting. On
/// iOS and older Android it does not, so an English phone set to German in
/// Settings got a German UI with English food names (#1214).
///
/// `LocaleProvider` is the one writer: it records the selection here when it
/// is created from the saved choice at start-up and whenever the picker
/// changes it. Nothing else should call [select].
class AppLocale {
  AppLocale._();

  static String? _selected;

  /// The language tag food names are requested in: the language chosen in
  /// the app, or — for "System default" — the one `MaterialApp` resolves
  /// from the device's preference list against the shipped locales. The
  /// two must agree: a device preferring unshipped French, then German,
  /// reads the UI in German and should get German food names, which the
  /// device's first locale alone would not say.
  static String get localeName => _selected ?? _systemLocaleName;

  /// The device's preference list, as `MaterialApp` sees it. Swapped in
  /// tests to exercise the resolution without a platform.
  @visibleForTesting
  static List<Locale> Function() preferredLocales = () =>
      PlatformDispatcher.instance.locales;

  static String get _systemLocaleName {
    final preferred = preferredLocales();
    if (preferred.isEmpty) return Platform.localeName;
    return basicLocaleListResolution(
      preferred,
      appLocales(S.supportedLocales),
    ).toString();
  }

  /// Records the app's chosen locale, or null for "follow the system".
  static void select(String? localeName) => _selected = localeName;

  @visibleForTesting
  static void reset() {
    _selected = null;
    preferredLocales = () => PlatformDispatcher.instance.locales;
  }
}
