import 'dart:ui';

/// Reconciles the language the app has saved with the one Android's per-app
/// language picker holds, so the two never quietly disagree.
///
/// There are two places to change the language now: our own Settings screen
/// and Settings -> Apps -> OpenNutriTracker -> Language. Whichever one someone
/// reaches for, they should get the same answer afterwards.
///
/// The system override wins when it exists, because it is the one the user can
/// see from outside the app. When it does not exist but we have a saved choice
/// -- an install that predates this wiring, or a fresh one where only the
/// in-app picker has been used -- the saved choice is pushed out to the system
/// so both sides start from the same place.
///
/// Off Android and below API 33 there is no system override at all, and this
/// collapses to returning the saved choice untouched.
Future<String?> reconcileAppLocale({
  required String? savedLocaleCode,
  required String? systemLocaleTag,
  required Iterable<Locale> supportedLocales,
  required Future<void> Function(String? localeCode) persistSelectedLocale,
  required Future<void> Function(String? languageTag) pushToSystem,
}) async {
  final systemCode = supportedLanguageCode(systemLocaleTag, supportedLocales);

  if (systemCode != null) {
    if (systemCode != savedLocaleCode) await persistSelectedLocale(systemCode);
    return systemCode;
  }

  if (savedLocaleCode != null) await pushToSystem(savedLocaleCode);
  return savedLocaleCode;
}

/// The supported language code behind a platform language tag, or null when
/// there is no tag or the app does not ship that language.
///
/// Android hands back a full BCP-47 tag -- `de`, `pt-BR`, `zh-Hans-CN` -- while
/// the app keys its ARBs and its own picker on the bare language subtag. A tag
/// we do not ship is treated as no override rather than as a language, so a
/// stale system value cannot strand someone in a screen we never translated.
String? supportedLanguageCode(
  String? languageTag,
  Iterable<Locale> supportedLocales,
) {
  if (languageTag == null || languageTag.isEmpty) return null;
  final code = languageTag.split(RegExp(r'[-_]')).first.toLowerCase();
  if (code.isEmpty) return null;
  final isSupported =
      supportedLocales.any((locale) => locale.languageCode == code);
  return isSupported ? code : null;
}
