import 'dart:ui';

/// Reconciles the language the app has saved with the one Android's per-app
/// language picker holds, so the two never quietly disagree.
///
/// There are two places to change the language now: our own Settings screen
/// and Settings -> Apps -> OpenNutriTracker -> Language. Whichever one someone
/// reaches for, they should get the same answer afterwards.
///
/// The cases are decided on the raw [systemLocaleTag] rather than on the
/// language it resolves to, because "no override at all" and "an override we
/// cannot render" mean opposite things. [localeSyncSeeded] records one fact
/// and only that fact: **the OS has been seen holding an override** -- it is
/// what makes a later absence readable as the user having cleared it. It is
/// never set on a platform that reports no override, because there the
/// absence is permanent and means nothing.
///
/// - **A supported override.** The system wins -- it is the side the user can
///   see from outside the app -- and is saved if it differs. The OS holds a
///   value, so seeded is recorded.
/// - **A tag we do not ship** (`ja`, say). Neither side is followed: the app
///   cannot render that language, and the saved choice is not pushed over it
///   either -- overwriting an explicit OS-level choice is a louder wrong
///   answer than ignoring it. The OS still demonstrably holds a value, so
///   seeded is recorded; switching it to System default later reads as the
///   clear it is.
/// - **The read failed.** Nothing is decided on a failed read: the saved
///   choice is returned untouched. Treating it as "no override" would clear
///   a language the user never cleared.
/// - **No override, never seeded.** The upgrade path: an install that
///   predates this wiring, or one where only the in-app picker has been
///   used. The saved choice is pushed out so both sides start from the same
///   place. Seeded is recorded only by *observing* the pushed value, read
///   back in this same call -- never by the attempt alone. On Android 13+
///   the read-back sees the value immediately, so the record lands before
///   this call returns and a clear arriving any time after it is honoured;
///   on platforms with no per-app override the push no-ops, the read-back
///   stays empty, and this branch harmlessly repeats instead of ever
///   mistaking the platform for a user who cleared it.
/// - **No override, seeded.** The OS held a value and no longer does, which
///   only happens when the user picked "System default" in Android's picker.
///   That is a deliberate choice, so the in-app override is cleared to
///   follow it -- without the seeded record this case is indistinguishable
///   from the one above and the cleared value got silently pushed back on
///   the next cold start.
Future<String?> reconcileAppLocale({
  required String? savedLocaleCode,
  required String? systemLocaleTag,
  required bool systemTagReadFailed,
  required bool localeSyncSeeded,
  required Iterable<Locale> supportedLocales,
  required Future<void> Function(String? localeCode) persistSelectedLocale,
  required Future<void> Function(String? languageTag) pushToSystem,
  required Future<({String? tag, bool readFailed})> Function() readSystemTag,
  required Future<void> Function() markLocaleSyncSeeded,
}) async {
  if (systemTagReadFailed) return savedLocaleCode;

  final systemCode = supportedLanguageCode(systemLocaleTag, supportedLocales);

  if (systemCode != null) {
    if (systemCode != savedLocaleCode) await persistSelectedLocale(systemCode);
    if (!localeSyncSeeded) await markLocaleSyncSeeded();
    return systemCode;
  }

  final hasSystemTag = systemLocaleTag != null && systemLocaleTag.isNotEmpty;
  if (hasSystemTag) {
    if (!localeSyncSeeded) await markLocaleSyncSeeded();
    return savedLocaleCode;
  }

  if (!localeSyncSeeded) {
    if (savedLocaleCode != null) {
      await pushToSystem(savedLocaleCode);
      final verify = await readSystemTag();
      if (!verify.readFailed && verify.tag != null && verify.tag!.isNotEmpty) {
        await markLocaleSyncSeeded();
      }
    }
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
