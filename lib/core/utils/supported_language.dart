/// Languages OFF and the Supabase food backend are asked to return
/// product names in. The set is broader than the app's UI locale set
/// because OFF carries product names in many languages even where ONT
/// itself doesn't ship a UI translation.
///
/// Supabase food names come from the `food_translation` table (keyed by
/// BCP 47 locale, see SPConst.translationLocaleOf); foods without a
/// translation for the user's locale fall back to their English name in
/// `food_summary`.
enum SupportedLanguage {
  en,
  de,
  pl,
  zh,
  cs,
  it,
  sk,
  tr,
  uk;

  factory SupportedLanguage.fromCode(String localeCode) {
    final languageCode = localeCode.split('_').first;
    switch (languageCode) {
      case 'en':
        return SupportedLanguage.en;
      case 'de':
        return SupportedLanguage.de;
      case 'pl':
        return SupportedLanguage.pl;
      case 'zh':
        return SupportedLanguage.zh;
      case 'cs':
        return SupportedLanguage.cs;
      case 'it':
        return SupportedLanguage.it;
      case 'sk':
        return SupportedLanguage.sk;
      case 'tr':
        return SupportedLanguage.tr;
      case 'uk':
        return SupportedLanguage.uk;
      default:
        return SupportedLanguage.en;
    }
  }
}
