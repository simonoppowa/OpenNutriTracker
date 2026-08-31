import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Asks an OpenAI model for food items, reached directly.
///
/// A third sibling rather than a shared OpenAI-dialect base with
/// [OpenAiCompatibleMealItemsApi], settled in #685 by measurement: only three
/// elements transfer between them. OpenRouter speaks *Chat Completions*,
/// where tools nest inside a `function` object and the system prompt is the
/// first message; this speaks *Responses*, where tools are flat and the
/// system prompt is a top-level `instructions` field. The reply shapes agree
/// on nothing either — one returns `choices[].message.tool_calls`, the other
/// an `output` list to search for a `function_call`.
///
/// **Responses, not Chat Completions**, and not for storage reasons — both
/// endpoints store by default, and `store: false` is what turns that off.
/// From GPT-5.4, tool calling is unsupported in Chat Completions with
/// `reasoning: none`, so the alternative pays reasoning tokens on every meal
/// line the user types. Settled in #681.
class OpenAiMealItemsApi implements MealItemsApi {
  static final _log = Logger('OpenAiMealItemsApi');

  static const _endpoint = 'https://api.openai.com/v1/responses';

  static const _maxOutputTokens = 1024;

  static const defaultTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String Function() _apiKey;

  /// No default, for the same reason as the OpenRouter client: which model is
  /// fit for this is a curation question whose answer changes, and a constant
  /// here would quietly become that answer. The list lives in
  /// `AiModelCatalogue`, where a behavioural screen justifies each entry.
  final String model;

  final Duration timeout;

  OpenAiMealItemsApi(
    this._client,
    this._apiKey, {
    required this.model,
    this.timeout = defaultTimeout,
  });

  @override
  Future<MealTextParseResult> requestItems({
    required MealContent content,
    required String system,
  }) async {
    final body = jsonEncode({
      'model': model,
      // Responses carries the system prompt here. There is no system role in
      // the input array — passing one is silently treated as user text.
      'instructions': system,
      'input': [
        {'role': 'user', 'content': _contentJson(content)},
      ],
      'tools': [
        {
          // Flat: `name` and `parameters` are siblings of `type`. Chat
          // Completions nests both inside a `function` object, and sending
          // that shape here is rejected.
          'type': 'function',
          'name': mealItemsToolName,
          'description': mealItemsToolDescription,
          'parameters': mealItemsToolSchema,
          // **Explicit, and the whole reason this line exists.** Omitting
          // `strict` on Responses does not leave the schema alone — it
          // normalises it into strict mode, which requires every key in
          // `properties` to appear in `required` and refuses the request
          // otherwise. `quantity` and `unit` are deliberately optional, so
          // doing nothing 400s every call: here the dangerous option is the
          // one that looks like no option.
          //
          // Strict would buy this design nothing anyway. Enforcement is in
          // Dart — `mealItemsFromJson` reads three keys and drops the rest,
          // and `validateParsedMealItems` handles an unrecognised unit
          // better than a refusal would, by dropping the unit and keeping
          // the food. Settled in #683, generalised there into a standing
          // rule: the app never relies on provider-side constrained
          // decoding.
          'strict': false,
        },
      ],
      'tool_choice': {'type': 'function', 'name': mealItemsToolName},
      // The app never leaves content on a provider's side that it can avoid
      // leaving. Responses stores by default, so this is not a no-op.
      'store': false,
      'max_output_tokens': _maxOutputTokens,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer ${_apiKey()}',
            },
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      // Not logging `e`, matching both other clients: a socket error can
      // carry part of the request, and on the photo path the request is the
      // photograph.
      throw const MealInterpreterException('request failed');
    }

    if (response.statusCode != 200) {
      _log.warning('Interpreter call failed with ${response.statusCode}');
      throw MealInterpreterException(
        'provider returned ${response.statusCode}',
        failure: _failureFor(response.statusCode, _errorFields(response.body)),
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const MealInterpreterException('malformed response');
    }

    return validateParsedMealItems(
      _itemsFrom(decoded),
      // Only the typed path corroborates: a photograph states no units at
      // all, and its own counts-only filter already drops them.
      statedIn: content is MealTextContent ? content.text : null,
    );
  }

  /// Responses content. **Image before text**, matching the Anthropic client
  /// and the opposite of OpenRouter's, whose own image documentation asks for
  /// text first.
  List<Map<String, Object?>> _contentJson(MealContent content) =>
      switch (content) {
        MealTextContent(:final text) => [
          {'type': 'input_text', 'text': text},
        ],
        MealPhotoContent(:final mediaType, :final base64Data) => [
          {
            'type': 'input_image',
            'image_url': 'data:$mediaType;base64,$base64Data',
          },
          {'type': 'input_text', 'text': mealPhotoContentPrompt},
        ],
      };

  /// The items from the forced tool call.
  ///
  /// The call is one element of `output`, which also carries reasoning
  /// summaries and any prose the model produced, so it has to be searched for
  /// rather than indexed. Its `arguments` is a JSON *string*, as on the
  /// OpenRouter path and unlike Anthropic's, which returns an object.
  List<ParsedMealItem> _itemsFrom(Map<String, dynamic> decoded) {
    final output = decoded['output'];
    if (output is! List) {
      throw const MealInterpreterException('response has no output');
    }

    for (final entry in output) {
      if (entry is! Map || entry['type'] != 'function_call') continue;
      // Checked, not assumed, and both other clients check it too. Only one
      // tool is offered and `tool_choice` names it, so a call by another name
      // should be impossible — but "impossible" here means parsing whatever
      // arrived as though it were a meal, and the cost of the check is a
      // line.
      if (entry['name'] != mealItemsToolName) continue;
      final arguments = entry['arguments'];
      if (arguments is! String) {
        throw const MealInterpreterException('tool call has no arguments');
      }
      final Object? parsed;
      try {
        parsed = jsonDecode(arguments);
      } catch (_) {
        // Never the body: on the photo path a malformed reply can still
        // contain what was sent.
        throw const MealInterpreterException('tool call arguments malformed');
      }
      if (parsed is! Map) {
        throw const MealInterpreterException('tool call is not an object');
      }
      return mealItemsFromJson(parsed['items']);
    }

    // A forced tool call that came back as prose. Raising beats returning
    // empty: empty means "no food in this", and reporting that for a
    // photograph of a meal is the failure #669 found to be worse than a
    // wrong answer, because the review screen makes a wrong answer visible
    // and makes an empty one look like a broken feature.
    throw MealInterpreterException(
      'response carried no tool call',
      // Not the default `transient`, which would send the user to check a
      // connection that just delivered a 200. A model that will not call the
      // tool will not call it next time either, and `unsupported` already
      // names exactly this: "no provider of it honours a forced tool call".
      // Ollama has no `tool_choice` field at all (#733), so on the most
      // popular local runtime this is the expected failure rather than a
      // rare one, and #779's probe has to be able to tell it from a blip.
      failure: MealInterpreterFailure.unsupported,
    );
  }

  /// The provider's machine-readable error fields, or nulls.
  ///
  /// Only the codes — never the message. OpenAI's 401 body echoes the key in
  /// a partially masked form that still carries its real last four
  /// characters, so the message is not a safe thing to keep hold of.
  ///
  /// **Both `code` and `type`**, because they are not the same question and
  /// billing is where the difference shows. OpenAI's guidance is to *"inspect
  /// `error.code` to identify the specific cause"* while *"the broader
  /// `error.type` can still be `insufficient_quota`"* — so `code` may carry
  /// something narrower than the state the app has to act on, and reading it
  /// alone would miss exactly the accounts whose cause is spelled out.
  static ({String? code, String? type}) _errorFields(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        return (
          code: error['code'] is String ? error['code'] as String : null,
          type: error['type'] is String ? error['type'] as String : null,
        );
      }
    } catch (_) {
      // Not JSON, or not the shape documented. Classification falls back to
      // the status alone, which is the pre-#686 behaviour.
    }
    return (code: null, type: null);
  }

  /// What a status means here — #695 put this in each client precisely so a
  /// provider that disagrees has somewhere to say so, and this one disagrees.
  ///
  /// **A withdrawn model answers 400, not the 404 both other providers use**,
  /// and 400 is also what a rejected image returns. The catalogue's promise
  /// that a stale entry "fails loudly" rests on the difference, so the code
  /// field carries it: `model_not_found` is `unsupported`, which tells the
  /// user to choose a different model — advice that works, and that the
  /// second catalogue entry makes actionable. Classifying it as `rejected`
  /// instead would tell someone whose model was retired to go and retake
  /// their photograph, forever. Measured in #684 and #686.
  /// **A 429 is two different failures wearing one status.** Both other
  /// providers separate an empty balance from going too fast by status alone
  /// — 402 against 429 — and this one does not: an exhausted prepaid balance
  /// arrives as 429 on many accounts. The status line is therefore not enough
  /// here, which is why this client reads the body at all. OpenAI says as
  /// much itself about retrying: *"Don't retry quota, billing, or other
  /// errors that require you to take action."*
  ///
  /// A bare 429 stays `transient`, because ordinary rate limiting is the
  /// common case and does clear on its own. A 429 that names
  /// `insufficient_quota` does not clear, and calling it transient told a
  /// user with an empty balance to try again later — forever, with the
  /// interpreter silently falling back on every attempt and nothing on screen
  /// ever naming the one thing that would fix it.
  static MealInterpreterFailure _failureFor(
    int statusCode,
    ({String? code, String? type}) error,
  ) => switch (statusCode) {
    401 || 403 => MealInterpreterFailure.auth,
    400 when error.code == 'model_not_found' =>
      MealInterpreterFailure.unsupported,
    400 || 422 => MealInterpreterFailure.rejected,
    402 => MealInterpreterFailure.billing,
    429 when error.code == _quotaCode || error.type == _quotaCode =>
      MealInterpreterFailure.billing,
    404 => MealInterpreterFailure.unsupported,
    _ => MealInterpreterFailure.transient,
  };

  /// What OpenAI calls an exhausted balance, in either field.
  static const _quotaCode = 'insufficient_quota';
}
