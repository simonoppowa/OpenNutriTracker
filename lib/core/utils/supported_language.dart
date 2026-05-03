enum SupportedLanguage {
  en,
  pl,
  de,
  zh;

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
      default:
        return SupportedLanguage.en;
    }
  }
}
