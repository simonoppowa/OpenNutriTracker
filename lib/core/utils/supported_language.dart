enum SupportedLanguage {
  en,
  fr,
  de;

  factory SupportedLanguage.fromCode(String localeCode) {
    final languageCode = localeCode.split('_').first;
    switch (languageCode) {
      case 'en':
        return SupportedLanguage.en;
      case 'de':
        return SupportedLanguage.de;
      case 'fr':
        return SupportedLanguage.fr;
      default:
        return SupportedLanguage.en;
    }
  }
}
