/// Languages OFF (and, where the Supabase columns exist, FDC) are
/// asked to return product names in. The set is broader than the
/// app's UI locale set because OFF carries product names in many
/// languages even where ONT itself doesn't ship a UI translation.
///
/// FDC product names are sourced from a Supabase view; that view
/// only has English and German columns today, so the FDC DTOs fall
/// through to English for cs / it / pl / tr / uk / zh users. The
/// fallthrough is documented at each call site so a Supabase schema
/// update can fill it in cleanly.
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
