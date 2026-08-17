import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/data/model_meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/data/openrouter_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

/// Captures the outgoing request and replays a canned reply. Nothing in this
/// file touches the network.
class FakeClient extends http.BaseClient {
  final int status;
  final String body;
  final Object? throwOnSend;

  /// Never completes, standing in for a connection that stalls.
  final bool hangs;

  Map<String, dynamic>? sentBody;
  Map<String, String>? sentHeaders;
  Uri? sentUrl;

  FakeClient({
    this.status = 200,
    this.body = '{}',
    this.throwOnSend,
    this.hangs = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (throwOnSend != null) throw throwOnSend!;
    if (hangs) return Completer<http.StreamedResponse>().future;
    sentHeaders = request.headers;
    sentUrl = request.url;
    sentBody =
        jsonDecode((request as http.Request).body) as Map<String, dynamic>;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

/// A well-formed chat-completions reply carrying one forced tool call.
/// `arguments` is a JSON *string*, which is the documented shape and the main
/// way this wire format differs from Anthropic's on the way back.
String toolReply(
  List<Map<String, dynamic>> items, {
  String name = mealItemsToolName,
  String? servedBy,
}) => jsonEncode({
  'id': 'gen_1',
  // Present only when the router reported one. It is absent on cache hits
  // and on failures that never reached the router, so the client has to cope
  // with a reply that carries no routing information at all.
  if (servedBy != null)
    'openrouter_metadata': {
      'requested': 'anthropic/claude-haiku-4.5',
      'strategy': 'direct',
      'attempt': 1,
      'endpoints': {
        'total': 1,
        'available': [
          {
            'provider': servedBy,
            'model': 'anthropic/claude-haiku-4.5',
            'selected': true,
          },
        ],
      },
    },
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
              'name': name,
              'arguments': jsonEncode({'items': items}),
            },
          },
        ],
      },
    },
  ],
});

OpenRouterMealItemsApi apiWith(
  FakeClient client, {
  String model = 'anthropic/claude-haiku-4.5',
  List<String>? providers,
  Duration timeout = OpenRouterMealItemsApi.defaultTimeout,
}) => OpenRouterMealItemsApi(
  client,
  () => 'test-key',
  model: model,
  providers: providers,
  timeout: timeout,
);

Future<MealTextParseResult> request(
  OpenRouterMealItemsApi api, {
  MealContent content = const MealTextContent('toast'),
}) => api.requestItems(content: content, system: 'system prompt');

/// Everything the client logged while [body] ran.
///
/// The pin check reports by logging rather than by throwing or returning, so
/// the log is the only place its behaviour is observable — and a test that
/// cannot see it would pass just as happily if the check were deleted.
Future<List<String>> logsDuring(Future<void> Function() body) async {
  final logged = <String>[];
  final previousLevel = Logger.root.level;
  Logger.root.level = Level.ALL;
  final subscription = Logger.root.onRecord.listen(
    (record) => logged.add(record.message),
  );
  try {
    await body();
  } finally {
    await subscription.cancel();
    Logger.root.level = previousLevel;
  }
  return logged;
}

void main() {
  group('the request', () {
    test('forces the tool by name, in the function-wrapped shape', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect(client.sentBody!['tool_choice'], {
        'type': 'function',
        'function': {'name': 'log_meal_items'},
      });
    });

    test('declares the tool under function, not flat', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final tool = (client.sentBody!['tools'] as List).single as Map;
      expect(tool['type'], 'function');
      expect((tool['function'] as Map)['name'], 'log_meal_items');
      // Anthropic's key. Sending it here would be silently ignored.
      expect(tool.containsKey('input_schema'), isFalse);
    });

    test('sends the key as a bearer header and never in the body', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect(client.sentHeaders!['authorization'], 'Bearer test-key');
      expect(jsonEncode(client.sentBody), isNot(contains('test-key')));
    });

    test('does not opt the user into app attribution', () async {
      // HTTP-Referer and X-Title put the app on OpenRouter's public
      // leaderboard. Saving a key is not consent to being listed.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect(
        client.sentHeaders!.keys.map((k) => k.toLowerCase()),
        isNot(anyElement(anyOf('http-referer', 'x-title'))),
      );
    });

    test('carries the system prompt as the first message', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      // There is no top-level `system` field in this wire format; sending one
      // would drop the prompt on the floor.
      expect(client.sentBody!.containsKey('system'), isFalse);
      final messages = client.sentBody!['messages'] as List;
      expect((messages.first as Map)['role'], 'system');
      expect((messages.first as Map)['content'], 'system prompt');
    });

    test('goes to OpenRouter and nowhere else', () async {
      // The README enumerates every destination this app talks to. A client
      // that quietly reached a fifth one would falsify that promise.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect(client.sentUrl!.host, 'openrouter.ai');
      expect(client.sentUrl!.scheme, 'https');
    });

    test('sends the model it was given rather than a default', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client, model: 'google/gemini-3.7-flash'));

      expect(client.sentBody!['model'], 'google/gemini-3.7-flash');
    });

    test('requires providers to support the parameters it sends', () async {
      // Without this, OpenRouter documents that a provider which does not
      // support `tool_choice` still receives the request and ignores it. The
      // reply would then be prose, and this client would report it as a
      // malformed response rather than as an unfit model.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect((client.sentBody!['provider'] as Map)['require_parameters'], true);
    });

    test('refuses providers that may keep and train on the input', () async {
      // Routing default is `allow`: providers that store input
      // non-transiently and may train on it are eligible unless the request
      // says otherwise. Nothing else in this request says otherwise — the
      // pin below narrows *who*, not *what they may do with it*.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client, providers: const ['anthropic']));

      expect((client.sentBody!['provider'] as Map)['data_collection'], 'deny');
    });

    test('asks the reply to name the provider that served it', () async {
      // Without this header the 200 carries no `openrouter_metadata`, and
      // the app cannot say which company received the payload. It is a
      // per-request opt-in, so it has to ride on every request or the answer
      // is unavailable exactly when it is wanted.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      expect(
        client.sentHeaders!.map((k, v) => MapEntry(k.toLowerCase(), v)),
        containsPair('x-openrouter-metadata', 'enabled'),
      );
    });
  });

  group('provider pinning', () {
    test('pins to the named providers with fallbacks off', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client, providers: const ['anthropic']));

      final provider = client.sentBody!['provider'] as Map;
      expect(provider['only'], ['anthropic']);
      // Fallbacks on would make the pin a preference. A probe of
      // `anthropic/claude-haiku-4.5` with no pin was served by Amazon Bedrock
      // on all three attempts, so an unenforced pin names the wrong company.
      expect(provider['allow_fallbacks'], false);
    });

    test('leaves routing free when nothing is pinned', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final provider = client.sentBody!['provider'] as Map;
      expect(provider.containsKey('only'), isFalse);
      expect(provider.containsKey('allow_fallbacks'), isFalse);
    });

    test('says nothing when the pinned provider is the one that served',
        () async {
      // Display form against slug. The metadata says "Anthropic" where the
      // pin says "anthropic", and treating that as a mismatch would make the
      // warning fire on every successful request — which is the fastest way
      // to make a warning worthless.
      final client = FakeClient(
        body: toolReply(const [], servedBy: 'Anthropic'),
      );

      final logged = await logsDuring(
        () => request(apiWith(client, providers: const ['anthropic'])),
      );

      expect(logged, isEmpty);
    });

    test('warns when a different provider served the request', () async {
      // The settings screen names the vendor as a guarantee. This is the
      // only runtime check that the guarantee held; without it the app
      // states where a photograph went and never verifies the claim.
      final client = FakeClient(
        body: toolReply(const [], servedBy: 'Amazon Bedrock'),
      );

      final logged = await logsDuring(
        () => request(apiWith(client, providers: const ['anthropic'])),
      );

      expect(logged.single, contains('Amazon Bedrock'));
    });

    test('a broken pin still returns the answer', () async {
      // Logged, never thrown. The reply is a valid answer to what the user
      // asked, and losing their meal entry to a routing discrepancy is a
      // worse outcome than the discrepancy.
      final client = FakeClient(
        body: toolReply(
          const [
            {'query': 'toast'},
          ],
          servedBy: 'Amazon Bedrock',
        ),
      );

      final result = await request(
        apiWith(client, providers: const ['anthropic']),
      );

      expect(result.items.single.query, 'toast');
    });

    test('stays quiet when the reply carries no routing metadata', () async {
      // Cache replays strip the field by design, and failures that never
      // reached the router never had it. Absence is not evidence the pin
      // broke, and warning on it would train the reader to ignore the line.
      final client = FakeClient(body: toolReply(const []));

      final logged = await logsDuring(
        () => request(apiWith(client, providers: const ['anthropic'])),
      );

      expect(logged, isEmpty);
    });

    test('checks nothing when nothing was pinned', () async {
      // No pin is no claim, so there is nothing to be wrong about.
      final client = FakeClient(
        body: toolReply(const [], servedBy: 'Amazon Bedrock'),
      );

      final logged = await logsDuring(() => request(apiWith(client)));

      expect(logged, isEmpty);
    });
  });

  group('content', () {
    test('text goes as a bare string', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final messages = client.sentBody!['messages'] as List;
      expect((messages[1] as Map)['content'], 'toast');
    });

    test('a photo goes text first, then a data-URI image', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(
        apiWith(client),
        content: const MealPhotoContent(
          mediaType: 'image/webp',
          base64Data: 'AQIDBA==',
        ),
      );

      final messages = client.sentBody!['messages'] as List;
      final parts = (messages[1] as Map)['content'] as List;

      // Order is load-bearing and is the opposite of Anthropic's: OpenRouter's
      // image documentation recommends the text prompt first.
      expect((parts[0] as Map)['type'], 'text');
      expect((parts[1] as Map)['type'], 'image_url');
      expect(
        ((parts[1] as Map)['image_url'] as Map)['url'],
        'data:image/webp;base64,AQIDBA==',
      );
    });
  });

  group('the schema cannot carry nutrition', () {
    // The same guarantee the Anthropic client is held to, asserted against
    // the bytes this client actually sends. A shared constant is only a
    // guarantee if every wire format really carries it.
    test('exposes only query, quantity and unit', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final tool = (client.sentBody!['tools'] as List).single as Map;
      final parameters = (tool['function'] as Map)['parameters'] as Map;
      final itemProps =
          (((parameters['properties'] as Map)['items'] as Map)['items']) as Map;

      expect((itemProps['properties'] as Map).keys.toSet(), {
        'query',
        'quantity',
        'unit',
      });
      expect(itemProps['additionalProperties'], isFalse);
    });

    test('does not ask for strict mode, which the schema cannot satisfy', () async {
      // OpenAI's strict mode requires every property to appear in
      // `required`, and rejects the whole request otherwise — measured, a
      // 400 on every openai/* call including text-only ones. `quantity` and
      // `unit` are optional on purpose, because a required amount is an
      // invented amount, so the schema cannot bend and this flag must not
      // be sent. The guarantee lives in the absent macro fields and in
      // validateParsedMealItems, never here.
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final tool = (client.sentBody!['tools'] as List).single as Map;
      expect((tool['function'] as Map).containsKey('strict'), isFalse);
    });

    test('sends the shared schema, not a copy of it', () async {
      final client = FakeClient(body: toolReply(const []));
      await request(apiWith(client));

      final tool = (client.sentBody!['tools'] as List).single as Map;
      expect(
        (tool['function'] as Map)['parameters'],
        jsonDecode(jsonEncode(mealItemsToolSchema)),
      );
    });

    test('a macro smuggled into the reply is discarded, not stored', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'toast', 'quantity': 100, 'unit': 'g', 'kcal': 265},
        ]),
      );

      final result = await request(apiWith(client));

      final item = result.items.single;
      expect(item.query, 'toast');
      expect(item.toString(), isNot(contains('265')));
    });
  });

  group('the reply', () {
    test('decodes arguments delivered as a JSON string', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'toast', 'quantity': 100, 'unit': 'g'},
          {'query': 'eggs', 'quantity': 2},
        ]),
      );

      final result = await request(apiWith(client));

      expect(result.items, hasLength(2));
      expect(result.items[0].unit, 'g');
      expect(result.items[1].quantity, 2);
      expect(result.items[1].unit, isNull);
      expect(result.errors, isEmpty);
    });

    test('accepts arguments delivered as an object', () async {
      // Not the documented shape, but some providers send it and the schema
      // is enforced either way. Failing here would reject a reply that is
      // otherwise exactly right.
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'finish_reason': 'tool_calls',
              'message': {
                'tool_calls': [
                  {
                    'function': {
                      'name': mealItemsToolName,
                      'arguments': {
                        'items': [
                          {'query': 'toast'},
                        ],
                      },
                    },
                  },
                ],
              },
            },
          ],
        }),
      );

      final result = await request(apiWith(client));

      expect(result.items.single.query, 'toast');
    });

    test('runs items through the same bounds the parser enforces', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'milk', 'quantity': 1.5, 'unit': 'l'},
        ]),
      );

      final result = await request(apiWith(client));

      // Converted, not silently downgraded — the 1000x bug the unit enum
      // exists to prevent.
      expect(result.items.single.quantity, 1500);
      expect(result.items.single.unit, 'ml');
    });

    test('rejects arguments that are not JSON', () async {
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'message': {
                'tool_calls': [
                  {
                    'function': {
                      'name': mealItemsToolName,
                      'arguments': 'not json at all',
                    },
                  },
                ],
              },
            },
          ],
        }),
      );

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('rejects a reply with no tool call', () async {
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'finish_reason': 'stop',
              'message': {'role': 'assistant', 'content': 'Sounds tasty!'},
            },
          ],
        }),
      );

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('rejects a tool call under a different name', () async {
      final client = FakeClient(body: toolReply(const [], name: 'other_tool'));

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('rejects a reply with no choices', () async {
      final client = FakeClient(body: jsonEncode({'choices': []}));

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('rejects a body that is not JSON', () async {
      final client = FakeClient(body: '<html>gateway error</html>');

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });
  });

  group('a failure that arrives as HTTP 200', () {
    test('is a failure, not an empty batch', () async {
      // The trap this wire format sets: the generation failed, the status
      // line says 200, and a client that only checks the status reports "no
      // food found" for a provider that fell over.
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'finish_reason': 'error',
              'message': {'role': 'assistant', 'content': 'partial'},
              'error': {
                'code': 502,
                'message': 'Provider disconnected mid-stream',
                'metadata': {'error_type': 'provider_unavailable'},
              },
            },
          ],
        }),
      );

      await expectLater(
        request(apiWith(client)),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('keeps the embedded code so the advice is still right', () async {
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'finish_reason': 'error',
              'error': {
                'code': 401,
                'metadata': {'error_type': 'invalid_credentials'},
              },
            },
          ],
        }),
      );

      // A rate limit reported inside the envelope is still a rate limit, and
      // a rejected key is still a rejected key. The caller should not have to
      // know which envelope its provider used.
      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>()
              .having((e) => e.failure, 'failure', MealInterpreterFailure.auth),
        ),
      );
    });
  });

  group('status classification', () {
    test('404 is a capability refusal, not something to retry', () async {
      // OpenRouter answers "No endpoints found that support image input" and
      // "No endpoints found that can handle the requested parameters" with a
      // 404. Telling the user to check their connection is advice that can
      // never work.
      final client = FakeClient(status: 404, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>()
              .having(
                (e) => e.failure,
                'failure',
                MealInterpreterFailure.unsupported,
              ),
        ),
      );
    });

    test('401 is a rejected key', () async {
      final client = FakeClient(status: 401, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.failure,
            'failure',
            MealInterpreterFailure.auth,
          ),
        ),
      );
    });

    test('a rejected image is not offered as retryable', () async {
      final client = FakeClient(status: 400, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>()
              .having(
                (e) => e.failure,
                'failure',
                MealInterpreterFailure.rejected,
              ),
        ),
      );
    });

    test('no credit is told apart from a rate limit', () async {
      // OpenRouter answers 402 "insufficient credits" and 429 for going too
      // fast. Folding the first into the second tells a user whose balance
      // is empty to keep retrying, which never resolves.
      final client = FakeClient(status: 402, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.failure,
            'failure',
            MealInterpreterFailure.billing,
          ),
        ),
      );
    });

    test('403 is a guardrail block here, not a bad key', () async {
      // Unlike the direct client, where 403 is `permission_error`,
      // OpenRouter documents 403 as a moderation or guardrail refusal.
      // Calling it an auth failure sends someone to check a working key.
      final client = FakeClient(status: 403, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.failure,
            'failure',
            MealInterpreterFailure.rejected,
          ),
        ),
      );
    });

    test('a rate limit is worth another attempt', () async {
      final client = FakeClient(status: 429, body: '{}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.failure,
            'failure',
            MealInterpreterFailure.transient,
          ),
        ),
      );
    });

    test('never carries the response body', () async {
      // The body can echo the submitted text, and this ends up in logs. On
      // the photo path the payload is a photograph.
      final client = FakeClient(status: 400, body: '{"prompt":"secret meal"}');

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains('secret meal')),
          ),
        ),
      );
    });

    test('a stalled connection gives up rather than hanging', () async {
      final client = FakeClient(hangs: true);

      await expectLater(
        request(apiWith(client, timeout: const Duration(milliseconds: 20))),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('a socket error does not leak the request into the message', () async {
      final client = FakeClient(throwOnSend: _LeakySocketException());

      await expectLater(
        request(apiWith(client)),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains('openrouter.ai')),
          ),
        ),
      );
    });
  });

  group('the seam holds', () {
    test('the photo interpreter runs over this client unchanged', () async {
      // The counts-only rule is a property of reading photographs, not of a
      // provider. Adding a destination must not be a way around it.
      final client = FakeClient(
        body: toolReply([
          {'query': 'rice', 'quantity': 200, 'unit': 'g'},
          {'query': 'eggs', 'quantity': 2},
        ]),
      );

      final result = await ModelMealPhotoInterpreter(apiWith(client)).interpret(
        MealPhoto(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          mediaType: 'image/webp',
        ),
      );

      final rice = result.items.firstWhere((i) => i.query == 'rice');
      expect(rice.quantity, isNull, reason: 'a measured amount is dropped');
      expect(rice.unit, isNull);

      final eggs = result.items.firstWhere((i) => i.query == 'eggs');
      expect(eggs.quantity, 2, reason: 'a count survives');
    });
  });
}

/// Stands in for a socket error whose message carries the request URL, which
/// some platforms really do include.
class _LeakySocketException implements Exception {
  @override
  String toString() => 'connection failed to openrouter.ai';
}
