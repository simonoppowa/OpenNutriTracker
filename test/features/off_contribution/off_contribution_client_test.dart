import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_client.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/domain/off_nutrition_upload.dart';

const _settings = OffContributionSettings(
  enabled: true,
  userId: 'theo',
  password: 's3cret',
);

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 480,
  carbohydrates100: 40.5,
  fat100: 30,
  proteins100: 12,
  sugars100: 25,
  saturatedFat100: 4.2,
  fiber100: 6,
  sodium100: 40,
);

void main() {
  group('OffNutritionUpload', () {
    test('sends the per-100 values with their units', () {
      final upload = OffNutritionUpload.fromNutriments('20697112', _nutriments);

      expect(upload.fields, {
        'nutrition_data_per': '100g',
        'nutriment_energy-kcal': '480',
        'nutriment_energy-kcal_unit': 'kcal',
        'nutriment_fat': '30',
        'nutriment_fat_unit': 'g',
        'nutriment_saturated-fat': '4.2',
        'nutriment_saturated-fat_unit': 'g',
        'nutriment_carbohydrates': '40.5',
        'nutriment_carbohydrates_unit': 'g',
        'nutriment_sugars': '25',
        'nutriment_sugars_unit': 'g',
        'nutriment_fiber': '6',
        'nutriment_fiber_unit': 'g',
        'nutriment_proteins': '12',
        'nutriment_proteins_unit': 'g',
        'nutriment_salt': '0.1',
        'nutriment_salt_unit': 'g',
      });
    });

    test('a food without any value has nothing to send', () {
      final upload = OffNutritionUpload.fromNutriments(
        '20697112',
        MealNutrimentsEntity.empty(),
      );

      expect(upload.hasValues, isFalse);
    });

    test('leaves out values the food does not have', () {
      final upload = OffNutritionUpload.fromNutriments(
        '20697112',
        const MealNutrimentsEntity(
          energyKcal100: 42,
          carbohydrates100: 10,
          fat100: 0,
          proteins100: 0.5,
          sugars100: null,
          saturatedFat100: null,
          fiber100: null,
        ),
      );

      expect(upload.fields.keys, isNot(contains('nutriment_sugars')));
      expect(upload.fields.keys, isNot(contains('nutriment_salt')));
      expect(upload.fields['nutriment_fat'], '0');
    });
  });

  group('OffContributionClient', () {
    late List<http.Request> requests;

    OffContributionClient clientAnswering(
      http.Response Function(http.Request request) answer,
    ) {
      requests = [];
      return OffContributionClient(
        userAgent: 'NutriTracker/1.0 (test)',
        client: MockClient((request) async {
          requests.add(request);
          return answer(request);
        }),
      );
    }

    test('posts the form to the test server with its basic auth', () async {
      final client = clientAnswering(
        (_) => http.Response(jsonEncode({'status': 1}), 200),
      );

      await client.upload(
        _settings,
        OffNutritionUpload.fromNutriments('20697112', _nutriments),
      );

      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://world.openfoodfacts.net/cgi/product_jqm2.pl',
      );
      expect(request.headers['User-Agent'], 'NutriTracker/1.0 (test)');
      expect(
        request.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('off:off'))}',
      );
      expect(request.bodyFields['code'], '20697112');
      expect(request.bodyFields['user_id'], 'theo');
      expect(request.bodyFields['password'], 's3cret');
      expect(request.bodyFields['nutriment_energy-kcal'], '480');
    });

    test('posts to the production server without basic auth', () async {
      final client = clientAnswering(
        (_) => http.Response(jsonEncode({'status': 1}), 200),
      );

      await client.upload(
        _settings.copyWith(useTestServer: false),
        OffNutritionUpload.fromNutriments('20697112', _nutriments),
      );

      expect(
        requests.single.url.toString(),
        'https://world.openfoodfacts.org/cgi/product_jqm2.pl',
      );
      expect(requests.single.headers['Authorization'], isNull);
    });

    test('a refused login is reported as such', () async {
      final client = clientAnswering(
        (_) => http.Response(
          jsonEncode({'status': 0, 'status_verbose': 'Incorrect user name'}),
          200,
        ),
      );

      await expectLater(
        client.upload(
          _settings,
          OffNutritionUpload.fromNutriments('20697112', _nutriments),
        ),
        throwsA(
          isA<OffContributionException>().having(
            (e) => e.failure,
            'failure',
            OffContributionFailure.rejected,
          ),
        ),
      );
    });

    test('a busy server is reported as such', () async {
      final client = clientAnswering((_) => http.Response('', 503));

      await expectLater(
        client.upload(
          _settings,
          OffNutritionUpload.fromNutriments('20697112', _nutriments),
        ),
        throwsA(
          isA<OffContributionException>().having(
            (e) => e.failure,
            'failure',
            OffContributionFailure.serverBusy,
          ),
        ),
      );
    });

    test('no connection is reported as offline', () async {
      requests = [];
      final client = OffContributionClient(
        userAgent: 'NutriTracker/1.0 (test)',
        client: MockClient(
          (_) async => throw http.ClientException('no route to host'),
        ),
      );

      await expectLater(
        client.upload(
          _settings,
          OffNutritionUpload.fromNutriments('20697112', _nutriments),
        ),
        throwsA(
          isA<OffContributionException>().having(
            (e) => e.failure,
            'failure',
            OffContributionFailure.offline,
          ),
        ),
      );
    });

    test('a TLS or socket failure is reported as offline', () async {
      final client = OffContributionClient(
        userAgent: 'NutriTracker/1.0 (test)',
        client: MockClient(
          (_) async => throw const HandshakeException('bad certificate'),
        ),
      );

      await expectLater(
        client.hasNutritionValues(_settings, '20697112'),
        throwsA(
          isA<OffContributionException>().having(
            (e) => e.failure,
            'failure',
            OffContributionFailure.offline,
          ),
        ),
      );
    });

    test('a product with energy already has nutrition values', () async {
      final client = clientAnswering(
        (_) => http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'nutriments': {'energy-kcal_100g': 540},
            },
          }),
          200,
        ),
      );

      expect(await client.hasNutritionValues(_settings, '20697112'), isTrue);
      expect(
        requests.single.url.toString(),
        'https://world.openfoodfacts.net/api/v2/product/20697112'
        '?fields=nutriments',
      );
    });

    test('a product with only sugars already has values too', () async {
      final client = clientAnswering(
        (_) => http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'nutriments': {'sugars_100g': 12},
            },
          }),
          200,
        ),
      );

      expect(await client.hasNutritionValues(_settings, '20697112'), isTrue);
    });

    test('a product without nutriments, or an unknown one, has none', () async {
      var client = clientAnswering(
        (_) => http.Response(
          jsonEncode({
            'status': 1,
            'product': {'nutriments': <String, Object>{}},
          }),
          200,
        ),
      );
      expect(await client.hasNutritionValues(_settings, '20697112'), isFalse);

      client = clientAnswering(
        (_) => http.Response(jsonEncode({'status': 0}), 404),
      );
      expect(await client.hasNutritionValues(_settings, '20697112'), isFalse);
    });
  });

  group('OffContributionSettings', () {
    test('is ready only when switched on with credentials', () {
      expect(_settings.isReady, isTrue);
      expect(_settings.copyWith(enabled: false).isReady, isFalse);
      expect(_settings.copyWith(password: '').isReady, isFalse);
      expect(const OffContributionSettings().useTestServer, isTrue);
    });

    test('round-trips through JSON', () {
      final back = OffContributionSettings.fromJson(
        _settings.copyWith(useTestServer: false).toJson(),
      );
      expect(back.userId, 'theo');
      expect(back.password, 's3cret');
      expect(back.useTestServer, isFalse);
      expect(back.enabled, isTrue);
    });
  });
}
