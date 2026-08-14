import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

// Re-exported so a caller that only cares about the text path still has one
// import, even though the failure type is now shared with the photo path.
export 'package:opennutritracker/features/add_meal/domain/meal_interpreter_exception.dart';

/// Turns a free-text meal description into items the existing food search
/// can resolve.
///
/// Deliberately returns the same [MealTextParseResult] `parseMealText`
/// returns, so an implementation is a drop-in alternative to the
/// deterministic parser: the resolver, the review screen and the write path
/// are untouched by which one produced the items.
///
/// **An implementation may not produce nutrition values.** Tier 1b of #599
/// exists so a model can do the *language* work — segmenting a sentence,
/// reading `two eggs` or `2个鸡蛋` — while every macro still comes from Open
/// Food Facts / USDA / BLS via the resolver. That is what keeps the app's
/// "every number is cited" claim true, and it is why #250 does not need
/// reopening for this tier. See [ParsedMealItem]: it has nowhere to put a
/// calorie.
abstract interface class MealTextInterpreter {
  /// Interprets [input], optionally hinted with the user's [localeCode] so
  /// food names come back in the language the search is querying.
  ///
  /// Implementations must not throw for ordinary failure — no network, a
  /// rejected key, a rate limit, a malformed reply. Those raise
  /// [MealInterpreterException] so the caller can fall back to the
  /// deterministic parser rather than showing the user an error.
  Future<MealTextParseResult> interpret(String input, {String? localeCode});
}
