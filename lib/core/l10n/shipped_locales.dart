// PROTOTYPE for https://github.com/simonoppowa/OpenNutriTracker/issues/1182
// — the one list every other locale list derives from.

/// The languages OpenNutriTracker ships, keyed by ARB language code, with
/// the name each shows in the in-app picker.
///
/// This is deliberately not "every `lib/l10n/intl_*.arb`": translations
/// arrive through Weblate while they are still being written, so an ARB
/// can be present and 1 % translated. A language is *shipped* when it is
/// listed here — and only then do users see it: `main.dart` resolves the
/// device locale against this list, Settings offers it, and
/// `tool/check_locales.dart` keeps `ios/Runner/Info.plist` and
/// `android/app/src/main/res/xml/locales_config.xml` in step with it.
///
/// Shipping a language: add its line here, run
/// `dart run tool/check_locales.dart --fix`, commit. Nothing else to edit.
///
/// Keep this file free of imports: `tool/check_locales.dart` runs outside
/// Flutter and reads the map directly.
const shippedLocales = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'tr': 'Türkçe',
  'cs': 'Čeština',
  'it': 'Italiano',
  'uk': 'Українська',
  'zh': '中文',
  'pl': 'Polski',
  'sk': 'Slovenčina',
};
