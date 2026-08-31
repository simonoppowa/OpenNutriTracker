import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Reads a free-text meal line with a model, and returns only what the food
/// search needs: a query per item, plus a quantity when the user stated one.
///
/// Everything about the request lives in the [MealItemsApi] it is given, and
/// everything about the schema lives in [mealItemsToolSchema]. This class is
/// the prompt and nothing else — which is why it takes any provider rather
/// than naming one. The contract with the model does not change because the
/// destination did, and writing it twice is how two versions of it end up
/// disagreeing.
class ModelMealTextInterpreter implements MealTextInterpreter {
  final MealItemsApi _api;

  ModelMealTextInterpreter(this._api);

  /// The whole contract with the model, in one place.
  ///
  /// `quantity` is described as *stated only* deliberately. Inferring that
  /// half an avocado is about 100 g is estimation, not parsing, and
  /// estimating mass is the first step back toward estimating nutrition —
  /// which is what #250 was closed over. When the user states no amount the
  /// field is left out and the review row's existing serving-size default
  /// fills it, exactly as it does for the deterministic parser.
  static const _systemPrompt = '''
You extract food items from a meal description so they can be looked up in a
food database. You do not estimate nutrition, and you never invent an amount.

Rules:
- One entry per distinct food. Split on any punctuation or conjunction the
  user's language uses.
- "query" is the food name alone, with no amount in it, in the same language
  the user wrote. Keep a brand if one is given.
- Only include "quantity" if the user stated an amount, including as a word
  ("two eggs" -> 2) or a counter ("2个鸡蛋" -> 2). If no amount is stated,
  omit both "quantity" and "unit".
- Only include "unit" if the user stated one, and only when it is one of
  the listed values. A bare count has no unit.
- If the user's unit is not in the list (tbsp, tsp, cup, slice...),
  give the "quantity" and leave "unit" out. Do not substitute a different
  unit: reporting 2 tbsp as 2 g is worse than reporting 2 with no unit.
- Never convert a quantity between units. Report the number as written.
- If nothing in the input is food, return an empty list.''';

  @override
  Future<MealTextParseResult> interpret(
    String input, {
    String? localeCode,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const MealTextParseResult(items: [], errors: []);
    }

    return _api.requestItems(
      content: MealTextContent(trimmed),
      system: localeCode == null
          ? _systemPrompt
          : '$_systemPrompt\nThe user\'s app language is "$localeCode".',
    );
  }
}
