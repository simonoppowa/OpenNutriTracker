import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// #1326: a phone in French got an English UI, because French is not a
/// shipped UI language, and with it English food searches: "tomate" asked
/// Open Food Facts for English names only, and the reviewer had to search
/// in English. Food names now follow the first device language the food
/// sources carry, when the UI could only fall back to English.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // OFFDataSource builds its User-Agent from PackageInfo.
    PackageInfo.setMockInitialValues(
      appName: 'ont-test',
      packageName: 'test',
      version: '0.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(AppLocale.reset);

  void device(List<Locale> locales) =>
      AppLocale.preferredLocales = () => locales;

  group('SupportedLanguage', () {
    test('knows French and Russian, with or without a region', () {
      expect(SupportedLanguage.fromCode('fr'), SupportedLanguage.fr);
      expect(SupportedLanguage.fromCode('fr_CA'), SupportedLanguage.fr);
      expect(SupportedLanguage.fromCode('ru_RU'), SupportedLanguage.ru);
    });

    test('a language the food sources do not carry still reads English', () {
      expect(SupportedLanguage.fromCode('nl_NL'), SupportedLanguage.en);
      expect(SupportedLanguage.tryFromCode('nl_NL'), isNull);
      expect(SupportedLanguage.tryFromCode(''), isNull);
    });
  });

  group('AppLocale.foodLocaleName', () {
    test('a French-only phone reads an English UI and French food names', () {
      device(const [Locale('fr', 'FR')]);
      expect(AppLocale.localeName, 'en');
      expect(AppLocale.foodLocaleName, 'fr_FR');
    });

    test('French above English: French food names', () {
      device(const [Locale('fr', 'FR'), Locale('en', 'US')]);
      expect(AppLocale.localeName, 'en');
      expect(AppLocale.foodLocaleName, 'fr_FR');
    });

    test('English above French: English, as the user ranked them', () {
      device(const [Locale('en', 'GB'), Locale('fr', 'FR')]);
      expect(AppLocale.foodLocaleName, AppLocale.localeName);
      expect(
        SupportedLanguage.fromCode(AppLocale.foodLocaleName),
        SupportedLanguage.en,
      );
    });

    test('French above shipped German: German, as the UI reads it', () {
      // Unchanged from before #1326: a non-English UI keeps its food names.
      device(const [Locale('fr', 'FR'), Locale('de', 'DE')]);
      expect(AppLocale.foodLocaleName, 'de');
    });

    test('a language neither side carries is skipped, not used', () {
      device(const [Locale('nl', 'NL'), Locale('fr', 'BE')]);
      expect(AppLocale.foodLocaleName, 'fr_BE');

      device(const [Locale('nl', 'NL')]);
      expect(AppLocale.foodLocaleName, 'en');
    });

    test('a language chosen in the app always wins', () {
      device(const [Locale('fr', 'FR')]);
      AppLocale.select('en');
      expect(AppLocale.foodLocaleName, 'en');
      AppLocale.select('it');
      expect(AppLocale.foodLocaleName, 'it');
    });

    test('Russian, a shipped UI language, names food in Russian', () {
      device(const [Locale('ru', 'RU')]);
      expect(
        SupportedLanguage.fromCode(AppLocale.foodLocaleName),
        SupportedLanguage.ru,
      );
    });
  });

  group('the Open Food Facts word search', () {
    Map<String, dynamic> salBody(List<Map<String, dynamic>> hits) => {
      'hits': hits,
      'count': hits.length,
      'page': 1,
      'page_size': 100,
    };

    Future<(Uri, int)> search(
      String query, {
      List<Map<String, dynamic>> hits = const [],
    }) async {
      Uri? requested;
      final dataSource = OFFDataSource(
        clientFactory: () => MockClient((request) async {
          requested ??= request.url;
          return http.Response.bytes(
            utf8.encode(jsonEncode(salBody(hits))),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final response = await dataSource.fetchSearchWordResults(query);
      return (requested!, response.products.length);
    }

    test('from a French phone asks for French and English names', () async {
      device(const [Locale('fr', 'FR')]);
      final (url, _) = await search('tomate');
      expect(url.queryParameters['langs'], 'fr,en');
    });

    test('from a Russian phone asks for Russian and English names', () async {
      device(const [Locale('ru', 'RU')]);
      final (url, _) = await search('молоко');
      expect(url.queryParameters['langs'], 'ru,en');
      expect(url.queryParameters['q'], 'молоко');
    });

    test('sends accented queries unchanged', () async {
      for (final (locale, query) in const [
        (Locale('fr', 'FR'), 'pâtes'),
        (Locale('de', 'DE'), 'Käse'),
        (Locale('it', 'IT'), 'mela'),
      ]) {
        device([locale]);
        final (url, _) = await search(query);
        expect(url.queryParameters['q'], query);
        expect(url.queryParameters['langs'], '${locale.languageCode},en');
      }
    });

    test('an empty answer is an empty list, not an error', () async {
      device(const [Locale('fr', 'FR')]);
      final (_, count) = await search('zzznothingzzz');
      expect(count, 0);
    });

    test('with Search-a-licious down, the classic API still answers', () async {
      device(const [Locale('fr', 'FR')]);
      final requested = <Uri>[];
      final dataSource = OFFDataSource(
        clientFactory: () => MockClient((request) async {
          requested.add(request.url);
          if (request.url.host == 'search.openfoodfacts.org') {
            return http.Response('Bad Gateway', 502);
          }
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'count': 1,
                'page': 1,
                'page_count': 1,
                'page_size': 100,
                'products': [
                  {'code': '1', 'product_name_fr': 'Pâtes', 'nutriments': {}},
                ],
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final response = await dataSource.fetchSearchWordResults('pâtes');

      expect(requested, hasLength(2));
      expect(requested.last.queryParameters['search_terms'], 'pâtes');
      expect(response.products.single.product_name_fr, 'Pâtes');
      expect(MealEntity.fromOFFProduct(response.products.single).name, 'Pâtes');
    });
  });

  group('an Open Food Facts product', () {
    OFFProductDTO product({String? fr, String? ru, String? en = 'Tomatoes'}) =>
        OFFProductDTO.fromJson({
          'code': '1',
          'product_name': 'Tomates (main language)',
          'product_name_en': ?en,
          'product_name_fr': ?fr,
          'product_name_ru': ?ru,
        });

    test('is named in French on a French phone', () {
      device(const [Locale('fr', 'FR')]);
      expect(MealEntity.fromOFFProduct(product(fr: 'Tomates')).name, 'Tomates');
    });

    test('is named in Russian on a Russian phone', () {
      device(const [Locale('ru', 'RU')]);
      expect(
        MealEntity.fromOFFProduct(product(ru: 'Помидоры')).name,
        'Помидоры',
      );
    });

    test('without a French name falls back to English', () {
      device(const [Locale('fr', 'FR')]);
      expect(MealEntity.fromOFFProduct(product()).name, 'Tomatoes');
    });

    test('a blank French or Russian name falls back to English', () {
      for (final (locale, blank) in [
        (const Locale('fr', 'FR'), product(fr: ' ')),
        (const Locale('fr', 'FR'), product(fr: '\t\n')),
        (const Locale('ru', 'RU'), product(ru: ' ')),
        (const Locale('ru', 'RU'), product(ru: ' ')),
      ]) {
        device([locale]);
        expect(MealEntity.fromOFFProduct(blank).name, 'Tomatoes');
      }
    });

    test('a blank English name does not hide the main-language one', () {
      device(const [Locale('fr', 'FR')]);
      expect(
        MealEntity.fromOFFProduct(product(fr: ' ', en: '  ')).name,
        'Tomates (main language)',
      );
    });

    test('keeps French as the last fallback for other languages', () {
      // Unchanged from before #1326: product_name still beats French.
      expect(
        product(fr: 'Tomates', en: null).getLocaleName(SupportedLanguage.pl),
        'Tomates (main language)',
      );
      expect(
        product(fr: 'Tomates', en: null).getLocaleName(SupportedLanguage.de),
        'Tomates (main language)',
      );
    });
  });

  group('the food backend', () {
    late _RecordingClient backend;

    setUp(() {
      backend = _RecordingClient();
      if (locator.isRegistered<SupabaseClient>()) {
        locator.unregister<SupabaseClient>();
      }
      if (locator.isRegistered<ConfigDataSource>()) {
        locator.unregister<ConfigDataSource>();
      }
      locator.registerSingleton<SupabaseClient>(
        SupabaseClient(
          'http://backend.invalid',
          'test-key',
          httpClient: backend,
        ),
      );
    });

    tearDown(() {
      locator.unregister<SupabaseClient>();
      locator.unregister<ConfigDataSource>();
    });

    List<String> rpcs() => [
      for (final r in backend.sent) r.url.pathSegments.last,
    ];

    test('has no French or Russian names yet, so asks in English', () async {
      // food_translation carries no fr or ru rows; asking for them would
      // cost every search an empty round trip first, as for hu and es.
      expect(SPConst.translationLocaleOf(SupportedLanguage.fr), isNull);
      expect(SPConst.translationLocaleOf(SupportedLanguage.ru), isNull);

      locator.registerSingleton<ConfigDataSource>(_Toggles(null));
      device(const [Locale('fr', 'FR')]);

      final results = await SpFoodDataSource().fetchSearchWordResults('pâtes');

      expect(results, isEmpty);
      expect(rpcs(), [SPConst.searchFoodSummaryFn]);
      expect(jsonDecode(backend.sent.single.body)['term'], 'pâtes');
    });

    test('German still tries German names before English', () async {
      locator.registerSingleton<ConfigDataSource>(_Toggles(null));
      device(const [Locale('de', 'DE')]);

      await SpFoodDataSource().fetchSearchWordResults('Käse');

      expect(rpcs(), [
        SPConst.searchFoodTranslationFn,
        SPConst.searchFoodSummaryFn,
      ]);
    });

    test('with every source switched off it asks nothing', () async {
      locator.registerSingleton<ConfigDataSource>(
        _Toggles({
          for (final code in SPConst.foodSourceDisplayNames.keys) code: false,
        }),
      );
      device(const [Locale('fr', 'FR')]);

      final results = await SpFoodDataSource().fetchSearchWordResults('pâtes');

      expect(results, isEmpty);
      expect(backend.sent, isEmpty);
    });
  });
}

/// Answers every Supabase request with an empty PostgREST result set.
class _RecordingClient extends http.BaseClient {
  final sent = <http.Request>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent.add(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode('[]')),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }
}

class _Toggles extends Fake implements ConfigDataSource {
  final Map<String, bool>? toggles;
  _Toggles(this.toggles);

  @override
  Future<Map<String, bool>?> getFoodSourceToggles() async => toggles;
}
