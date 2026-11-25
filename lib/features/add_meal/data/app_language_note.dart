import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';

/// What a meal interpreter appends to its system prompt for the user's app
/// language: the bare language code, and which language to write `query` in
/// when that is not the user's own.
///
/// The Supabase search reads names in the app language only where
/// `food_translation` has that language ([SPConst.translationLocaleOf]).
/// Everywhere else it matches the English names alone, so a query in Spanish
/// ("huevos") finds no generic food, and neither does a meal written in
/// German on an English phone. In those languages the model is asked for
/// English names; where translations exist the prompt is unchanged.
String appLanguageNote(String localeCode) {
  final note = 'The user\'s app language is "$localeCode".';
  final searchesEnglishNames =
      SPConst.translationLocaleOf(SupportedLanguage.fromCode(localeCode)) ==
      null;
  if (!searchesEnglishNames) return note;
  return '$note\nWrite "query" in English: the food database is searched by '
      'English names in this language. Translate the food name if the input '
      'is in another language, and keep a brand name as written.';
}
