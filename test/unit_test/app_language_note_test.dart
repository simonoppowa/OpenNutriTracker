import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/app_language_note.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

const _englishRule = 'Write "query" in English';

void main() {
  group('appLanguageNote', () {
    test('always names the app language', () {
      for (final language in SupportedLanguage.values) {
        expect(
          appLanguageNote(language.name),
          startsWith('The user\'s app language is "${language.name}".'),
        );
      }
    });

    test('asks for English names in Spanish, where the search reads only '
        'English names', () {
      expect(appLanguageNote('es'), contains(_englishRule));
    });

    test('asks for English names in Hungarian, for the same reason', () {
      expect(appLanguageNote('hu'), contains(_englishRule));
    });

    test('asks for English names in English, so a meal written in another '
        'language still matches', () {
      expect(appLanguageNote('en'), contains(_englishRule));
    });

    test('leaves the query in the user\'s language where translated names '
        'are searched', () {
      expect(appLanguageNote('de'), isNot(contains(_englishRule)));
    });

    // Ties the note to the search rather than to a list of its own: flipping
    // a language on in translationLocaleOf turns the English rule off.
    test('follows SPConst.translationLocaleOf for every language', () {
      for (final language in SupportedLanguage.values) {
        final searchesEnglish = SPConst.translationLocaleOf(language) == null;
        expect(
          appLanguageNote(language.name).contains(_englishRule),
          searchesEnglish,
          reason: language.name,
        );
      }
    });
  });
}
