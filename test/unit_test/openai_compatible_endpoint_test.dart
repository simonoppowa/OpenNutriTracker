import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';
import 'package:opennutritracker/features/add_meal/data/openai_compatible_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

import 'openrouter_meal_items_api_test.dart' show FakeClient;

/// The client pointed at a server the user runs. #754.
///
/// The OpenRouter configuration is covered by its own suite and is unchanged;
/// what is new here is everything that must **not** be sent when there is no
/// broker in the path, and the forcing mode, which is the one thing the
/// runtimes genuinely disagree about (#733).
void main() {
  final endpoint = Uri.parse('http://192.168.1.5:11434/v1/chat/completions');

  String replyWith(String query) => jsonEncode({
    'choices': [
      {
        'message': {
          'tool_calls': [
            {
              'function': {
                'name': mealItemsToolName,
                'arguments': jsonEncode({
                  'items': [
                    {'query': query},
                  ],
                }),
              },
            },
          ],
        },
      },
    ],
  });

  OpenAiCompatibleMealItemsApi apiFor(
    http.Client client, {
    String Function()? apiKey,
    ToolChoiceMode toolChoice = ToolChoiceMode.anyTool,
    MealInterpreterFailure Function(int)? failureFor,
    MealInterpreterFailure? timeoutFailure,
    Duration timeout = OpenAiCompatibleMealItemsApi.defaultTimeout,
  }) => OpenAiCompatibleMealItemsApi(
    client,
    apiKey,
    model: 'gemma3:4b',
    endpoint: endpoint,
    toolChoice: toolChoice,
    failureFor:
        failureFor ?? OpenAiCompatibleMealItemsApi.openRouterFailureFor,
    timeoutFailure: timeoutFailure ?? MealInterpreterFailure.transient,
    timeout: timeout,
  );

  Future<void> send(OpenAiCompatibleMealItemsApi api) => api.requestItems(
    content: const MealTextContent('two eggs'),
    system: 'system',
  );

  test('posts to the endpoint it was given, not a compiled-in one', () async {
    final client = FakeClient(body: replyWith('eggs'));

    final result = await apiFor(client).requestItems(
      content: const MealTextContent('two eggs'),
      system: 'system',
    );

    expect(client.sentUrl, endpoint);
    expect(result.items.single.query, 'eggs');
  });

  group('what must not be sent to a machine in the user\'s house', () {
    test('no routing block', () async {
      // Nothing rejects it — #733 found all four runtimes ignore unknown
      // top-level keys — but every key in it asserts something about a broker
      // that is not in the path. `data_collection: "deny"` addressed to the
      // user's own server is a claim the app cannot mean.
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client));

      expect(client.sentBody, isNot(contains('provider')));
    });

    test('no OpenRouter metadata header', () async {
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client));

      expect(client.sentHeaders, isNot(contains('x-openrouter-metadata')));
    });

    test('no authorization header when there is no key', () async {
      // The runtimes ignore a stray bearer token, but sending a credential to
      // a machine that never asked for one is not something to do by
      // accident.
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, apiKey: null));

      expect(client.sentHeaders, isNot(contains('authorization')));
    });

    test('nor when the key is present but blank', () async {
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, apiKey: () => ''));

      expect(client.sentHeaders, isNot(contains('authorization')));
    });

    test('but it is sent when the user supplied one', () async {
      // vLLM and llama.cpp both take an optional `--api-key`.
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, apiKey: () => 'sk-local'));

      expect(client.sentHeaders?['authorization'], 'Bearer sk-local');
    });
  });

  group('the forcing mode, which is the real fork', () {
    test('anyTool asks for "required"', () async {
      // What the app means with one tool defined, and what vLLM, llama.cpp
      // (with --jinja) and LM Studio's llama.cpp engine accept.
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, toolChoice: ToolChoiceMode.anyTool));

      expect(client.sentBody?['tool_choice'], 'required');
    });

    test('namedFunction asks for the tool by name', () async {
      // Only vLLM enforces this. llama.cpp parses `tool_choice` as a string
      // and silently downgrades an object to "auto".
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, toolChoice: ToolChoiceMode.namedFunction));

      expect(
        client.sentBody?['tool_choice'],
        {
          'type': 'function',
          'function': {'name': mealItemsToolName},
        },
      );
    });

    test('unforced omits the field entirely', () async {
      // Ollama has no `tool_choice` field at all, so there is nothing to ask
      // for and sending one would be noise.
      final client = FakeClient(body: replyWith('eggs'));

      await send(apiFor(client, toolChoice: ToolChoiceMode.unforced));

      expect(client.sentBody, isNot(contains('tool_choice')));
    });

    test('an unforced model answering in prose is a handled failure', () async {
      // The usefulness cliff on Ollama. It must surface as the existing "no
      // tool call" refusal — never as a malformed response, and never as an
      // invented number.
      final client = FakeClient(
        body: jsonEncode({
          'choices': [
            {
              'message': {'content': 'You ate two eggs, about 140 kcal.'},
            },
          ],
        }),
      );

      await expectLater(
        send(apiFor(client, toolChoice: ToolChoiceMode.unforced)),
        throwsA(isA<MealInterpreterException>()),
      );
    });
  });

  test('the schema still carries no macro fields on this path', () async {
    // The provenance guarantee does not depend on the destination, and a
    // fourth destination is exactly when that is worth re-asserting.
    final client = FakeClient(body: replyWith('eggs'));

    await send(apiFor(client));

    final tool = (client.sentBody?['tools'] as List).single as Map;
    final params =
        (tool['function'] as Map)['parameters'] as Map<String, dynamic>;
    final item =
        ((params['properties'] as Map)['items'] as Map)['items'] as Map;
    expect(
      (item['properties'] as Map).keys,
      // `portion` joined the set in #864. It is a lookup key rather than a
      // measurement — the model names a portion, the gram weight comes from
      // the food's own record — so the provenance guarantee is unchanged.
      // Kept exact rather than loosened to "contains no macros", because
      // exact is what caught this addition and has to catch the next one.
      unorderedEquals(['query', 'quantity', 'unit', 'portion']),
    );
  });

  group('running out of time is not the same fact as losing the connection', () {
    // #774. Both used to arrive here as "request failed" and leave as
    // `transient`, whose advice is to check the network — measured against a
    // real Ollama, that sent the user to debug a connection that was working
    // while their model was still loading.
    Future<MealInterpreterFailure> failureFrom(
      OpenAiCompatibleMealItemsApi api,
    ) async {
      try {
        await send(api);
      } on MealInterpreterException catch (e) {
        return e.failure;
      }
      fail('expected the request to fail');
    }

    test('a stalled server is reported the way the caller asked', () async {
      final client = FakeClient(hangs: true);

      expect(
        await failureFrom(
          apiFor(
            client,
            timeout: const Duration(milliseconds: 20),
            timeoutFailure: MealInterpreterFailure.timeout,
          ),
        ),
        MealInterpreterFailure.timeout,
      );
    });

    test('and stays transient when nobody asked otherwise', () async {
      // The guard on the hosted three: 20s was deliberate there and a miss
      // really is a blip, so this must not change under them.
      final client = FakeClient(hangs: true);

      expect(
        await failureFrom(
          apiFor(client, timeout: const Duration(milliseconds: 20)),
        ),
        MealInterpreterFailure.transient,
      );
    });

    test('a dropped connection is still transient, even here', () async {
      // The mutation this exists for: classifying in the catch-all instead of
      // in the timeout arm would relabel every socket error as a timeout and
      // tell someone with no wifi to go and buy a faster computer.
      final client = FakeClient(throwOnSend: Exception('connection closed'));

      expect(
        await failureFrom(
          apiFor(client, timeoutFailure: MealInterpreterFailure.timeout),
        ),
        MealInterpreterFailure.transient,
      );
    });

    test('the reason carries no payload, whatever it is called', () async {
      // The rule the whole file is held to: a timeout on the photo path must
      // not put the photograph in a log line.
      final client = FakeClient(hangs: true);

      await expectLater(
        send(
          apiFor(
            client,
            timeout: const Duration(milliseconds: 20),
            timeoutFailure: MealInterpreterFailure.timeout,
          ),
        ),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.reason,
            'reason',
            isNot(contains('two eggs')),
          ),
        ),
      );
    });
  });

  test('a refused plaintext destination is not a network problem', () async {
    // #758. The guard raises before anything is sent, and folding that into
    // the catch-all would report it as `transient` — telling the user to
    // check a connection the app deliberately never opened. Nothing about
    // their network will fix it; the address will.
    final client = FakeClient(
      throwOnSend: const InsecureDestinationException('ollama.example.com'),
    );

    await expectLater(
      send(apiFor(client)),
      throwsA(
        isA<MealInterpreterException>().having(
          (e) => e.failure,
          'failure',
          MealInterpreterFailure.insecureDestination,
        ),
      ),
    );
  });

  test('and the refusal carries no host into a log line', () async {
    // Raised on requests that may be a photograph of somebody's dinner, and
    // the host is the address of a machine in their house.
    final client = FakeClient(
      throwOnSend: const InsecureDestinationException('ollama.example.com'),
    );

    await expectLater(
      send(apiFor(client)),
      throwsA(
        isA<MealInterpreterException>().having(
          (e) => e.toString(),
          'toString',
          isNot(contains('ollama.example.com')),
        ),
      ),
    );
  });

  test('the failure table is the caller\'s, not a static one', () async {
    // #695: the same number does not mean the same thing to every
    // destination. A local runtime's 404 is "that model is not pulled", not
    // "that model was retired".
    final client = FakeClient(status: 404, body: '{}');

    await expectLater(
      send(
        apiFor(
          client,
          failureFor: (status) => status == 404
              ? MealInterpreterFailure.rejected
              : MealInterpreterFailure.transient,
        ),
      ),
      throwsA(
        isA<MealInterpreterException>().having(
          (e) => e.failure,
          'failure',
          MealInterpreterFailure.rejected,
        ),
      ),
    );
  });
}
