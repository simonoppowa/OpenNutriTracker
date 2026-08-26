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
      // No verdict, but the run itself is recorded. #850: this used to
      // encode to absence, which is also what "nobody has ever asked" encodes
      // to — so four minutes of waiting came back reading "Not checked yet."
      expect(result.checked, isTrue);
      expect(result.encode(), '--c');
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

  group('every failure kind is ruled on, not inherited (#854)', () {
    // The mapping in `_verdictForFailure` is the whole of #850's argument in
    // code: some failures say something durable about the destination and
    // some say nothing at all. Until now it was reached only sideways, via
    // an unreachable host and a 500 — so six of the seven members were
    // pinned by nothing. Flipping `auth` to `failed` is the plausible
    // mistake (a rejected key *feels* like a failure) and it would have
    // turned the camera off for a server that can see perfectly well.
    //
    // Driven through real status codes rather than by calling the mapper, so
    // these also pin `_failureFor`'s half of the journey.
    Future<AiCapability> textVerdictFor(int status) async {
      final client = _ScriptedClient([_reply('{}', status: status)]);
      final result = await _prober(client).probe(_selection);
      return result.text;
    }

    test('401 says nothing about what the model can do', () async {
      // A key problem is the user's to fix, and it is not a capability.
      // A server the user runs should not be answering this at all.
      expect(await textVerdictFor(401), AiCapability.unknown);
    });

    test('403 is NOT the same answer as 401 on this client', () async {
      // The trap this test exists for. On the direct OpenAI client 403 is
      // `permission_error` and pairs with 401 as auth — but a server the
      // user runs goes through `OpenAiCompatibleMealItemsApi`, where 403 is
      // documented as a guardrail block or moderation flag. Treating it as a
      // credential problem would send someone whose photo tripped a filter
      // off to check a key that works fine.
      //
      // So it is `rejected`, which is a real verdict: the request was
      // refused and will be refused again tomorrow.
      expect(await textVerdictFor(403), AiCapability.failed);
    });

    test('402 is a bill, not an ability', () async {
      expect(await textVerdictFor(402), AiCapability.unknown);
    });

    test('404 means nothing here serves this, and will not tomorrow', () async {
      // On Ollama, which has no `tool_choice` at all, this is the expected
      // way a weak model fails rather than a rare one (#733).
      expect(await textVerdictFor(404), AiCapability.failed);
    });

    test('400 is the request itself being refused', () async {
      expect(await textVerdictFor(400), AiCapability.failed);
    });

    test('422 is the same answer as 400', () async {
      expect(await textVerdictFor(422), AiCapability.failed);
    });

    test('an unrecognised status is not a verdict', () async {
      // Anything unclassified folds to transient, which is the whole reason
      // `unknown` exists — asleep, loading, or rate limited.
      expect(await textVerdictFor(418), AiCapability.unknown);
    });

    test('every one of them still records that a check ran', () async {
      // The #850 property, across the whole mapping rather than one case of
      // it: a verdict is a claim about knowledge, `checked` is a claim about
      // history, and no failure kind may quietly cost the second one.
      for (final status in [400, 401, 402, 403, 404, 422, 418, 500]) {
        final client = _ScriptedClient([_reply('{}', status: status)]);
        final result = await _prober(client).probe(_selection);
        expect(
          result.checked,
          isTrue,
          reason: 'a $status left the run looking like it never happened',
        );
      }
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
    expect(result.encode(), 'pfc');
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

  test('two overlapping probes do not share a temp file', () async {
    // Copilot caught this on #784: the probe photo was written to a fixed
    // path and then deleted by `encodeAndDiscardSource`, so two probes in
    // flight at once — a user saving twice quickly, a retry overlapping one
    // still running — would race on the same file.
    //
    // Asserted on the paths rather than by provoking the race: a
    // scheduling-dependent test that passes on a fast machine and fails in
    // CI is worse than no test.
    final paths = <String>{
      for (var i = 0; i < 50; i++) probePhotoTempPath('/tmp'),
    };

    expect(paths, hasLength(50));
  });

  test('the probe budget clears a cold model load with room over', () async {
    // The probe is by definition the first request a machine ever sees, so
    // its model is cold every time. Measured against a real Ollama on an M4
    // Mac mini: 29s for the text probe and 37s for the photo probe, both
    // from cold. The hosted 20s default would have failed both.
    expect(aiEndpointProbeTimeout.inSeconds, greaterThan(37 * 2));
  });

  group('the quoted wait is derived from the probe timeout (#851)', () {
    test('changing the timeout changes the stated duration', () {
      // The acceptance criterion, and the reason this takes an argument at
      // all: a figure read from the constant inside the body could only ever
      // be checked against itself, and the bug being fixed is exactly a
      // second number that stopped tracking the first.
      expect(aiProbeWorstCaseMinutes(const Duration(seconds: 120)), 4);
      expect(aiProbeWorstCaseMinutes(const Duration(seconds: 60)), 2);
      expect(aiProbeWorstCaseMinutes(const Duration(seconds: 300)), 10);
      expect(
        aiProbeWorstCaseMinutes(const Duration(seconds: 20)),
        1,
        reason: 'the hosted budget, which does not reach a whole minute',
      );
    });

    test('it covers both legs, not one', () {
      // The whole of #851 in one line. The old copy said "one to two
      // minutes", which is what a *single* 120s leg rounds to — the two-leg
      // worst case measured 4m00s on a Pixel 6.
      expect(
        aiProbeWorstCaseMinutes(const Duration(seconds: 120)),
        greaterThan(const Duration(seconds: 120).inMinutes),
      );
      expect(aiProbeLegCount, 2, reason: 'text, then photo');
    });

    test('a remainder rounds up rather than down', () {
      // A wait a run can outlast is the bug, in miniature. 200s of budget is
      // 3m20s, and quoting three minutes would send the user back early to
      // the same "still going" screen the four-minute promise was meant to
      // spare them.
      expect(aiProbeWorstCaseMinutes(const Duration(seconds: 100)), 4);
      expect(aiProbeWorstCaseMinutes(const Duration(seconds: 91)), 4);
    });

    test('what the dialog quotes today is four minutes', () {
      // Pins the derivation to the shipping constant, so a timeout change
      // that should move the copy cannot pass unnoticed.
      expect(aiProbeWorstCaseMinutes(), 4);
      expect(
        aiProbeWorstCaseMinutes(),
        aiProbeWorstCaseMinutes(aiEndpointProbeTimeout),
      );
    });
  });
}
