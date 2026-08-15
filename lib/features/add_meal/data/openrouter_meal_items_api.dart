import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Asks a model for food items through OpenRouter, which brokers the request
/// on to whichever provider actually serves it.
///
/// The sibling of [AnthropicMealItemsApi] rather than a branch inside it.
/// The two share a schema, a tool name and a set of prompts, and agree on
/// nothing else: tools are wrapped in a `function` object, images are a data
/// URI instead of a base64 source block, the parts of a message go in the
/// opposite order, tool arguments come back as a JSON *string*, and a failed
/// generation arrives as HTTP 200. Every one of those is a place a shared
/// class would need a provider check, and a class that is a chain of provider
/// checks is two classes with extra steps.
class OpenRouterMealItemsApi implements MealItemsApi {
  static final _log = Logger('OpenRouterMealItemsApi');

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  static const _maxTokens = 1024;

  static const defaultTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String Function() _apiKey;

  /// No default. Which model is fit for this is a curation question with an
  /// answer that will change, and a constant here would quietly become that
  /// answer.
  final String model;

  /// Providers this request may be served by, or null to let OpenRouter
  /// route freely.
  ///
  /// When set, fallbacks are switched off, so the provider named in the app
  /// is the provider that served the request — guaranteed rather than
  /// likely. That matters because a model slug does not name its provider: a
  /// probe of `anthropic/claude-haiku-4.5` with no pin was served by Amazon
  /// Bedrock on all three attempts.
  final List<String>? providers;

  final Duration timeout;

  OpenRouterMealItemsApi(
    this._client,
    this._apiKey, {
    required this.model,
    this.providers,
    this.timeout = defaultTimeout,
  });

  @override
  Future<MealTextParseResult> requestItems({
    required MealContent content,
    required String system,
  }) async {
    final body = jsonEncode({
      'model': model,
      'max_tokens': _maxTokens,
      // No top-level `system` field here: the OpenAI-compatible shape wants
      // it as the first message.
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': _contentJson(content)},
      ],
      'tools': [
        {
          'type': 'function',
          'function': {
            'name': mealItemsToolName,
            'description': mealItemsToolDescription,
            'parameters': mealItemsToolSchema,
            'strict': true,
          },
        },
      ],
      'tool_choice': {
        'type': 'function',
        'function': {'name': mealItemsToolName},
      },
      'provider': {
        // Without this, OpenRouter documents that a provider which does not
        // support a parameter still receives the request and ignores it —
        // and `tool_choice` is not in the set it steers by. A dropped
        // `tool_choice` means a prose answer this client cannot read, which
        // would surface as "malformed response" rather than as the
        // capability problem it is. With it, an unfit provider is refused up
        // front with a 404 the user can be told about.
        'require_parameters': true,
        if (providers != null) ...{'only': providers, 'allow_fallbacks': false},
      },
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer ${_apiKey()}',
              // Deliberately no HTTP-Referer or X-Title. Those are
              // OpenRouter's app-attribution headers and they put the app on
              // a public leaderboard, which is not something to opt a user
              // into as a side effect of them saving a key.
            },
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      // Not logging `e`, for the same reason as the Anthropic client: a
      // socket error can carry part of the payload, and on the photo path
      // that payload is the photograph.
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

  /// OpenRouter's message content. **Text before image**, which its own image
  /// documentation recommends — and the opposite of what the Anthropic client
  /// sends, which is the clearest single reason these are two classes.
  Object _contentJson(MealContent content) => switch (content) {
    MealTextContent(:final text) => text,
    MealPhotoContent(:final mediaType, :final base64Data) => [
      {'type': 'text', 'text': mealPhotoContentPrompt},
      {
        'type': 'image_url',
        'image_url': {'url': 'data:$mediaType;base64,$base64Data'},
      },
    ],
  };

  /// Pulls the tool arguments out of the reply.
  ///
  /// Two shapes here that the Anthropic client does not have to think about.
  /// A generation that failed part-way through arrives as **HTTP 200** with
  /// `finish_reason: "error"` and the real status inside the choice, so the
  /// status line alone cannot be trusted. And `arguments` is a JSON string
  /// rather than an object, so it is decoded a second time.
  List<ParsedMealItem> _itemsFrom(String responseBody) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw const MealInterpreterException('malformed response');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const MealInterpreterException('response has no choices');
    }

    final choice = choices.first;
    if (choice is! Map) {
      throw const MealInterpreterException('response has no choices');
    }

    _throwIfFailedGeneration(choice);

    final message = choice['message'];
    final toolCalls = message is Map ? message['tool_calls'] : null;
    if (toolCalls is! List) {
      throw const MealInterpreterException('response has no tool call');
    }

    for (final call in toolCalls) {
      if (call is! Map) continue;
      final function = call['function'];
      if (function is! Map) continue;
      if (function['name'] != mealItemsToolName) continue;

      return mealItemsFromJson(_argumentsFrom(function['arguments']));
    }

    throw const MealInterpreterException('response has no tool call');
  }

  /// A 200 that is not a success.
  ///
  /// The embedded code is carried out as the exception's status so the whole
  /// taxonomy — auth, rejected request, capability refusal, transient — works
  /// the same for a failure that arrived this way as for one that arrived on
  /// the status line. A caller should not have to know which envelope its
  /// provider used to report a rate limit.
  void _throwIfFailedGeneration(Map<dynamic, dynamic> choice) {
    if (choice['finish_reason'] != 'error') return;

    final error = choice['error'];
    final code = error is Map ? error['code'] : null;
    _log.warning('Interpreter generation failed with $code');
    throw MealInterpreterException(
      'generation failed',
      statusCode: code is int ? code : null,
    );
  }

  /// `arguments` is documented as a string of JSON. An object is accepted too
  /// rather than failing a reply that is otherwise exactly right — some
  /// providers send one, and the schema is enforced either way.
  Object? _argumentsFrom(Object? arguments) {
    final Object? decoded;
    if (arguments is String) {
      try {
        decoded = jsonDecode(arguments);
      } catch (_) {
        throw const MealInterpreterException(
          'tool call has malformed arguments',
        );
      }
    } else {
      decoded = arguments;
    }

    return decoded is Map ? decoded['items'] : null;
  }
}
