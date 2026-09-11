// The three hosted providers the measurement runs against, built the way
// `meal_items_api_factory.dart` builds them, plus the wire-level recorder
// that lets the harness see what a model *said* before validation edited it.
//
// The model ids are copied from `lib/core/utils/ai_model_catalogue.dart`
// rather than imported: that file reaches `flutter_secure_storage` through
// `ai_credential_storage.dart`, and `dart run` cannot compile a Flutter
// import. `test/unit_test/portion_measurement_parity_test.dart` pins the
// copies to the catalogue so a change there fails a test here.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openai_compatible_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openai_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

enum Provider { anthropic, openrouter, openai }

/// `AiModelCatalogue.defaultFor(provider).id` — the first entry of each list,
/// which is what a user who never opened the model picker is sent to.
const defaultModelIds = <Provider, String>{
  Provider.anthropic: 'claude-haiku-4-5',
  Provider.openrouter: 'anthropic/claude-sonnet-5',
  Provider.openai: 'gpt-5.6-luna',
};

/// `AiModel.providers` for the OpenRouter default: pinned to Anthropic with
/// fallbacks off, so the vendor that answers is the vendor the app names.
const openRouterPins = <String, List<String>>{
  'anthropic/claude-sonnet-5': ['anthropic'],
};

/// The client for [provider], over [client], with the key read through
/// [key] at request time — the same three constructor calls the factory
/// makes for the hosted providers.
MealItemsApi buildApi(
  Provider provider,
  http.Client client,
  String Function() key,
) {
  final model = defaultModelIds[provider]!;
  return switch (provider) {
    Provider.anthropic => AnthropicMealItemsApi(client, key, model: model),
    Provider.openrouter => OpenAiCompatibleMealItemsApi.openRouter(
      client,
      key,
      model: model,
      providers: openRouterPins[model],
    ),
    Provider.openai => OpenAiMealItemsApi(client, key, model: model),
  };
}

/// Where the harness gets the model's reply *before* `validateParsedMealItems`
/// and the photo path's counts-only filter edited it.
///
/// The interpreters return validated items, and validation drops exactly the
/// things this measurement has to count — a unit the text never stated, a
/// unit outside the enum on a photo. So the raw `items` array is taken off
/// the wire (or, in a dry run, straight from the fake) and keyed by a
/// substring of the request that identifies it: the meal line, or a prefix
/// of the photo's base64.
abstract interface class RawReplySource {
  /// The raw items of the reply to the request carrying [needle], removed
  /// from the store so a repeat of the same line finds the next reply. Null
  /// when nothing matched — a failed call, or a body that held no items.
  List<Map<String, Object?>>? takeRawItems(String needle);
}

/// An `http.Client` that keeps every request/response body pair so the raw
/// items can be recovered afterwards. Never logs: a request body carries
/// the meal line and a photo, and a header carries the key, so neither is
/// written anywhere but this list.
class RecordingClient extends http.BaseClient implements RawReplySource {
  final http.Client _inner;
  final _pairs = <({String request, String response})>[];

  RecordingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestBody = request is http.Request ? request.body : '';
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    _pairs.add((request: requestBody, response: utf8.decode(bytes)));
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  /// Consumes every pair for [needle] — a retried call leaves the failed
  /// attempt's body ahead of the one that succeeded — and returns the first
  /// that holds items.
  @override
  List<Map<String, Object?>>? takeRawItems(String needle) {
    List<Map<String, Object?>>? found;
    _pairs.removeWhere((p) {
      if (!p.request.contains(needle)) return false;
      found ??= extractRawItems(p.response);
      return true;
    });
    return found;
  }

  @override
  void close() => _inner.close();
}

/// The `items` array wherever a provider put it.
///
/// Anthropic returns it as `content[].input.items`; the OpenAI-compatible
/// shape returns `choices[].message.tool_calls[].function.arguments` as a
/// JSON *string* with `items` inside. Rather than know three layouts, this
/// walks the decoded body, decodes any string that itself parses as JSON,
/// and returns the first list under an `items` key whose entries are maps.
List<Map<String, Object?>>? extractRawItems(String body) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return null;
  }
  return _findItems(decoded, depth: 0);
}

List<Map<String, Object?>>? _findItems(Object? node, {required int depth}) {
  if (depth > 12) return null;
  if (node is Map) {
    final items = node['items'];
    if (items is List && items.every((e) => e is Map)) {
      return [for (final e in items) Map<String, Object?>.from(e as Map)];
    }
    for (final value in node.values) {
      final found = _findItems(value, depth: depth + 1);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _findItems(value, depth: depth + 1);
      if (found != null) return found;
    }
  } else if (node is String && node.trimLeft().startsWith('{')) {
    try {
      return _findItems(jsonDecode(node), depth: depth + 1);
    } on FormatException {
      return null;
    }
  }
  return null;
}

/// The needle for a text request: the line as `jsonEncode` writes it inside
/// the request body, quotes included. The quotes matter: every client sends
/// the line as a whole JSON string value, so `"banana"` cannot match the
/// request for `"2 banana"` that another lane has in flight, and the
/// escaping means a line with a newline or a quote in it still matches the
/// form on the wire.
String textNeedle(String line) => jsonEncode(line.trim());

/// The needle for a photo request: a slice from the middle of the base64,
/// because the start of two JPEGs is the same header bytes.
String photoNeedle(String base64Data) {
  if (base64Data.length <= 96) return base64Data;
  final start = base64Data.length ~/ 2;
  return base64Data.substring(start, start + 96);
}
