import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Reads a photograph of a meal with a model and returns the foods it can
/// identify, so the existing search can resolve each one against Open Food
/// Facts / USDA / BLS.
///
/// Shares [MealItemsApi] — and therefore [mealItemsToolSchema], which has no
/// macro fields — with the text path, and with every provider. What differs
/// is the prompt, and one extra rule this class enforces in code.
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
///
/// **A photograph may size a counted thing, never name a container.** The
/// `portion` key the text path carries — `slice`, `cup`, `handful` — is a
/// measurement in a word's clothing when it comes from a picture: on every
/// uncountable food the app can see, the default row already *is* the cup,
/// so the only thing `cup` could add is a count of cups, which is the
/// measuring above. A size is different: `large` on `2 eggs` describes the
/// things that were counted, and the grams still come from the food's own
/// `1 large` row. So [_sizesOnly] keeps `small`, `medium` and `large` on a
/// counted item and drops every other word. #1156.
///
/// Both rules live here rather than in either client because they are
/// properties of reading photographs, not of a provider. A provider added
/// later inherits them without being asked to.
///
/// **A dish the user saved is named as they saved it.** A photograph names
/// a regional dish generically — "dumplings" for the user's own "Pelmeni" —
/// and the search then never reaches the recipe they made for it. So the
/// prompt lists the names of their saved recipes, [savedDishesLimit] at most
/// and the latest changed first, and asks for one by its exact name only when
/// the photo clearly shows it ([savedDishesPrompt]). Only the names go: no
/// ingredient, amount or nutrition value of a recipe is sent.
class ModelMealPhotoInterpreter implements MealPhotoInterpreter {
  static final _log = Logger('ModelMealPhotoInterpreter');

  final MealItemsApi _api;

  /// The names of the user's saved recipes, the latest changed first. Asked
  /// at each read, so a recipe saved a moment ago is already among them.
  /// Null where there are none to offer, as for the setup probe, which
  /// sends nothing of the user's.
  final List<String> Function()? _savedDishes;

  ModelMealPhotoInterpreter(this._api, {List<String> Function()? savedDishes})
    : _savedDishes = savedDishes;

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
- Include "quantity" whenever you can count discrete items, and count
  them: 2 eggs, 3 sausages, 1 banana, 14 dumplings, 1 whole pizza. A dish
  served as pieces (dumplings, pancakes, tarts, rolls) is counted, roughly
  if there are many. A count has no unit, so never include "unit".
- For anything you cannot count — rice, salad, sauce, soup, a drink — omit
  "quantity". Do not guess grams or millilitres from a photograph. The app
  asks the user for the amount, and a guess they cannot check is worse than
  no answer.
- If you counted items and can see their size, you may add "portion":
  "small", "medium" or "large". Nothing else belongs in "portion" from a
  photograph — no cups, bowls, slices or handfuls.
- Only list food you can actually identify. If you cannot tell what a dish
  is, describe it plainly ("meat stew") rather than naming a specific
  recipe you are guessing at.
- If the photo contains no food, return an empty list.''';

  @override
  Future<MealTextParseResult> interpret(
    MealPhoto photo, {
    String? localeCode,
  }) async {
    final saved = savedDishesPrompt(_savedDishNames());
    final result = await _api.requestItems(
      content: MealPhotoContent(
        mediaType: photo.mediaType,
        base64Data: base64Encode(photo.bytes),
      ),
      system:
          (localeCode == null
              ? _systemPrompt
              : '$_systemPrompt\nThe user\'s app language is "$localeCode".') +
          (saved == null ? '' : '\n$saved'),
    );

    return _sizesOnly(_countsOnly(result));
  }

  /// The saved recipe names, or none when they cannot be read: the photo is
  /// still worth reading without them.
  List<String> _savedDishNames() {
    try {
      return _savedDishes?.call() ?? const [];
    } catch (e, stackTrace) {
      _log.warning('Saved recipes unreadable', e, stackTrace);
      return const [];
    }
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
  /// either — and adding a provider is exactly that day arriving.
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

  /// The three words a photograph may say about the things it counted.
  ///
  /// English and model-facing — the same shape of contract as `unit`, not a
  /// per-locale vocabulary for user text, which is what #600 ruled out. The
  /// prompt asks for exactly these; this is what holds the model to it.
  static const _photoSizes = {'small', 'medium', 'large'};

  /// Keeps `portion` only as a size of one counted thing; drops it otherwise.
  ///
  /// Runs after [_countsOnly], so an item that lost its number has already
  /// lost its word with it — a size is the size of a counted thing, and a
  /// model that sized what it could not count has slipped. What is left to
  /// decide is the word itself: trimmed and lower-cased, it survives only as
  /// one of [_photoSizes]. `cup`, `slice`, `handful`, `extra large` and
  /// `mini` all become null here, whatever the prompt said. The prompt
  /// already forbids them, but a prompt is a request and this is a
  /// guarantee.
  ///
  /// The matcher downstream only runs under a stated quantity, so a size on
  /// an uncounted item would have gone nowhere anyway; dropping it here makes
  /// that a rule rather than a coincidence of two gates agreeing. #1156.
  MealTextParseResult _sizesOnly(MealTextParseResult result) =>
      MealTextParseResult(
        items: [
          for (final item in result.items)
            ParsedMealItem(
              query: item.query,
              quantity: item.quantity,
              unit: item.unit,
              portion: _sizeOfOne(item),
            ),
        ],
        errors: result.errors,
      );

  static String? _sizeOfOne(ParsedMealItem item) {
    if (item.quantity == null) return null;
    final word = item.portion?.trim().toLowerCase();
    return word != null && _photoSizes.contains(word) ? word : null;
  }
}

/// How many saved recipe names a photo read carries at most.
const savedDishesLimit = 60;

/// The prompt line for the user's saved recipe [names], latest changed
/// first, or null when there are none.
///
/// Each name is quoted as JSON, so a name with a quote or a comma in it is
/// still one name. Blank names go, and a name differing only in case from
/// one before it, then the rest past [savedDishesLimit] — the latest changed
/// are the likeliest to be on the plate.
String? savedDishesPrompt(List<String> names) {
  final seen = <String>{};
  final unique = [
    for (final name in names.map((n) => n.trim()))
      if (name.isNotEmpty && seen.add(name.toLowerCase())) name,
  ].take(savedDishesLimit).toList();
  if (unique.isEmpty) return null;
  return 'The user has saved these dishes: '
      '${unique.map(jsonEncode).join(', ')}. When the photo clearly shows one '
      'of them, use its name exactly as the query; otherwise name the food '
      'as usual.';
}
