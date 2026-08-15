import 'package:opennutritracker/features/add_meal/domain/meal_interpreter_exception.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

export 'package:opennutritracker/features/add_meal/domain/meal_interpreter_exception.dart';

/// What the app is asking a model to read.
///
/// Deliberately data, not JSON. The two providers disagree about how a photo
/// is carried *and* about the order the parts go in — Anthropic's guidance
/// puts the image first, OpenRouter's docs recommend the text first — so a
/// `toJson` on this type would have to pick one and be wrong for the other.
/// Each client renders it.
sealed class MealContent {
  const MealContent();
}

/// A meal line the user typed.
final class MealTextContent extends MealContent {
  final String text;

  const MealTextContent(this.text);
}

/// A photograph, already encoded and base64'd. Bytes rather than a path
/// because this image is never written anywhere the app can read it again.
final class MealPhotoContent extends MealContent {
  final String mediaType;
  final String base64Data;

  const MealPhotoContent({required this.mediaType, required this.base64Data});
}

/// The text part that accompanies a photo. Short on purpose: the system
/// prompt carries the rules, and this only has to say what the picture is
/// for.
const mealPhotoContentPrompt = 'List the foods in this photo.';

const mealItemsToolName = 'log_meal_items';

const mealItemsToolDescription = 'Record the food items found.';

/// The schema every provider is held to. **No nutrition fields, by
/// construction.**
///
/// This is the provenance guarantee's enforcement point, and it is a
/// top-level constant rather than a member of either client so that adding a
/// provider cannot quietly add a second schema. Reviewing the guarantee stays
/// one question — "did anyone add a field here?" — no matter how many
/// destinations the app grows.
///
/// The shape is plain JSON Schema, which is what Anthropic's `input_schema`
/// and OpenAI-compatible `function.parameters` both take, so one constant
/// serves both wire formats unchanged.
const mealItemsToolSchema = {
  'type': 'object',
  'properties': {
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'Food name only, no amount, in the user\'s '
                'language.',
          },
          'quantity': {
            'type': 'number',
            'description': 'Only if the user stated an amount.',
          },
          'unit': {
            'type': 'string',
            // `l`, `kg` and `lb` are here because the app converts them
            // (validateParsedMealItems normalizes to ml and g). Leaving
            // them out did not stop the model answering — it mapped a
            // litre to `ml` and kept the number, turning 1.5 l of milk
            // into 1.5 ml. A thousandfold under-count with no warning,
            // because a unit *was* stated so nothing flagged the row.
            'enum': [
              'g',
              'kg',
              'lb',
              'ml',
              'l',
              'g/ml',
              'oz',
              'fl.oz',
              'serving',
            ],
            'description':
                'Only if the user stated a unit, and only '
                'one of these. Never map a different unit onto one of '
                'them.',
          },
        },
        'required': ['query'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['items'],
  'additionalProperties': false,
};

/// Reads the `items` array a forced tool call returned.
///
/// Shared by both clients and kept beside [mealItemsToolSchema] on purpose:
/// this function is the schema read back, and a change to one that is not
/// mirrored in the other is a bug worth seeing in a single diff.
///
/// Raises when the array itself is missing or the wrong type, because that
/// means the provider answered something other than what was asked for and
/// guessing at it is how silent nonsense gets into a diary.
List<ParsedMealItem> mealItemsFromJson(Object? rawItems) {
  if (rawItems is! List) {
    throw const MealInterpreterException('tool call has no items');
  }
  return [
    for (final item in rawItems)
      if (item is Map) _mealItemFrom(item),
  ].nonNulls.toList();
}

/// One item, or null when it carries no usable query. A malformed entry is
/// dropped rather than failing the batch — the other items are still worth
/// showing, and `validateParsedMealItems` reports what it rejects.
ParsedMealItem? _mealItemFrom(Map<dynamic, dynamic> raw) {
  final query = raw['query'];
  if (query is! String) return null;

  // Numbers arrive as int or double depending on how the model wrote them; a
  // string is accepted too rather than dropping an otherwise fine item over
  // its JSON type.
  final rawQuantity = raw['quantity'];
  final quantity = switch (rawQuantity) {
    num n => n.toDouble(),
    String s => double.tryParse(s.replaceAll(',', '.')),
    _ => null,
  };

  final rawUnit = raw['unit'];
  return ParsedMealItem(
    query: query,
    quantity: quantity,
    unit: rawUnit is String ? rawUnit : null,
  );
}

/// One forced tool call to a model provider, returning validated items.
///
/// The seam a second provider hangs off. What differs between providers is
/// entirely below this line — endpoint, auth header, request body, how a
/// photo is carried, and how a failure is signalled. What must not differ is
/// above it: the prompts, the counts-only rule on the photo path, and
/// [mealItemsToolSchema].
///
/// Everything an implementation returns goes through
/// [validateParsedMealItems], the same bounds `parseMealText` enforces, so no
/// model can write to the diary under looser rules than a regex.
abstract interface class MealItemsApi {
  /// Raises [MealInterpreterException] for every ordinary failure, carrying
  /// the provider's status code where there was one so the caller can tell a
  /// wrong key from a rate limit from an image nothing can serve.
  Future<MealTextParseResult> requestItems({
    required MealContent content,
    required String system,
  });
}
