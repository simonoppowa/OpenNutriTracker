import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_interpreter_exception.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// The one place this app asks Claude for a list of food items, whether the
/// question came from a line of text or a photograph.
///
/// **The provenance guarantee lives here, and only here.** [toolSchema] has
/// no macro fields, so the model has nowhere to put a calorie count and
/// cannot supply one. Both interpreters share this single schema on purpose:
/// a second copy is a second thing to audit, and the whole value of a
/// structural guarantee is that reviewing it is one question — "did anyone
/// add a field to this schema?" — rather than one question per caller.
///
/// Everything the model returns then goes through [validateParsedMealItems],
/// the same bounds `parseMealText` enforces, so no model can write to the
/// diary under looser rules than a regex.
class AnthropicMealItemsApi {
  static final _log = Logger('AnthropicMealItemsApi');

  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  /// Pinned rather than tracking "latest": a silent model change would move
  /// behaviour the user never asked to change, and these calls are cheap
  /// enough that the smallest current model is the right default. Haiku 4.5
  /// takes images as well as text, so both paths share it.
  static const defaultModel = 'claude-haiku-4-5';

  /// The API version header Anthropic requires. Pinned for the same reason.
  static const _apiVersion = '2023-06-01';

  static const toolName = 'log_meal_items';

  /// Small on purpose. This returns a short list of short strings; a large
  /// budget only buys a longer runaway before it is cut off.
  static const _maxTokens = 1024;

  /// Matches the other remote data sources in this repo. Without it a
  /// stalled connection hangs until the OS gives up, which means the user
  /// waits instead of being told, or falling back to the parser.
  static const defaultTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String Function() _apiKey;
  final String model;

  /// Injectable so the stalled-connection tests do not spend the real twenty
  /// seconds proving it. Raising the production value should not quietly
  /// make the suite slower.
  final Duration timeout;

  AnthropicMealItemsApi(
    this._client,
    this._apiKey, {
    this.model = defaultModel,
    this.timeout = defaultTimeout,
  });

  /// No nutrition fields, by construction. Adding one here is the only way a
  /// model could return a macro through either path.
  static const toolSchema = {
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

  /// Sends one forced tool call and returns the validated items.
  ///
  /// [content] is the user message body — a plain string for the text path,
  /// a list of content blocks for the photo path. The Messages API accepts
  /// either, and keeping it untyped here is what lets the two paths share
  /// every line below it.
  Future<MealTextParseResult> requestItems({
    required Object content,
    required String system,
  }) async {
    final body = jsonEncode({
      'model': model,
      'max_tokens': _maxTokens,
      'system': system,
      'tools': [
        {
          'name': toolName,
          'description': 'Record the food items found.',
          'input_schema': toolSchema,
        },
      ],
      // Forcing the tool is what makes the reply parseable. Without it the
      // model may answer in prose and every caller needs a fallback parser.
      'tool_choice': {'type': 'tool', 'name': toolName},
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': _apiKey(),
              'anthropic-version': _apiVersion,
            },
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      // Deliberately not logging `e`: a socket error can carry the request
      // URL and, on some platforms, part of the payload — which for the
      // photo path is the photograph.
      throw const MealInterpreterException('request failed');
    }

    if (response.statusCode != 200) {
      _log.warning('Interpreter call failed with ${response.statusCode}');
      throw MealInterpreterException(
        'provider returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return validateParsedMealItems(_itemsFrom(response.body));
  }

  /// Pulls the tool input out of the reply. Every shape that is not the one
  /// expected raises rather than guessing, so a changed API surfaces as a
  /// handled failure instead of silent nonsense.
  List<ParsedMealItem> _itemsFrom(String responseBody) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw const MealInterpreterException('malformed response');
    }

    final content = decoded['content'];
    if (content is! List) {
      throw const MealInterpreterException('response has no content');
    }

    for (final block in content) {
      if (block is! Map) continue;
      if (block['type'] != 'tool_use' || block['name'] != toolName) continue;

      // Checked rather than cast: a provider returning something other than
      // an object here would otherwise throw a TypeError straight past the
      // exception surface the callers rely on.
      final input = block['input'];
      final rawItems = input is Map ? input['items'] : null;
      if (rawItems is! List) {
        throw const MealInterpreterException('tool call has no items');
      }

      return [
        for (final item in rawItems)
          if (item is Map) _itemFrom(item),
      ].nonNulls.toList();
    }

    throw const MealInterpreterException('response has no tool call');
  }

  /// One item, or null when it carries no usable query. A malformed entry is
  /// dropped rather than failing the batch — the other items are still worth
  /// showing, and `validateParsedMealItems` reports what it rejects.
  ParsedMealItem? _itemFrom(Map<dynamic, dynamic> raw) {
    final query = raw['query'];
    if (query is! String) return null;

    // Numbers arrive as int or double depending on how the model wrote
    // them; a string is accepted too rather than dropping an otherwise fine
    // item over its JSON type.
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
}
