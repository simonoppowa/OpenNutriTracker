import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
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
    sentBody =
        jsonDecode((request as http.Request).body) as Map<String, dynamic>;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

/// A well-formed Messages reply carrying one forced tool call.
String toolReply(List<Map<String, dynamic>> items) => jsonEncode({
  'id': 'msg_1',
  'type': 'message',
  'role': 'assistant',
  'content': [
    {
      'type': 'tool_use',
      'id': 'tu_1',
      'name': 'log_meal_items',
      'input': {'items': items},
    },
  ],
});

AnthropicMealTextInterpreter interpreterWith(FakeClient client) =>
    AnthropicMealTextInterpreter(client, () => 'test-key');

void main() {
  group('the request', () {
    test('forces the tool so the reply is always parseable', () async {
      final client = FakeClient(body: toolReply(const []));
      await interpreterWith(client).interpret('toast');

      expect(client.sentBody!['tool_choice'], {
        'type': 'tool',
        'name': 'log_meal_items',
      });
    });

    test('sends the key as a header and never in the body', () async {
      final client = FakeClient(body: toolReply(const []));
      await interpreterWith(client).interpret('toast');

      expect(client.sentHeaders!['x-api-key'], 'test-key');
      expect(client.sentHeaders!['anthropic-version'], isNotEmpty);
      expect(jsonEncode(client.sentBody), isNot(contains('test-key')));
    });

    test('pins the model rather than tracking a moving alias', () async {
      final client = FakeClient(body: toolReply(const []));
      await interpreterWith(client).interpret('toast');

      expect(
        client.sentBody!['model'],
        AnthropicMealTextInterpreter.defaultModel,
      );
      expect(client.sentBody!['model'], isNot(contains('latest')));
    });

    test(
      'passes the locale so names come back in the search language',
      () async {
        final client = FakeClient(body: toolReply(const []));
        await interpreterWith(client).interpret('toast', localeCode: 'de');

        expect(client.sentBody!['system'], contains('de'));
      },
    );

    test('does not call out at all for empty input', () async {
      final client = FakeClient(body: toolReply(const []));
      final result = await interpreterWith(client).interpret('   ');

      expect(client.sentBody, isNull);
      expect(result.items, isEmpty);
    });
  });

  group('the schema cannot carry nutrition', () {
    // The provenance guarantee for tier 1b is structural: the model has
    // nowhere to put a calorie. If someone adds a macro field to the tool
    // schema, this fails — which is the review question we want asked.
    test('exposes only query, quantity and unit', () async {
      final client = FakeClient(body: toolReply(const []));
      await interpreterWith(client).interpret('toast');

      final schema =
          (client.sentBody!['tools'] as List).single as Map<String, dynamic>;
      final itemProps =
          (((schema['input_schema'] as Map)['properties'] as Map)['items']
                  as Map)['items']
              as Map;

      expect(((itemProps['properties']) as Map).keys.toSet(), {
        'query',
        'quantity',
        'unit',
      });
      expect(itemProps['additionalProperties'], isFalse);
    });

    test('a macro smuggled into the reply is discarded, not stored', () async {
      // Even if a future model returns extra fields, ParsedMealItem has
      // nowhere to hold them, so they cannot reach the diary.
      final client = FakeClient(
        body: toolReply([
          {'query': 'toast', 'quantity': 100, 'unit': 'g', 'kcal': 265},
        ]),
      );

      final result = await interpreterWith(client).interpret('100g toast');

      final item = result.items.single;
      expect(item.query, 'toast');
      expect(item.quantity, 100);
      expect(item.unit, 'g');
      expect(item.toString(), isNot(contains('265')));
    });
  });

  group('the reply', () {
    test('maps items through to parsed items', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'toast', 'quantity': 100, 'unit': 'g'},
          {'query': 'eggs', 'quantity': 2},
          {'query': 'black coffee'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.items, hasLength(3));
      expect(result.items[1].quantity, 2);
      expect(result.items[1].unit, isNull);
      expect(result.items[2].quantity, isNull);
      expect(result.errors, isEmpty);
    });

    test('accepts a quantity written as a string or a decimal', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'milk', 'quantity': '1,5', 'unit': 'ml'},
          {'query': 'flour', 'quantity': 2.5, 'unit': 'g'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.items[0].quantity, 1.5);
      expect(result.items[1].quantity, 2.5);
    });

    test('drops an unusable entry without failing the batch', () async {
      final client = FakeClient(
        body: toolReply([
          {'quantity': 100},
          {'query': 'toast', 'quantity': 100, 'unit': 'g'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.items.single.query, 'toast');
    });

    test('drops a unit the app cannot convert, keeping the food', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'flour', 'quantity': 2, 'unit': 'cups'},
        ]),
      );

      final result = await interpreterWith(client).interpret('2 cups flour');

      expect(result.items.single.query, 'flour');
      expect(result.items.single.unit, isNull);
      expect(result.items.single.quantity, 2);
    });
  });

  group('model output is held to the parser bounds', () {
    test('a quantity over the maximum is rejected, not clamped', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'flour', 'quantity': 15000, 'unit': 'g'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.items, isEmpty);
      expect(result.errors, [const QuantityTooLargeError(1, 10000)]);
    });

    test('a zero or negative quantity is rejected', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'water', 'quantity': 0, 'unit': 'ml'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.errors, [const QuantityTooSmallError(1)]);
    });

    test('a query with no letters is rejected', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': '123'},
        ]),
      );

      final result = await interpreterWith(client).interpret('anything');

      expect(result.errors, [const InvalidFoodNameError(1)]);
    });
  });

  group('failures', () {
    test('a rejected key is reported as not worth retrying', () async {
      final client = FakeClient(status: 401, body: '{"error":"bad key"}');

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(
          isA<MealTextInterpreterException>().having(
            (e) => e.isTransient,
            'isTransient',
            isFalse,
          ),
        ),
      );
    });

    test('a rate limit is reported as transient', () async {
      final client = FakeClient(status: 429, body: '{}');

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(
          isA<MealTextInterpreterException>().having(
            (e) => e.isTransient,
            'isTransient',
            isTrue,
          ),
        ),
      );
    });

    test('a network error raises without echoing the request', () async {
      final client = FakeClient(throwOnSend: const SocketExceptionStub());

      await expectLater(
        interpreterWith(client).interpret('my private meal note'),
        throwsA(
          isA<MealTextInterpreterException>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains('private')),
          ),
        ),
      );
    });

    test('a reply with no tool call raises rather than guessing', () async {
      final client = FakeClient(
        body: jsonEncode({
          'content': [
            {'type': 'text', 'text': 'I think you ate toast.'},
          ],
        }),
      );

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(isA<MealTextInterpreterException>()),
      );
    });

    test('an unexpected tool-input shape raises, not a TypeError', () async {
      // Must arrive as MealTextInterpreterException, or #635 cannot fall
      // back to the deterministic parser and the caller crashes instead.
      final client = FakeClient(
        body: jsonEncode({
          'content': [
            {'type': 'tool_use', 'name': 'log_meal_items', 'input': 'oops'},
          ],
        }),
      );

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(isA<MealTextInterpreterException>()),
      );
    });

    test('a stalled connection does not hang forever', () async {
      final client = FakeClient(hangs: true);

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(isA<MealTextInterpreterException>()),
      );
    });

    test('a malformed body raises rather than guessing', () async {
      final client = FakeClient(body: 'not json');

      await expectLater(
        interpreterWith(client).interpret('toast'),
        throwsA(isA<MealTextInterpreterException>()),
      );
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'connection failed to api.anthropic.com';
}
