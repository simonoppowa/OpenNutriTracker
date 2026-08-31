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
/// `portion` is not one, and the distinction is the whole design rather than
/// a technicality. It is a **lookup key** into the food's own portions — the
/// model says "slice" and the gram weight comes from the row that matched,
/// which came from the food database. A key that matches nothing is ignored.
/// So the model still names and the data still measures, and a wrong key
/// costs a portion nobody selected rather than a number nobody can check.
/// #864.
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
///
/// **The app never relies on provider-side constrained decoding.** This
/// schema is a hint to the model; [_mealItemFrom] and
/// `validateParsedMealItems` are the enforcement. Every guarantee the app
/// makes about model output must be checkable in Dart, against a reply that
/// ignored the schema entirely — which is why `additionalProperties: false`
/// below is documentation of intent rather than a defence, and why a reply
/// carrying a `calories` field loses it whether or not any provider agreed
/// to forbid one.
///
/// That is a standing rule for new providers, not a description of one. A
/// provider offering strict or constrained output may be given it, but
/// nothing may be *moved* onto it: the checks stay. Settled in #683, which
/// also records why adopting OpenAI's strict mode buys this design nothing.
const mealItemsToolSchema = {
  'type': 'object',
  'properties': {
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'portion': {
            'type': 'string',
            'description':
                'How the food was portioned, if it was — '
                'slice, cup, piece. A word only, never a weight or a '
                'count. Omit when unsure.',
          },
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
///
/// **And raises when it held entries and none of them survived**, which is
/// the same sentence one level down. An empty array is a model saying "no
/// food here", and `ReadMealTextUseCase` honours that by showing no rows —
/// so a reply of `{"items": [{"name": "egg"}]}`, where every entry is
/// dropped for carrying no `query`, used to arrive at that use case wearing
/// the same clothes as a deliberate answer. The user got nothing: not the
/// model's rows, which never existed, and not the parser's, which were
/// suppressed by a judgement the model never made.
///
/// The distinction can only be drawn here, because this is the only place
/// that sees both counts. It stays [MealInterpreterFailure.transient], like
/// the wrong-type case above and for the same reason — nothing about a
/// malformed reply says the next one will be, and the text path falls back
/// to the parser in silence rather than blaming a model over one bad batch.
List<ParsedMealItem> mealItemsFromJson(Object? rawItems) {
  if (rawItems is! List) {
    throw const MealInterpreterException('tool call has no items');
  }
  final items = [
    for (final item in rawItems)
      if (item is Map) _mealItemFrom(item),
  ].nonNulls.toList();
  if (items.isEmpty && rawItems.isNotEmpty) {
    throw const MealInterpreterException('every item in the tool call dropped');
  }
  return items;
}

/// One item, or null when it carries no usable query. A malformed entry is
/// dropped rather than failing the batch — the other items are still worth
/// showing, and `validateParsedMealItems` reports what it rejects.
///
/// "The other items" is load-bearing: [mealItemsFromJson] raises when there
/// are none, because dropping every entry is not a batch with holes in it,
/// it is a reply that was not the one asked for.
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
  final rawPortion = raw['portion'];
  return ParsedMealItem(
    query: query,
    quantity: quantity,
    unit: rawUnit is String ? rawUnit : null,
    // A non-string is dropped rather than coerced: this is a key to look
    // something up with, and a number here means the model misread the
    // field, not that it meant 3.
    portion: rawPortion is String && rawPortion.trim().isNotEmpty
        ? rawPortion.trim()
        : null,
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
