import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/edit_meal/domain/usecase/read_nutrition_label_usecase.dart';

/// A keystore in memory, with the agreement given unless a test says not.
class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;

  _MapStorage(Map<String, String> values)
    : values = {'AiTermsAcceptedTag': 'true', ...values};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

NutritionLabelReading _read(List<String> queries) =>
    NutritionLabelReading.fromItems([
      for (final query in queries) ParsedMealItem(query: query),
    ]);

/// An Anthropic reply calling the tool with [queries] as its items.
String _toolReply(List<String> queries) => jsonEncode({
  'id': 'msg_1',
  'type': 'message',
  'role': 'assistant',
  'content': [
    {
      'type': 'tool_use',
      'id': 'tu_1',
      'name': 'log_meal_items',
      'input': {
        'items': [
          for (final query in queries) {'query': query},
        ],
      },
    },
  ],
});

final _photo = MealPhoto(
  bytes: Uint8List.fromList([1, 2, 3, 4]),
  mediaType: 'image/webp',
);

void main() {
  group('NutritionLabelReading', () {
    test('reads identity and per-100 values, zeros included', () {
      final reading = _read([
        'name=Rye crispbread',
        'brand = Finn Crisp',
        'barcode=6410500090014',
        'serving=10',
        'energyKcal=350',
        'fat=2,5',
        'sodium=480',
        'vitaminD=0',
      ]);

      expect(reading.name, 'Rye crispbread');
      expect(reading.brand, 'Finn Crisp');
      expect(reading.barcode, '6410500090014');
      expect(reading.servingGrams, 10);
      expect(reading.per100, {
        'energyKcal': 350,
        'fat': 2.5,
        'sodium': 480,
        'vitaminD': 0,
      });
    });

    test('a serving alone is something read', () {
      final reading = _read(['serving=30']);

      expect(reading.servingGrams, 30);
      expect(reading.isEmpty, isFalse);
    });

    test('drops what no label prints', () {
      final reading = _read([
        'fat=120',
        'energyKcal=1500',
        'caffeine=40',
        'protein=n/a',
        'barcode=12ab',
        'serving=0',
        'carbs',
        'name=',
      ]);

      expect(reading.isEmpty, isTrue);
      expect(reading.servingGrams, isNull);
    });

    test('the prompt names every key the form takes', () {
      for (final key in nutritionLabelUnits.keys) {
        expect(nutritionLabelPrompt, contains('- $key:'));
      }
    });
  });

  group('ReadNutritionLabelUseCase', () {
    late List<http.Request> sent;

    ReadNutritionLabelUseCase useCase(
      Map<String, String> stored, {
      List<String> reply = const [],
    }) => ReadNutritionLabelUseCase(
      AiCredentialStorage(_MapStorage(stored)),
      MockClient((request) async {
        sent.add(request);
        return http.Response(_toolReply(reply), 200);
      }),
    );

    setUp(() => sent = []);

    const anthropic = {
      'AiProviderTag': 'anthropic',
      'AiApiKeyTag.anthropic': 'sk-ant',
    };

    test(
      'reads the label with the chosen model and the label prompt',
      () async {
        final reading = await useCase(
          anthropic,
          reply: ['name=Rye crispbread', 'energyKcal=350'],
        ).read(_photo);

        expect(reading!.name, 'Rye crispbread');
        expect(reading.per100, {'energyKcal': 350});
        final body = jsonDecode(sent.single.body) as Map<String, dynamic>;
        expect(body['system'], nutritionLabelPrompt);
        expect(sent.single.url.host, 'api.anthropic.com');
      },
    );

    test('names where the photo goes', () async {
      final destination = await useCase(anthropic).photoDestination();

      expect(destination?.provider, AiProvider.anthropic);
      expect(destination?.name, 'Anthropic');
    });

    for (final (why, stored) in [
      ('nothing set up', const <String, String>{}),
      ('paused', {...anthropic, 'AiAssistEnabledTag': 'false'}),
      ('hidden', {...anthropic, 'AiAssistHiddenTag': 'true'}),
      ('not agreed to', {...anthropic, 'AiTermsAcceptedTag': 'false'}),
      (
        'a server whose setup check read no photo',
        {
          'AiProviderTag': 'ownServer',
          'AiEndpointTag.ownServer': 'http://192.168.1.5:11434',
          'AiModelTag.ownServer': 'gemma3:4b',
          'AiProbeTag.ownServer': 'pf',
        },
      ),
    ]) {
      test('$why: offered nowhere, and nothing is sent', () async {
        final labels = useCase(stored, reply: ['name=Rye crispbread']);

        expect(await labels.photoDestination(), isNull);
        expect(await labels.read(_photo), isNull);
        expect(sent, isEmpty);
      });
    }

    test(
      'a server whose setup check read a photo is named by its address',
      () async {
        final destination = await useCase(const {
          'AiProviderTag': 'ownServer',
          'AiEndpointTag.ownServer': 'http://192.168.1.5:11434',
          'AiModelTag.ownServer': 'gemma3:4b',
          'AiProbeTag.ownServer': 'pp',
        }).photoDestination();

        expect(destination?.provider, AiProvider.ownServer);
        expect(destination?.name, '192.168.1.5:11434');
      },
    );
  });
}
