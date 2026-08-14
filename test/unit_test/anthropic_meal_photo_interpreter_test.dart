import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';

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

AnthropicMealPhotoInterpreter interpreterWith(
  http.Client client, {
  Duration timeout = AnthropicMealPhotoInterpreter.defaultTimeout,
}) => AnthropicMealPhotoInterpreter(client, () => 'test-key', timeout: timeout);

final _photo = MealPhoto(
  bytes: Uint8List.fromList([1, 2, 3, 4]),
  mediaType: 'image/webp',
);

/// The user message's content blocks from a captured request.
List<dynamic> contentBlocksOf(FakeClient client) =>
    (client.sentBody!['messages'] as List).first['content'] as List;

void main() {
  group('request shape', () {
    test('sends the photo as a base64 image block', () async {
      final client = FakeClient(body: toolReply([]));
      await interpreterWith(client).interpret(_photo);

      final image = contentBlocksOf(client).first as Map;
      expect(image['type'], 'image');
      final source = image['source'] as Map;
      expect(source['type'], 'base64');
      expect(source['media_type'], 'image/webp');
      expect(source['data'], base64Encode([1, 2, 3, 4]));
    });

    test(
      'puts the image before the text, as the vision guidance asks',
      () async {
        final client = FakeClient(body: toolReply([]));
        await interpreterWith(client).interpret(_photo);

        final blocks = contentBlocksOf(client);
        expect(blocks, hasLength(2));
        expect((blocks[0] as Map)['type'], 'image');
        expect((blocks[1] as Map)['type'], 'text');
      },
    );

    test('carries the media type it was given, not a hardcoded one', () async {
      final client = FakeClient(body: toolReply([]));
      await interpreterWith(client).interpret(
        MealPhoto(bytes: Uint8List.fromList([9]), mediaType: 'image/jpeg'),
      );

      final source = (contentBlocksOf(client).first as Map)['source'] as Map;
      expect(source['media_type'], 'image/jpeg');
    });

    test('forces the tool call so the reply is always parseable', () async {
      final client = FakeClient(body: toolReply([]));
      await interpreterWith(client).interpret(_photo);

      expect(client.sentBody!['tool_choice'], {
        'type': 'tool',
        'name': 'log_meal_items',
      });
    });

    test('passes the locale hint to the model', () async {
      final client = FakeClient(body: toolReply([]));
      await interpreterWith(client).interpret(_photo, localeCode: 'de');

      expect(client.sentBody!['system'], contains('"de"'));
    });

    test('sends the key as a header, never in the body', () async {
      final client = FakeClient(body: toolReply([]));
      await interpreterWith(client).interpret(_photo);

      expect(client.sentHeaders!['x-api-key'], 'test-key');
      expect(jsonEncode(client.sentBody), isNot(contains('test-key')));
    });
  });

  group('the schema cannot carry nutrition', () {
    test('no macro or energy field exists anywhere in it', () {
      final schema = jsonEncode(AnthropicMealItemsApi.toolSchema);

      for (final banned in [
        'kcal',
        'calorie',
        'energy',
        'protein',
        'carbohydrate',
        'fat',
        'sugar',
        'fiber',
        'nutriment',
      ]) {
        expect(
          schema.toLowerCase(),
          isNot(contains(banned)),
          reason:
              'The provenance guarantee is that the model has nowhere to put '
              'a nutrition value. Adding "$banned" to the schema removes it.',
        );
      }
    });

    test(
      'the photo path shares that one schema, it does not copy it',
      () async {
        final client = FakeClient(body: toolReply([]));
        await interpreterWith(client).interpret(_photo);

        final tool = (client.sentBody!['tools'] as List).single as Map;
        expect(tool['input_schema'], AnthropicMealItemsApi.toolSchema);
      },
    );
  });

  group('a photo may count, never measure', () {
    test('a bare count survives', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'egg', 'quantity': 2},
        ]),
      );

      final result = await interpreterWith(client).interpret(_photo);

      expect(result.items.single.query, 'egg');
      expect(result.items.single.quantity, 2);
      expect(result.items.single.unit, isNull);
    });

    test('a measured amount loses both its unit and its number', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'rice', 'quantity': 200, 'unit': 'g'},
        ]),
      );

      final result = await interpreterWith(client).interpret(_photo);

      // Not 200-with-no-unit: downstream that reads as a *count*, and the
      // bulk-add bloc turns a bare count into servings. Estimating 200 g of
      // rice and logging 200 servings is the worse of the two failures.
      expect(result.items.single.query, 'rice');
      expect(result.items.single.quantity, isNull);
      expect(result.items.single.unit, isNull);
    });

    test('a measured volume is dropped the same way', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'orange juice', 'quantity': 250, 'unit': 'ml'},
        ]),
      );

      final result = await interpreterWith(client).interpret(_photo);

      expect(result.items.single.quantity, isNull);
      expect(result.items.single.unit, isNull);
    });

    test(
      'one measured item does not discard the counted ones beside it',
      () async {
        final client = FakeClient(
          body: toolReply([
            {'query': 'egg', 'quantity': 2},
            {'query': 'rice', 'quantity': 150, 'unit': 'g'},
            {'query': 'toast', 'quantity': 1},
          ]),
        );

        final result = await interpreterWith(client).interpret(_photo);

        expect(result.items.map((i) => i.query), ['egg', 'rice', 'toast']);
        expect(result.items.map((i) => i.quantity), [2, null, 1]);
      },
    );

    test('a serving is a measurement here, not a count', () async {
      // `serving` scales against the food record, so it is exactly the kind
      // of amount a photo cannot establish.
      final client = FakeClient(
        body: toolReply([
          {'query': 'lasagne', 'quantity': 1, 'unit': 'serving'},
        ]),
      );

      final result = await interpreterWith(client).interpret(_photo);

      expect(result.items.single.quantity, isNull);
    });

    test('an item with no amount at all comes back untouched', () async {
      final client = FakeClient(
        body: toolReply([
          {'query': 'salad'},
        ]),
      );

      final result = await interpreterWith(client).interpret(_photo);

      expect(result.items.single.query, 'salad');
      expect(result.items.single.quantity, isNull);
    });
  });

  group('answers and failures', () {
    test('an empty list is an answer, not a failure', () async {
      final client = FakeClient(body: toolReply([]));

      final result = await interpreterWith(client).interpret(_photo);

      expect(result.items, isEmpty);
      expect(result.errors, isEmpty);
    });

    test(
      'a rejected key raises with its status so the caller can say so',
      () async {
        final client = FakeClient(status: 401, body: '{}');

        await expectLater(
          interpreterWith(client).interpret(_photo),
          throwsA(
            isA<MealInterpreterException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.isAuthFailure, 'isAuthFailure', isTrue)
                .having((e) => e.isTransient, 'isTransient', isFalse),
          ),
        );
      },
    );

    test('a rate limit is transient, not an auth failure', () async {
      final client = FakeClient(status: 429, body: '{}');

      await expectLater(
        interpreterWith(client).interpret(_photo),
        throwsA(
          isA<MealInterpreterException>()
              .having((e) => e.isAuthFailure, 'isAuthFailure', isFalse)
              .having((e) => e.isTransient, 'isTransient', isTrue),
        ),
      );
    });

    test('a malformed body raises rather than guessing', () async {
      final client = FakeClient(body: 'not json');

      await expectLater(
        interpreterWith(client).interpret(_photo),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('a reply with no tool call raises', () async {
      final client = FakeClient(
        body: jsonEncode({
          'content': [
            {'type': 'text', 'text': 'I see two eggs.'},
          ],
        }),
      );

      await expectLater(
        interpreterWith(client).interpret(_photo),
        throwsA(isA<MealInterpreterException>()),
      );
    });

    test('a socket failure carries no payload into the exception', () async {
      final client = FakeClient(throwOnSend: StateError('connection reset'));

      await expectLater(
        interpreterWith(client).interpret(_photo),
        throwsA(
          isA<MealInterpreterException>()
              .having((e) => e.reason, 'reason', 'request failed')
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('a stalled connection gives up instead of hanging', () async {
      final client = FakeClient(hangs: true);

      await expectLater(
        interpreterWith(
          client,
          timeout: const Duration(milliseconds: 20),
        ).interpret(_photo),
        throwsA(isA<MealInterpreterException>()),
      );
    });
  });
}
