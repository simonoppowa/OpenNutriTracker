import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/data/rate_limit_retry_client.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

/// Answers each request with the next of [replies], recording what was sent.
MockClient _replying(List<http.Response> replies, List<http.Request> sent) =>
    MockClient((request) async {
      sent.add(request);
      return replies[sent.length - 1];
    });

void main() {
  late List<http.Request> sent;
  late List<Duration> slept;
  RateLimitRetryClient retrying(List<http.Response> replies) =>
      RateLimitRetryClient(
        _replying(replies, sent),
        sleep: (wait) async => slept.add(wait),
      );
  Future<http.Response> post(RateLimitRetryClient client) => client.post(
    Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    headers: {'authorization': 'Bearer sk-or'},
    body: '{"model":"m"}',
  );

  setUp(() {
    sent = [];
    slept = [];
  });

  test('an answer that is not a 429 is passed on, sent once', () async {
    final r = await post(retrying([http.Response('ok', 200)]));
    expect([r.statusCode, r.body, sent.length, slept], [200, 'ok', 1, []]);
  });

  test('a 429 is asked once more, the same request, after a moment', () async {
    final r = await post(
      retrying([http.Response('busy', 429), http.Response('ok', 200)]),
    );
    expect([r.statusCode, r.body], [200, 'ok']);
    expect(slept, [RateLimitRetryClient.defaultWait]);
    expect(sent.map((s) => (s.url, s.body, s.headers['authorization'])), [
      for (var i = 0; i < 2; i++)
        (
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          '{"model":"m"}',
          'Bearer sk-or',
        ),
    ]);
  });

  test('a second 429 is passed on: one retry only', () async {
    final r = await post(
      retrying([http.Response('busy', 429), http.Response('still', 429)]),
    );
    expect([r.statusCode, r.body, sent.length], [429, 'still', 2]);
  });

  test('a short retry-after is waited out', () async {
    await post(
      retrying([
        http.Response('busy', 429, headers: {'retry-after': '1.5'}),
        http.Response('ok', 200),
      ]),
    );
    expect(slept, [const Duration(milliseconds: 1500)]);
  });

  for (final retryAfter in ['30', 'Wed, 28 Oct 2026 21:00:00 GMT']) {
    test('a retry-after past the read\'s budget ($retryAfter) is passed on '
        'at once', () async {
      final r = await post(
        retrying([
          http.Response('busy', 429, headers: {'retry-after': retryAfter}),
        ]),
      );
      expect([r.statusCode, sent.length, slept], [429, 1, []]);
    });
  }

  group('through mealItemsApiFor', () {
    final toolReply = jsonEncode({
      'choices': [
        {
          'finish_reason': 'tool_calls',
          'message': {
            'tool_calls': [
              {
                'function': {
                  'name': 'log_meal_items',
                  'arguments': '{"items":[{"query":"toast"}]}',
                },
              },
            ],
          },
        },
      ],
    });

    test('an OpenRouter read gets past one rate limit', () async {
      final api = mealItemsApiFor(
        _replying([
          http.Response('', 429, headers: {'retry-after': '0'}),
          http.Response(toolReply, 200),
        ], sent),
        const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
      );
      final result = await api.requestItems(
        content: const MealTextContent('toast'),
        system: 'system',
      );
      expect(result.items.single.query, 'toast');
      expect(sent, hasLength(2));
    });

    for (final selection in const [
      AiSelection(provider: AiProvider.anthropic, apiKey: 'sk-ant'),
      AiSelection(provider: AiProvider.openai, apiKey: 'sk'),
      AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
      AiSelection(
        provider: AiProvider.ownServer,
        endpoint: 'https://llm.example.com/v1/chat/completions',
        modelId: 'llama3.1:8b',
      ),
    ]) {
      test('${selection.provider.name} asks once more after a 429', () async {
        final api = mealItemsApiFor(
          _replying([
            http.Response('', 429, headers: {'retry-after': '0'}),
            http.Response('', 429),
          ], sent),
          selection,
        );
        await expectLater(
          api.requestItems(
            content: const MealTextContent('toast'),
            system: 'system',
          ),
          throwsA(isA<MealInterpreterException>()),
        );
        expect(sent, hasLength(2));
      });
    }

    test('the read\'s own timeout covers the wait', () async {
      final api = mealItemsApiFor(
        _replying([
          http.Response('', 429),
          http.Response(toolReply, 200),
        ], sent),
        const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
        timeout: const Duration(milliseconds: 100),
      );
      final started = DateTime.now();
      await expectLater(
        api.requestItems(
          content: const MealTextContent('toast'),
          system: 'system',
        ),
        throwsA(isA<MealInterpreterException>()),
      );
      expect(
        DateTime.now().difference(started),
        lessThan(RateLimitRetryClient.defaultWait),
      );
    });

    test('an exhausted OpenAI balance is still a billing failure', () async {
      final quota = jsonEncode({
        'error': {'code': 'insufficient_quota', 'type': 'insufficient_quota'},
      });
      final api = mealItemsApiFor(
        _replying([
          http.Response(quota, 429, headers: {'retry-after': '0'}),
          http.Response(quota, 429),
        ], sent),
        const AiSelection(provider: AiProvider.openai, apiKey: 'sk'),
      );
      await expectLater(
        api.requestItems(
          content: const MealTextContent('toast'),
          system: 'system',
        ),
        throwsA(
          isA<MealInterpreterException>().having(
            (e) => e.failure,
            'failure',
            MealInterpreterFailure.billing,
          ),
        ),
      );
    });
  });
}
