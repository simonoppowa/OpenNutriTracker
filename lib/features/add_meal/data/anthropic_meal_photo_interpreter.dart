import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Reads a photograph of a meal with Claude and returns the foods it can
/// identify, so the existing search can resolve each one against Open Food
/// Facts / USDA / BLS.
///
/// Shares [AnthropicMealItemsApi] — and therefore the tool schema with no
/// macro fields — with the text path. What differs is the prompt, and one
/// extra rule this class enforces in code.
///
/// **A photograph may produce a count, never a measurement.** The text path
/// can return `100 g` because the user typed it. Nothing in a photo is
/// stated: a gram figure read off a picture of a plate is estimation
/// wearing the costume of a measurement, and it arrives looking exactly as
/// confident as a number the user typed. Counting discrete items is a
/// different act — two eggs are two eggs, and the user can see whether the
/// count is right. So the prompt asks for counts only and [_countsOnly]
/// discards anything that came back with a unit, which is the tell that the
/// model measured instead of counted.
class AnthropicMealPhotoInterpreter implements MealPhotoInterpreter {
  static const defaultModel = AnthropicMealItemsApi.defaultModel;
  static const defaultTimeout = AnthropicMealItemsApi.defaultTimeout;

  final AnthropicMealItemsApi _api;

  AnthropicMealPhotoInterpreter(
    http.Client client,
    String Function() apiKey, {
    String model = defaultModel,
    Duration timeout = defaultTimeout,
  }) : _api = AnthropicMealItemsApi(
         client,
         apiKey,
         model: model,
         timeout: timeout,
       );

  static const _systemPrompt = '''
You identify the foods visible in a photograph of a meal so they can be
looked up in a food database. You do not estimate nutrition, and you do not
estimate weight or volume.

Rules:
- One entry per distinct food you can see. A composed dish a person would
  log as one thing ("lasagne", "chicken curry") is one entry, not a list of
  its ingredients.
- "query" is the food name alone, with no amount in it, in the user's app
  language. Keep a brand only if it is legible in the photo.
- Only include "quantity" when you can count discrete items: 2 eggs, 3
  sausages, 1 banana. A count has no unit, so never include "unit".
- For anything you cannot count — rice, salad, sauce, soup, a drink — omit
  "quantity". Do not guess grams or millilitres from a photograph. The app
  asks the user for the amount, and a guess they cannot check is worse than
  no answer.
- Only list food you can actually identify. If you cannot tell what a dish
  is, describe it plainly ("meat stew") rather than naming a specific
  recipe you are guessing at.
- If the photo contains no food, return an empty list.''';

  @override
  Future<MealTextParseResult> interpret(
    MealPhoto photo, {
    String? localeCode,
  }) async {
    final result = await _api.requestItems(
      content: AnthropicMealPhotoContent(
        mediaType: photo.mediaType,
        base64Data: base64Encode(photo.bytes),
      ),
      system: localeCode == null
          ? _systemPrompt
          : '$_systemPrompt\nThe user\'s app language is "$localeCode".',
    );

    return _countsOnly(result);
  }

  /// Drops any amount that is not a whole count of visible things.
  ///
  /// Two ways an amount fails that, and both drop the *number* as well as
  /// whatever came with it.
  ///
  /// **It arrived with a unit.** The prompt already forbids it, but a prompt
  /// is a request and this is a guarantee. Dropping only the unit would be
  /// worse than useless: an estimated `200 g` of rice stripped to a bare
  /// `200` reads downstream as a count, and `BulkAddBloc._initialUnit` turns
  /// a bare count into *servings*. That converts a wrong guess into a far
  /// wronger one while looking tidier.
  ///
  /// **It is not a whole number.** You cannot see one and a half of
  /// something and call it counting — `1.5` is an estimate of a proportion,
  /// which is the measuring this path does not do. A 447-call corpus never
  /// once produced a fraction, so this guards nothing today; it guards the
  /// day the model changes, which is the only reason the unit rule is here
  /// either.
  ///
  /// Either way the row falls back to the same default an unquantified item
  /// gets, and the user sets the amount.
  MealTextParseResult _countsOnly(MealTextParseResult result) =>
      MealTextParseResult(
        items: [
          for (final item in result.items)
            if (item.unit == null && _isWholeCount(item.quantity))
              item
            else
              ParsedMealItem(query: item.query, quantity: null, unit: null),
        ],
        errors: result.errors,
      );

  /// Null counts as fine — an item with no amount is the normal case here.
  static bool _isWholeCount(double? quantity) =>
      quantity == null || quantity == quantity.roundToDouble();
}
