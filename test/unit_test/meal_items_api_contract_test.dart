import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openai_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/openrouter_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

/// The rules every [MealItemsApi] must obey, whatever wire format it speaks.
///
/// The clients are deliberately independent siblings — #681 measured that only
/// three elements transfer between them — so nothing structural stops a future
/// client from being perfectly plausible and quietly breaking a guarantee the
/// app's privacy claim rests on. Until this file existed, the rules lived in
/// comments:
///
/// > Deliberately not logging `e`: a socket error can carry the request URL
/// > and, on some platforms, part of the payload — which for the photo path
/// > is the photograph.
///
/// Both shipped clients say a version of that in their own words, and nothing
/// checked either of them. These cases check all of them at once.
///
/// **Adding a provider means adding one entry to [_contracts].** Do not give a
/// client an exemption from a case; an exemption is how the next leak gets
/// written.
///
/// **Not here: the counts-never-measurements rule.** #706 listed it, and it
/// does not belong — it is enforced by `ModelMealPhotoInterpreter`, of which
/// there is exactly one, shared by every provider. A per-client suite cannot
/// pin a rule no client can break. Its tests live with that class.
void main() {
  for (final contract in _contracts) {
    group(contract.name, () {
      test('a failing send puts the payload in neither the error nor the log', () async {
        // The transport throws something that carries the submitted text, the
        // way a real socket error carries the request it failed on.
        final client = _FakeClient(
          throwOnSend: _LeakyException('connection reset while sending $_secret'),
        );

        final logged = await _logsDuring(() async {
          await expectLater(
            contract.build(client).requestItems(
              content: const MealTextContent(_secret),
              system: 'system',
            ),
            throwsA(isA<MealInterpreterException>()),
          );
        });

        final raised = await _raisedBy(contract, client, const MealTextContent(_secret));
        expect(
          raised.toString(),
          isNot(contains(_secret)),
          reason: 'the exception must not carry what the user typed',
        );
        expect(
          logged.join('\n'),
          isNot(contains(_secret)),
          reason: 'a socket error must never be logged with its payload',
        );
      });

      test('a photo never reaches the error or the log either', () async {
        final client = _FakeClient(
          throwOnSend: _LeakyException('send failed: $_photoBytes'),
        );
        const photo = MealPhotoContent(
          mediaType: 'image/webp',
          base64Data: _photoBytes,
        );

        final logged = await _logsDuring(() async {
          await expectLater(
            contract.build(client).requestItems(content: photo, system: 'system'),
            throwsA(isA<MealInterpreterException>()),
          );
        });

        // Mirrors the text case above: a leaky transport error must not
        // surface the payload via the exception either, not just the log.
        final raised = await _raisedBy(contract, client, photo);
        expect(
          raised.toString(),
          isNot(contains(_photoBytes)),
          reason: 'the exception must not carry the photo bytes',
        );
        expect(logged.join('\n'), isNot(contains(_photoBytes)));
      });

      test('a rejected request does not carry the response body', () async {
        // Provider error payloads routinely echo the submitted text back.
        final client = _FakeClient(
          status: 400,
          body: jsonEncode({
            'error': {'message': 'could not parse: $_secret'},
          }),
        );

        final logged = await _logsDuring(() async {
          await expectLater(
            contract.build(client).requestItems(
              content: const MealTextContent(_secret),
              system: 'system',
            ),
            throwsA(
              isA<MealInterpreterException>().having(
                (e) => e.toString(),
                'toString',
                isNot(contains(_secret)),
              ),
            ),
          );
        });

        expect(logged.join('\n'), isNot(contains(_secret)));
      });

      test('a stalled connection gives up instead of hanging', () async {
        final client = _FakeClient(hangs: true);

        // Wrapped in an explicit short timeout so a client that regresses
        // its own `.timeout(...)` wiring fails this assertion in ~2s rather
        // than hanging until the test runner's own default timeout — which
        // grows every time a provider is added to this suite.
        await expectLater(
          contract
              .build(client, timeout: const Duration(milliseconds: 20))
              .requestItems(
                content: const MealTextContent('toast'),
                system: 'system',
              )
              .timeout(
                const Duration(seconds: 2),
                onTimeout: () => fail(
                  '${contract.name} did not honour its own timeout — the '
                  'request should have failed in ~20ms',
                ),
              ),
          throwsA(isA<MealInterpreterException>()),
        );
      });

      test('output is held to the parser bounds, not the model', () async {
        // 99999 g is past the 10000 ceiling manual entry enforces. No client
        // may write to the diary under looser rules than a regex does.
        final client = _FakeClient(
          body: contract.toolReply([
            {'query': 'toast', 'quantity': 99999, 'unit': 'g'},
          ]),
        );

        final result = await contract.build(client).requestItems(
          content: const MealTextContent('toast'),
          system: 'system',
        );

        expect(result.items, isEmpty);
        expect(result.errors, isNotEmpty);
      });

      test('a reply with no tool call raises rather than reading as empty', () async {
        // "No food in this photo" is only trustworthy if a model that ignored
        // the tool call cannot be mistaken for one that answered nothing.
        final client = _FakeClient(body: contract.noToolCall);

        await expectLater(
          contract.build(client).requestItems(
            content: const MealTextContent('toast'),
            system: 'system',
          ),
          throwsA(isA<MealInterpreterException>()),
        );
      });
    });
  }
}

/// A meal note distinctive enough that any leak of it is unmistakable.
const _secret = 'zzq-private-meal-note-zzq';

/// Stands in for base64 photo bytes.
const _photoBytes = 'zzq-photo-payload-zzq';

class _ClientContract {
  final String name;
  final MealItemsApi Function(http.Client client, {required Duration timeout})
  _build;

  /// A 200 body carrying a forced tool call with these raw item maps, in this
  /// provider's own shape.
  final String Function(List<Map<String, dynamic>> items) toolReply;

  /// A well-formed 200 that carries no tool call at all.
  final String noToolCall;

  const _ClientContract({
    required this.name,
    required MealItemsApi Function(http.Client, {required Duration timeout})
    build,
    required this.toolReply,
    required this.noToolCall,
  }) : _build = build;

  MealItemsApi build(
    http.Client client, {
    Duration timeout = const Duration(seconds: 20),
  }) => _build(client, timeout: timeout);
}

final _contracts = <_ClientContract>[
  _ClientContract(
    name: 'AnthropicMealItemsApi',
    build: (client, {required timeout}) =>
        AnthropicMealItemsApi(client, () => 'test-key', timeout: timeout),
    toolReply: (items) => jsonEncode({
      'id': 'msg_1',
      'type': 'message',
      'role': 'assistant',
      'content': [
        {
          'type': 'tool_use',
          'id': 'tu_1',
          'name': mealItemsToolName,
          'input': {'items': items},
        },
      ],
    }),
    noToolCall: jsonEncode({
      'id': 'msg_1',
      'type': 'message',
      'role': 'assistant',
      'content': [
        {'type': 'text', 'text': 'Here are the foods I can see.'},
      ],
    }),
  ),
  _ClientContract(
    name: 'OpenRouterMealItemsApi',
    build: (client, {required timeout}) => OpenRouterMealItemsApi(
      client,
      () => 'test-key',
      model: 'anthropic/claude-haiku-4.5',
      timeout: timeout,
    ),
    toolReply: (items) => jsonEncode({
      'id': 'gen_1',
      'choices': [
        {
          'finish_reason': 'tool_calls',
          'message': {
            'role': 'assistant',
            'tool_calls': [
              {
                'id': 'call_1',
                'type': 'function',
                'function': {
                  'name': mealItemsToolName,
                  'arguments': jsonEncode({'items': items}),
                },
              },
            ],
          },
        },
      ],
    }),
    noToolCall: jsonEncode({
      'id': 'gen_1',
      'choices': [
        {
          'finish_reason': 'stop',
          'message': {'role': 'assistant', 'content': 'Here are the foods.'},
        },
      ],
    }),
  ),
  _ClientContract(
    name: 'OpenAiMealItemsApi',
    build: (client, {required timeout}) => OpenAiMealItemsApi(
      client,
      () => 'test-key',
      model: 'gpt-5.6-luna',
      timeout: timeout,
    ),
    // Responses returns a list to search rather than a slot to index, and
    // the reasoning entry is here on purpose: the client must find the tool
    // call past it, not assume it is first.
    toolReply: (items) => jsonEncode({
      'id': 'resp_1',
      'object': 'response',
      'status': 'completed',
      'output': [
        {'type': 'reasoning', 'id': 'rs_1', 'summary': []},
        {
          'type': 'function_call',
          'id': 'fc_1',
          'call_id': 'call_1',
          'name': mealItemsToolName,
          'arguments': jsonEncode({'items': items}),
        },
      ],
    }),
    noToolCall: jsonEncode({
      'id': 'resp_1',
      'object': 'response',
      'status': 'completed',
      'output': [
        {
          'type': 'message',
          'role': 'assistant',
          'content': [
            {'type': 'output_text', 'text': 'Here are the foods I can see.'},
          ],
        },
      ],
    }),
  ),
];

/// Runs [body] and returns everything the app logged while it ran, so a rule
/// about what must *not* be logged can actually fail.
Future<List<String>> _logsDuring(Future<void> Function() body) async {
  final logged = <String>[];
  final previousLevel = Logger.root.level;
  Logger.root.level = Level.ALL;
  final subscription = Logger.root.onRecord.listen(
    (record) => logged.add('${record.message} ${record.error ?? ''}'),
  );
  try {
    await body();
  } finally {
    await subscription.cancel();
    Logger.root.level = previousLevel;
  }
  return logged;
}

/// The exception a client raises for [client] against [content], for
/// asserting on directly.
Future<Object> _raisedBy(
  _ClientContract contract,
  _FakeClient client,
  MealContent content,
) async {
  try {
    await contract.build(client).requestItems(content: content, system: 'system');
  } catch (e) {
    return e;
  }
  fail('expected the client to raise');
}

/// An error whose own `toString` carries the payload — what a real socket
/// failure can do, and the reason clients must not log the caught object.
class _LeakyException implements Exception {
  final String message;
  const _LeakyException(this.message);

  @override
  String toString() => message;
}

class _FakeClient extends http.BaseClient {
  final int status;
  final String body;
  final Object? throwOnSend;
  final bool hangs;

  _FakeClient({
    this.status = 200,
    this.body = '{}',
    this.throwOnSend,
    this.hangs = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (throwOnSend != null) throw throwOnSend!;
    if (hangs) return Completer<http.StreamedResponse>().future;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}
