import 'dart:ui';

import 'package:opennutritracker/core/l10n/shipped_locales.dart';

/// The locales the app resolves against: gen-l10n's list narrowed to the
/// languages in [shippedLocales], in gen-l10n's order (English first).
///
/// gen-l10n lists every ARB in `lib/l10n/`, including ones Weblate is still
/// filling. Passing that list to `MaterialApp` would switch a device set to
/// Swedish onto a 1 %-Swedish UI. Resolving against the shipped subset
/// keeps such a locale compiled but inert until it is shipped.
///
/// The whole tag is matched, not just the language: a staged regional or
/// script variant of a shipped language (`intl_zh_TW.arb` next to a shipped
/// `zh`) must stay inert too, and [shippedLocales] keys are bare codes, so
/// only the bare `Locale` of a shipped language passes.
List<Locale> appLocales(Iterable<Locale> generated) => generated
    .where((locale) => shippedLocales.containsKey(locale.toString()))
    .toList(growable: false);
