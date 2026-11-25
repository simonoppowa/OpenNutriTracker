/// Languages OFF and the Supabase food backend are asked to return
/// product names in. The set is broader than the app's UI locale set
/// because OFF carries product names in many languages even where ONT
/// itself doesn't ship a UI translation — French is the largest of those
/// (#1326), and `AppLocale.foodLocaleName` picks it from the device even
/// though the UI then reads English.
///
/// Supabase food names come from the `food_translation` table (keyed by
/// BCP 47 locale, see SPConst.translationLocaleOf); foods without a
/// translation for the user's locale fall back to their English name in
/// `food_summary`.
///
/// English stays first: `OFFProductDTO.getLocaleName` walks [values] in
/// order for its fallback name.
enum SupportedLanguage {
  en,
  de,
  pl,
  zh,
  cs,
  it,
  sk,
  tr,
  uk,
  hu,
  es,
  ru,
  fr;

  /// The language of [localeCode] (`fr`, `fr_CA`), or English when the
  /// food sources are not asked for that language.
  factory SupportedLanguage.fromCode(String localeCode) =>
      tryFromCode(localeCode) ?? SupportedLanguage.en;

  /// The language of [localeCode], or null when the food sources are not
  /// asked for that language.
  static SupportedLanguage? tryFromCode(String localeCode) {
    final languageCode = localeCode.split(RegExp('[_-]')).first;
    for (final language in values) {
      if (language.name == languageCode) return language;
    }
    return null;
  }
}
