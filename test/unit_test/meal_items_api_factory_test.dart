import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/data/meal_items_api_factory.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';

/// Records where a request actually went. Everything else in this suite
/// checks a shape; this checks a destination.
class CapturingClient extends http.BaseClient {
  Uri? url;
  Map<String, String>? headers;
  Map<String, dynamic>? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    url = request.url;
    headers = request.headers;
    body = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
    // Enough of a reply to get past parsing; the assertions are on the way
    // out, not the way back.
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'content': [
              {
                'type': 'tool_use',
                'name': 'log_meal_items',
                'input': {'items': []},
              },
            ],
            'choices': [
              {
                'finish_reason': 'tool_calls',
                'message': {
                  'tool_calls': [
                    {
                      'function': {
                        'name': 'log_meal_items',
                        'arguments': '{"items":[]}',
                      },
                    },
                  ],
                },
              },
            ],
          }),
        ),
      ),
      200,
      request: request,
    );
  }
}

Future<CapturingClient> send(AiSelection selection) async {
  final client = CapturingClient();
  await mealItemsApiFor(
    client,
    selection,
  ).requestItems(content: const MealTextContent('toast'), system: 'system');
  return client;
}

void main() {
  group('the provider the user picked is the provider that is used', () {
    test('Anthropic goes direct, with its own auth header', () async {
      final client = await send(
        const AiSelection(provider: AiProvider.anthropic, apiKey: 'sk-ant'),
      );

      expect(client.url!.host, 'api.anthropic.com');
      expect(client.headers!['x-api-key'], 'sk-ant');
      expect(client.headers!.containsKey('authorization'), isFalse);
      expect(client.body!.containsKey('provider'), isFalse);
    });

    test('OpenRouter goes to the broker, with a bearer token', () async {
      final client = await send(
        const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
      );

      expect(client.url!.host, 'openrouter.ai');
      expect(client.headers!['authorization'], 'Bearer sk-or');
      expect(client.headers!.containsKey('x-api-key'), isFalse);
    });

    test('one provider\'s key never reaches the other\'s endpoint', () async {
      // The reason AiSelection is read as a unit: a provider switch landing
      // between two reads must not be able to produce this.
      final anthropic = await send(
        const AiSelection(provider: AiProvider.anthropic, apiKey: 'sk-ant'),
      );
      final openrouter = await send(
        const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
      );

      expect(jsonEncode(anthropic.headers), isNot(contains('sk-or')));
      expect(jsonEncode(openrouter.headers), isNot(contains('sk-ant')));
    });
  });

  group('the model the settings screen named is the model that is sent', () {
    test('defaults to the curated first entry', () async {
      final client = await send(
        const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
      );

      expect(client.body!['model'], AiModelCatalogue.openrouter.first.id);
      expect(client.body!['model'], 'anthropic/claude-sonnet-5');
    });

    test('honours a stored choice', () async {
      final client = await send(
        const AiSelection(
          provider: AiProvider.openrouter,
          apiKey: 'sk-or',
          modelId: 'anthropic/claude-haiku-4.5',
        ),
      );

      expect(client.body!['model'], 'anthropic/claude-haiku-4.5');
    });

    test('falls back when the stored model has been retired', () async {
      // What a user sees after an update drops a model. Sending the dead id
      // would 404 every time; falling back to the default keeps the feature
      // working and the settings screen still shows what is really in use.
      final client = await send(
        const AiSelection(
          provider: AiProvider.openrouter,
          apiKey: 'sk-or',
          modelId: 'anthropic/claude-retired-in-2027',
        ),
      );

      expect(client.body!['model'], AiModelCatalogue.openrouter.first.id);
    });

    test('a model id is never carried across providers', () async {
      // An OpenRouter slug sent to api.anthropic.com is a 404 with a
      // confusing message. The catalogue resolves per provider, so a stale
      // cross-provider value cannot survive.
      final client = await send(
        const AiSelection(
          provider: AiProvider.anthropic,
          apiKey: 'sk-ant',
          modelId: 'anthropic/claude-sonnet-5',
        ),
      );

      expect(client.body!['model'], AnthropicMealItemsApi.defaultModel);
      expect(client.body!['model'], isNot(contains('/')));
    });
  });

  group('pinning', () {
    test('every curated OpenRouter model is pinned, fallbacks off', () async {
      // #656: the policy fit that justified Anthropic survives only under
      // provider.only. An unpinned entry on this list would silently be a
      // different company's terms.
      for (final model in AiModelCatalogue.openrouter) {
        final client = await send(
          AiSelection(
            provider: AiProvider.openrouter,
            apiKey: 'sk-or',
            modelId: model.id,
          ),
        );

        final provider = client.body!['provider'] as Map;
        expect(provider['only'], isNotEmpty, reason: model.id);
        expect(provider['allow_fallbacks'], false, reason: model.id);
        expect(provider['require_parameters'], true, reason: model.id);
      }
    });

    test('the pin matches the vendor settings names', () async {
      // The screen says "Served by Anthropic". If the pin said otherwise the
      // label would be a claim the request does not keep.
      for (final model in AiModelCatalogue.openrouter) {
        expect(
          model.providers.single.toLowerCase(),
          model.servedBy.toLowerCase(),
          reason: model.id,
        );
      }
    });

    test('the direct client carries no OpenRouter routing block', () async {
      final client = await send(
        const AiSelection(provider: AiProvider.anthropic, apiKey: 'sk-ant'),
      );

      expect(client.body!.containsKey('provider'), isFalse);
      expect(client.body!['tool_choice'], {
        'type': 'tool',
        'name': 'log_meal_items',
      });
    });
  });

  test('both clients are held to the one shared schema', () async {
    // The no-macros guarantee is only a guarantee if it survives the switch
    // that chooses between them.
    final anthropic = await send(
      const AiSelection(provider: AiProvider.anthropic, apiKey: 'sk-ant'),
    );
    final openrouter = await send(
      const AiSelection(provider: AiProvider.openrouter, apiKey: 'sk-or'),
    );

    final expected = jsonDecode(jsonEncode(mealItemsToolSchema));
    expect(
      ((anthropic.body!['tools'] as List).single as Map)['input_schema'],
      expected,
    );
    expect(
      (((openrouter.body!['tools'] as List).single as Map)['function']
          as Map)['parameters'],
      expected,
    );
  });
}
