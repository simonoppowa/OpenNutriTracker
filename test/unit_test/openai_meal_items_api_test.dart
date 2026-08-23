import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/data/openai_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

/// What the client sent, so a rule about the request can actually fail.
class _Captured {
  late Map<String, dynamic> body;
  late Map<String, String> headers;
}

({OpenAiMealItemsApi api, _Captured sent}) subject({
  int status = 200,
  String? responseBody,
  String model = 'gpt-5.6-luna',
}) {
  final sent = _Captured();
  final client = MockClient((request) async {
    sent.body = jsonDecode(request.body) as Map<String, dynamic>;
    sent.headers = request.headers;
    return http.Response(
      responseBody ?? _toolReply([]),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return (
    api: OpenAiMealItemsApi(client, () => 'test-key', model: model),
    sent: sent,
  );
}

String _toolReply(List<Map<String, Object?>> items) => jsonEncode({
  'id': 'resp_1',
  'status': 'completed',
  'output': [
    {'type': 'reasoning', 'id': 'rs_1', 'summary': []},
    {
      'type': 'function_call',
      'name': mealItemsToolName,
      'arguments': jsonEncode({'items': items}),
    },
  ],
});

/// The failure a call classifies as, for a given status and error body.
///
/// `type` as well as `code`, because OpenAI does not always put the state the
/// app must act on in the same field: the code names the specific cause and
/// the broader type is what stays `insufficient_quota`.
Future<MealInterpreterException> _failureFrom(
  int status, {
  String? code,
  String? type,
}) async {
  final client = MockClient(
    (_) async => http.Response(
      jsonEncode({
        'error': {
          'message': 'something went wrong',
          'code': ?code,
          'type': ?type,
        },
      }),
      status,
    ),
  );
  final api = OpenAiMealItemsApi(client, () => 'k', model: 'gpt-5.6-luna');
  try {
    await api.requestItems(
      content: const MealTextContent('an egg'),
      system: 'rules',
    );
  } on MealInterpreterException catch (e) {
    return e;
  }
  fail('expected a MealInterpreterException for status $status');
}

void main() {
  group('the request Responses actually wants', () {
    test('the system prompt goes in instructions, not as a message', () async {
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'the rules',
      );

      expect(s.sent.body['instructions'], 'the rules');
      final input = s.sent.body['input'] as List;
      expect(
        input.map((m) => (m as Map)['role']),
        everyElement(isNot('system')),
        reason: 'Responses has no system role; one sent here reads as user '
            'text and the rules stop being rules',
      );
    });

    test('strict is sent, and sent false', () async {
      // Omitting it does not leave the schema alone — Responses normalises an
      // absent `strict` into strict mode, which refuses a schema whose
      // `properties` carry keys missing from `required`. That is exactly this
      // schema, so an absent field 400s every call.
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      final tool = (s.sent.body['tools'] as List).single as Map;
      expect(tool.containsKey('strict'), isTrue, reason: 'must be explicit');
      expect(tool['strict'], isFalse);
    });

    test('the tool is flat, not nested in a function object', () async {
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      final tool = (s.sent.body['tools'] as List).single as Map;
      expect(tool['name'], mealItemsToolName);
      expect(tool['parameters'], mealItemsToolSchema);
      expect(
        tool.containsKey('function'),
        isFalse,
        reason: 'that is the Chat Completions shape and is rejected here',
      );
    });

    test('the tool call is forced by name', () async {
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      expect(s.sent.body['tool_choice'], {
        'type': 'function',
        'name': mealItemsToolName,
      });
    });

    test('store is false on every request', () async {
      // Responses stores by default, so this is not a no-op.
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      expect(s.sent.body['store'], isFalse);
    });

    test('a photo goes image first, then the prompt', () async {
      final s = subject();

      await s.api.requestItems(
        content: const MealPhotoContent(
          mediaType: 'image/webp',
          base64Data: 'AAAA',
        ),
        system: 'rules',
      );

      final content =
          ((s.sent.body['input'] as List).single as Map)['content'] as List;
      expect((content.first as Map)['type'], 'input_image');
      expect(
        (content.first as Map)['image_url'],
        'data:image/webp;base64,AAAA',
      );
      expect((content.last as Map)['type'], 'input_text');
      expect((content.last as Map)['text'], mealPhotoContentPrompt);
    });

    test('the key is a bearer header and nothing else', () async {
      final s = subject();

      await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      expect(s.sent.headers['authorization'], 'Bearer test-key');
      expect(
        jsonEncode(s.sent.body),
        isNot(contains('test-key')),
        reason: 'a credential in the body would be logged by any proxy',
      );
    });
  });

  group('reading the reply', () {
    test('finds the tool call past a reasoning entry', () async {
      // `output` is a list carrying reasoning and prose as well, so the call
      // has to be searched for rather than indexed.
      final s = subject(
        responseBody: _toolReply([
          {'query': 'egg', 'quantity': 2},
        ]),
      );

      final result = await s.api.requestItems(
        content: const MealTextContent('2 eggs'),
        system: 'rules',
      );

      expect(result.items.single.query, 'egg');
      expect(result.items.single.quantity, 2);
    });

    test('arguments are a JSON string, not an object', () async {
      final s = subject(
        responseBody: jsonEncode({
          'output': [
            {
              'type': 'function_call',
              'name': mealItemsToolName,
              // An object here, which is Anthropic's shape, not this one.
              'arguments': {'items': []},
            },
          ],
        }),
      );

      expect(
        () => s.api.requestItems(
          content: const MealTextContent('2 eggs'),
          system: 'rules',
        ),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('a call by another name is not read as meal items', () async {
      // Only one tool is offered and tool_choice names it, so this should be
      // impossible — but "impossible" here means parsing whatever arrived as
      // though it were food. Both other clients check the name; so does this.
      final s = subject(
        responseBody: jsonEncode({
          'output': [
            {
              'type': 'function_call',
              'name': 'some_other_tool',
              'arguments': jsonEncode({
                'items': [
                  {'query': 'not food', 'quantity': 99},
                ],
              }),
            },
          ],
        }),
      );

      expect(
        () => s.api.requestItems(
          content: const MealTextContent('2 eggs'),
          system: 'rules',
        ),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('an empty item list is a reading, not a failure', () async {
      final s = subject(responseBody: _toolReply([]));

      final result = await s.api.requestItems(
        content: const MealTextContent('hello'),
        system: 'rules',
      );

      expect(result.items, isEmpty);
    });
  });

  group('classifying failures', () {
    test('401 is an auth failure', () async {
      expect(
        (await _failureFrom(401)).failure,
        MealInterpreterFailure.auth,
      );
    });

    test('403 is an auth failure', () async {
      expect(
        (await _failureFrom(403)).failure,
        MealInterpreterFailure.auth,
      );
    });

    test('a withdrawn model is unsupported, though it arrives as 400', () async {
      // The finding this client exists to handle. Both other providers answer
      // 404 for this; OpenAI answers 400 and reuses 400 for a rejected image,
      // so only the code separates them.
      final e = await _failureFrom(400, code: 'model_not_found');

      expect(e.failure, MealInterpreterFailure.unsupported);
      expect(e.statusCode, 400);
    });

    test('any other 400 is a rejected request', () async {
      expect(
        (await _failureFrom(400, code: 'integer_below_min_value')).failure,
        MealInterpreterFailure.rejected,
        reason: 'a malformed request must not tell the user to switch model',
      );
    });

    test('a 400 with no code at all is rejected, not unsupported', () async {
      expect(
        (await _failureFrom(400)).failure,
        MealInterpreterFailure.rejected,
      );
    });

    test('402 is billing', () async {
      expect(
        (await _failureFrom(402)).failure,
        MealInterpreterFailure.billing,
      );
    });

    test('404 is still unsupported', () async {
      expect(
        (await _failureFrom(404)).failure,
        MealInterpreterFailure.unsupported,
      );
    });

    test('a bare 429 is transient', () async {
      // Ordinary rate limiting: it clears on its own, and retrying is right.
      // A 429 that says why is a different matter — see below.
      expect(
        (await _failureFrom(429)).failure,
        MealInterpreterFailure.transient,
      );
    });

    test('a 429 that names an exhausted balance is billing', () async {
      // Both other providers separate this from a rate limit by status alone,
      // 402 against 429. OpenAI does not, so an empty prepaid balance used to
      // be told to try again later — forever, with the interpreter falling
      // back silently every time and nothing on screen ever naming the one
      // thing that would fix it.
      expect(
        (await _failureFrom(429, code: 'insufficient_quota')).failure,
        MealInterpreterFailure.billing,
      );
    });

    test('the broader type carries it when the code is narrower', () async {
      // OpenAI's own guidance: inspect `error.code` for the specific cause,
      // while the broader `error.type` can still be `insufficient_quota`. So
      // the account whose cause *is* spelled out is exactly the one a
      // code-only read would miss, which would be the same bug with a
      // smaller blast radius.
      expect(
        (await _failureFrom(
          429,
          code: 'billing_hard_limit_reached',
          type: 'insufficient_quota',
        )).failure,
        MealInterpreterFailure.billing,
      );
    });

    test('503 is transient', () async {
      expect(
        (await _failureFrom(503)).failure,
        MealInterpreterFailure.transient,
      );
    });

    test('the provider message never reaches the exception', () async {
      // OpenAI's 401 body echoes the key in a partially masked form that
      // still carries its real last four characters, so the message is not a
      // safe thing to keep hold of. Only the code is read.
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'message': 'Incorrect API key provided: sk-proj-****abcd.',
              'code': 'invalid_api_key',
            },
          }),
          401,
        ),
      );
      final api = OpenAiMealItemsApi(client, () => 'k', model: 'm');

      try {
        await api.requestItems(
          content: const MealTextContent('an egg'),
          system: 'rules',
        );
        fail('expected a failure');
      } on MealInterpreterException catch (e) {
        expect(e.toString(), isNot(contains('sk-proj')));
        expect(e.toString(), isNot(contains('abcd')));
        expect(e.toString(), isNot(contains('Incorrect API key')));
      }
    });

    test('an unparseable error body still classifies on status', () async {
      final client = MockClient(
        (_) async => http.Response('<html>502 Bad Gateway</html>', 502),
      );
      final api = OpenAiMealItemsApi(client, () => 'k', model: 'm');

      try {
        await api.requestItems(
          content: const MealTextContent('an egg'),
          system: 'rules',
        );
        fail('expected a failure');
      } on MealInterpreterException catch (e) {
        expect(e.failure, MealInterpreterFailure.transient);
        expect(e.toString(), isNot(contains('Bad Gateway')));
      }
    });
  });
}
