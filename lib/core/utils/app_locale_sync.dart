import 'dart:ui';

/// Reconciles the language the app has saved with the one Android's per-app
/// language picker holds, so the two never quietly disagree.
///
/// There are two places to change the language now: our own Settings screen
/// and Settings -> Apps -> OpenNutriTracker -> Language. Whichever one someone
/// reaches for, they should get the same answer afterwards.
///
/// Four cases, decided on the raw [systemLocaleTag] rather than on the
/// language it resolves to, because "no override at all" and "an override we
/// cannot render" mean opposite things:
///
/// - **A supported override.** The system wins -- it is the side the user can
///   see from outside the app -- and is saved if it differs. Both sides now
///   agree, so the migration below must never fire again: seeded is recorded.
/// - **A tag we do not ship** (`ja`, say). Neither side is followed: the app
///   cannot render that language, and the saved choice is not pushed over it
///   either. The user picked that language in the OS for a reason, and
///   overwriting their choice is a louder wrong answer than ignoring it.
/// - **No override, never seeded.** The upgrade path: an install that predates
///   this wiring, or one where only the in-app picker has been used. The saved
///   choice is pushed out so both sides start from the same place. This is a
///   one-time migration, so it is recorded as seeded either way.
/// - **No override, already seeded.** The OS once held a value and no longer
///   does, which only happens when the user picked "System default" in
///   Android's picker. That is a deliberate choice, so the in-app override is
///   cleared to follow it -- without [localeSyncSeeded] this case is
///   indistinguishable from the one above and the cleared value gets silently
///   pushed back on the next cold start.
///
/// Off Android and below API 33 there is no system override to read and none
/// can ever be set, so the first launch seeds nothing, records seeded, and
/// every launch after that returns the saved choice untouched.
Future<String?> reconcileAppLocale({
  required String? savedLocaleCode,
  required String? systemLocaleTag,
  required bool localeSyncSeeded,
  required Iterable<Locale> supportedLocales,
  required Future<void> Function(String? localeCode) persistSelectedLocale,
  required Future<void> Function(String? languageTag) pushToSystem,
  required Future<void> Function() markLocaleSyncSeeded,
}) async {
  final systemCode = supportedLanguageCode(systemLocaleTag, supportedLocales);

  if (systemCode != null) {
    if (systemCode != savedLocaleCode) await persistSelectedLocale(systemCode);
    if (!localeSyncSeeded) await markLocaleSyncSeeded();
    return systemCode;
  }

  final hasSystemTag = systemLocaleTag != null && systemLocaleTag.isNotEmpty;
  if (hasSystemTag) return savedLocaleCode;

  if (!localeSyncSeeded) {
    if (savedLocaleCode != null) await pushToSystem(savedLocaleCode);
    await markLocaleSyncSeeded();
    return savedLocaleCode;
  }

  if (savedLocaleCode != null) await persistSelectedLocale(null);
  return null;
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
  final isSupported = supportedLocales.any(
    (locale) => locale.languageCode == code,
  );
  return isSupported ? code : null;
}
