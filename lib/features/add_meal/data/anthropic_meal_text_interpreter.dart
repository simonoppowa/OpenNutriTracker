import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Reads a free-text meal line with Claude, and returns only what the food
/// search needs: a query per item, plus a quantity when the user stated one.
///
/// The provenance guarantee is structural, not a convention. The tool schema
/// below has **no macro fields** — the model has nowhere to put a calorie
/// count, so it cannot supply one. Everything it does return then goes
/// through [validateParsedMealItems], the same bounds `parseMealText`
/// enforces, so a model can never write to the diary under looser rules than
/// a regex. Both halves are covered by tests.
class AnthropicMealTextInterpreter implements MealTextInterpreter {
  static final _log = Logger('AnthropicMealTextInterpreter');

  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  /// Pinned rather than tracking "latest": a silent model change would move
  /// behaviour the user never asked to change, and this call is cheap enough
  /// that the smallest current model is the right default.
  static const defaultModel = 'claude-haiku-4-5';

  /// The API version header Anthropic requires. Pinned for the same reason.
  static const _apiVersion = '2023-06-01';

  static const _toolName = 'log_meal_items';

  /// Small on purpose. This returns a short list of short strings; a large
  /// budget only buys a longer runaway before it is cut off.
  static const _maxTokens = 1024;

  /// Matches the other remote data sources in this repo. Without it a
  /// stalled connection hangs until the OS gives up, which in #635 means the
  /// user waits instead of falling back to the deterministic parser.
  static const defaultTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String Function() _apiKey;
  final String model;

  /// Injectable so the stalled-connection test does not spend the real
  /// twenty seconds proving it. Raising the production value should not
  /// quietly make the suite slower.
  final Duration timeout;

  AnthropicMealTextInterpreter(
    this._client,
    this._apiKey, {
    this.model = defaultModel,
    this.timeout = defaultTimeout,
  });

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
- Only include "unit" if the user stated one. A bare count has no unit.
- Never convert between units. Report what was written.
- If nothing in the input is food, return an empty list.''';

  /// No nutrition fields, by construction. Adding one here is the only way a
  /// model could return a macro through this path, which makes the review
  /// question "did anyone add a field to this schema?" rather than "did the
  /// model behave?".
  static const _toolSchema = {
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
              'enum': ['g', 'ml', 'g/ml', 'oz', 'fl.oz', 'serving'],
              'description': 'Only if the user stated a unit.',
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

  @override
  Future<MealTextParseResult> interpret(
    String input, {
    String? localeCode,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const MealTextParseResult(items: [], errors: []);
    }

    final body = jsonEncode({
      'model': model,
      'max_tokens': _maxTokens,
      'system': localeCode == null
          ? _systemPrompt
          : '$_systemPrompt\nThe user\'s app language is "$localeCode".',
      'tools': [
        {
          'name': _toolName,
          'description': 'Record the food items found in the description.',
          'input_schema': _toolSchema,
        },
      ],
      // Forcing the tool is what makes the reply parseable. Without it the
      // model may answer in prose and every caller needs a fallback parser.
      'tool_choice': {'type': 'tool', 'name': _toolName},
      'messages': [
        {'role': 'user', 'content': trimmed},
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
      // URL and, on some platforms, part of the payload.
      throw const MealTextInterpreterException('request failed');
    }

    if (response.statusCode != 200) {
      _log.warning('Interpreter call failed with ${response.statusCode}');
      throw MealTextInterpreterException(
        'provider returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return validateParsedMealItems(_itemsFrom(response.body));
  }

  /// Pulls the tool input out of the reply. Every shape that is not the one
  /// expected raises rather than guessing, so a changed API surfaces as a
  /// fallback to the deterministic parser instead of silent nonsense.
  List<ParsedMealItem> _itemsFrom(String responseBody) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw const MealTextInterpreterException('malformed response');
    }

    final content = decoded['content'];
    if (content is! List) {
      throw const MealTextInterpreterException('response has no content');
    }

    for (final block in content) {
      if (block is! Map) continue;
      if (block['type'] != 'tool_use' || block['name'] != _toolName) continue;

      // Checked rather than cast: a provider returning something other than
      // an object here would otherwise throw a TypeError straight past the
      // exception surface that #635 relies on to fall back.
      final input = block['input'];
      final rawItems = input is Map ? input['items'] : null;
      if (rawItems is! List) {
        throw const MealTextInterpreterException('tool call has no items');
      }

      return [
        for (final item in rawItems)
          if (item is Map) _itemFrom(item),
      ].nonNulls.toList();
    }

    throw const MealTextInterpreterException('response has no tool call');
  }

  /// One item, or null when it carries no usable query. A malformed entry is
  /// dropped rather than failing the batch — the other items are still
  /// worth showing, and `validateParsedMealItems` reports what it rejects.
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
