enum SupportedLanguage {
  en,
  de;

  factory SupportedLanguage.fromCode(String localeCode) {
    final languageCode = localeCode.split('_').first;
    switch (languageCode) {
      case 'en':
        return SupportedLanguage.en;
      case 'de':
        return SupportedLanguage.de;
      default:
        return SupportedLanguage.en;
    }
  }
}
