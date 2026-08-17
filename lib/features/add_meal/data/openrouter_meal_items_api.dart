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
            // **No `strict: true`.** It looks like free rigour and is not.
            //
            // OpenAI's strict mode requires every key in `properties` to
            // also appear in `required`, and refuses the whole request
            // otherwise: "'required' is required to be supplied and to be an
            // array including every key in properties. Missing 'quantity'."
            // Measured — every call to every `openai/*` model failed with a
            // 400, text included.
            //
            // That constraint is *not* the reason to skip it, though this
            // comment used to say so. A nullable union satisfies strict
            // while keeping the field optional — OpenAI sanctions exactly
            // that: "it is possible to emulate an optional parameter by
            // using a union type with `null`" — and `_mealItemFrom` already
            // maps an explicit null to null, so absent and null already
            // produce the identical item. The option exists; it was
            // rejected for a reason that did not hold.
            //
            // The real reason is that strict buys this design nothing.
            // Enforcement is in Dart: `_mealItemFrom` reads three keys and
            // drops the rest, so a model emitting a calorie field loses it
            // regardless. And what strict would add — constraining the unit
            // enum, forbidding a missing `query` — `validateParsedMealItems`
            // already handles *better*, dropping an unrecognised unit and
            // keeping the food rather than refusing the whole reply.
            //
            // Settled in #683, which generalised it: the app never relies on
            // provider-side constrained decoding. See `mealItemsToolSchema`.
            //
            // A direct OpenAI client would have to send `strict: false`
            // explicitly — on the Responses API, omitting it normalises the
            // schema into strict mode rather than leaving it alone.
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
        // Routing default is `allow`, meaning providers that store input
        // non-transiently and may train on it are eligible. The app cannot
        // promise a destination's behaviour it never asked for.
        //
        // Enforced here as a policy field rather than by reading the slug:
        // free *usage* triggers the training clauses, not the `:free`
        // suffix, so slug inspection would be a check that looks like one
        // and is not.
        'data_collection': 'deny',
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
              // Opts the reply into `openrouter_metadata`, which names the
              // provider that actually served the request. Without it the
              // response says nothing about who received the payload, and a
              // project that invites you to verify its destination list
              // cannot be structurally unable to name one.
              'x-openrouter-metadata': 'enabled',
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

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const MealInterpreterException('malformed response');
    }

    _warnIfThePinDidNotHold(decoded);

    return validateParsedMealItems(_itemsFrom(decoded));
  }

  /// Checks that the provider named in the app is the one that answered.
  ///
  /// Settings states the serving vendor as a guarantee rather than a guess,
  /// and `only` + `allow_fallbacks: false` is what earns that word. This is
  /// the only way to find out at runtime whether it held — otherwise the app
  /// makes a claim about where a photograph went and never once checks it.
  ///
  /// Logged, never thrown. The reply is a valid answer to the user's
  /// question, and costing them their meal entry over a routing discrepancy
  /// would be a worse outcome than the discrepancy. The metadata is also
  /// absent on cache hits and on failures that never reached the router, so
  /// absence is not a finding.
  void _warnIfThePinDidNotHold(Map<String, dynamic> decoded) {
    final pinned = providers;
    if (pinned == null) return;

    final metadata = decoded['openrouter_metadata'];
    final endpoints = metadata is Map ? metadata['endpoints'] : null;
    final available = endpoints is Map ? endpoints['available'] : null;
    if (available is! List) return;

    for (final endpoint in available) {
      if (endpoint is! Map || endpoint['selected'] != true) continue;
      final servedBy = endpoint['provider'];
      if (servedBy is! String) continue;

      // Case-insensitive because the metadata names a provider in display
      // form ("Anthropic") while the pin is a slug ("anthropic"). That is a
      // heuristic and it can mismatch for a vendor whose display name is not
      // its slug — acceptable when the only consequence is a log line.
      final held = pinned.any(
        (provider) => provider.toLowerCase() == servedBy.toLowerCase(),
      );
      if (!held) _log.warning('Pinned to $pinned but served by $servedBy');
      return;
    }
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
  List<ParsedMealItem> _itemsFrom(Map<String, dynamic> decoded) {
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
