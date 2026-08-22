import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_photo_encoder.dart';

/// Answers each request from a script, so the text probe and the photo probe
/// can be given different outcomes in one run — which is the whole point of
/// storing two verdicts rather than one.
class _ScriptedClient extends http.BaseClient {
  final List<http.StreamedResponse Function(http.BaseRequest)> _script;
  final requests = <Map<String, dynamic>>[];

  _ScriptedClient(this._script);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(
      jsonDecode((request as http.Request).body) as Map<String, dynamic>,
    );
    final step =
        _script[requests.length - 1 < _script.length
            ? requests.length - 1
            : _script.length - 1];
    return step(request);
  }
}

http.StreamedResponse Function(http.BaseRequest) _reply(
  String body, {
  int status = 200,
}) =>
    (request) => http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );

http.StreamedResponse Function(http.BaseRequest) _throws(Object error) =>
    (request) => throw error;

String _toolReply(List<Map<String, dynamic>> items) => jsonEncode({
  'choices': [
    {
      'message': {
        'tool_calls': [
          {
            'function': {
              'name': mealItemsToolName,
              'arguments': jsonEncode({'items': items}),
            },
          },
        ],
      },
    },
  ],
});

/// A well-formed 200 that answers in prose. The expected way a weak model
/// fails on Ollama, which has no `tool_choice` field at all (#733).
const _prose = '{"choices":[{"message":{"content":"That looks like bread."}}]}';

const _selection = AiSelection(
  provider: AiProvider.ownServer,
  endpoint: 'http://192.168.1.5:11434/v1/chat/completions',
  modelId: 'gemma3:4b',
);

AiEndpointProber _prober(
  _ScriptedClient client, {
  List<MealPhotoFormat>? formatsAskedFor,
  MealPhoto? photo,
}) => AiEndpointProber(
  client,
  sampleImage: (format) async {
    formatsAskedFor?.add(format);
    return photo ??
        MealPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          mediaType: format.mediaType,
        );
  },
);

void main() {
  group('the pass bar is at least one item, not merely a reply', () {
    test('items come back, so the capability is proven', () async {
      final client = _ScriptedClient([
        _reply(
          _toolReply([
            {'query': 'bread'},
          ]),
        ),
      ]);

      final result = await _prober(client).probe(_selection);

      expect(result.text, AiCapability.passed);
      expect(result.photo, AiCapability.passed);
    });

    test('a well-formed reply with no items is a failure', () async {
      // The measured case, and the reason the bar is not "it replied":
      // `openai/gpt-5.4-nano` advertised every capability, accepted
      // food-bearing photographs, and returned an empty list for all of
      // them. A probe that accepted this would offer a camera that always
      // comes back with nothing.
      final client = _ScriptedClient([_reply(_toolReply([]))]);

      final result = await _prober(client).probe(_selection);

      expect(result.text, AiCapability.failed);
      expect(result.photo, AiCapability.failed);
    });

    test('a reply in prose is a failure, not an inconclusive one', () async {
      // Ollama cannot be told to force a tool call, so this is the ordinary
      // way a small model fails there rather than an exotic one. It has to
      // be told apart from a server that never answered.
      final client = _ScriptedClient([_reply(_prose)]);

      final result = await _prober(client).probe(_selection);

      expect(result.text, AiCapability.failed);
      expect(result.photo, AiCapability.failed);
    });
  });

  group('what is not conclusive stays unknown', () {
    test('an unreachable endpoint produces no verdict at all', () async {
      final client = _ScriptedClient([_throws(Exception('no route to host'))]);

      final result = await _prober(client).probe(_selection);

      expect(result.text, AiCapability.unknown);
      expect(result.photo, AiCapability.unknown);
      // And nothing is stored: the encoded form of unknown is absence.
      expect(result.encode(), '--');
    });

    test('a 500 is the server having a bad day, not a verdict', () async {
      final client = _ScriptedClient([_reply('{}', status: 500)]);

      final result = await _prober(client).probe(_selection);

      expect(result.text, AiCapability.unknown);
    });

    test('a photo the app could not encode blames nobody', () async {
      // The encoder returning null is the app's problem — a device with no
      // encoder — and recording `failed` would pin it on the user's server.
      final client = _ScriptedClient([
        _reply(
          _toolReply([
            {'query': 'bread'},
          ]),
        ),
      ]);
      final prober = AiEndpointProber(client, sampleImage: (_) async => null);

      expect(await prober.probePhoto(_selection), AiCapability.unknown);
      // ...and nothing was sent for it.
      expect(client.requests, isEmpty);
    });
  });

  test('the two verdicts are independent', () async {
    // The common case for a small local model: it handles a meal line and
    // cannot see. One combined verdict could not express it, and the text
    // half is what keeps the feature usable at all.
    final client = _ScriptedClient([
      _reply(
        _toolReply([
          {'query': 'eggs'},
        ]),
      ),
      _reply(_prose),
    ]);

    final result = await _prober(client).probe(_selection);

    expect(result.text, AiCapability.passed);
    expect(result.photo, AiCapability.failed);
    expect(result.encode(), 'pf');
  });

  test('the photo probe asks for the container the real path sends', () async {
    // #778 chose JPEG for this provider because llama.cpp cannot decode
    // WebP. A probe that tested a different container would certify an
    // endpoint for a request the app never makes.
    final formats = <MealPhotoFormat>[];
    final client = _ScriptedClient([
      _reply(
        _toolReply([
          {'query': 'bread'},
        ]),
      ),
    ]);

    await _prober(client, formatsAskedFor: formats).probePhoto(_selection);

    expect(formats, [MealPhotoFormat.jpeg]);
  });

  test(
    'it probes with the shipping schema, carrying no macro fields',
    () async {
      // The provenance guarantee does not get a holiday because this request
      // is a probe rather than a meal.
      final client = _ScriptedClient([
        _reply(
          _toolReply([
            {'query': 'bread'},
          ]),
        ),
      ]);

      await _prober(client).probe(_selection);

      final tool = (client.requests.first['tools'] as List).single as Map;
      final params =
          (tool['function'] as Map)['parameters'] as Map<String, dynamic>;
      final item =
          ((params['properties'] as Map)['items'] as Map)['items'] as Map;
      expect(
        (item['properties'] as Map).keys,
        unorderedEquals(['query', 'quantity', 'unit']),
      );
    },
  );

  test('the probe budget clears a cold model load with room over', () async {
    // The probe is by definition the first request a machine ever sees, so
    // its model is cold every time. Measured against a real Ollama on an M4
    // Mac mini: 29s for the text probe and 37s for the photo probe, both
    // from cold. The hosted 20s default would have failed both.
    expect(aiEndpointProbeTimeout.inSeconds, greaterThan(37 * 2));
  });
}
