import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/l10n/shipped_locales.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Food names must follow the language the app is read in, not the device
/// language. The two differ on iOS and on Android below 13 whenever the user
/// has picked a language in Settings; `Platform.localeName` only tracks the
/// picker where `AppLocaleService` writes it through (#1214).
void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ont-test',
      packageName: 'test',
      version: '0.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(AppLocale.reset);

  // A language the test VM is not running in, so a match proves the app's
  // choice won over the device — whatever the host's locale is.
  final device = SupportedLanguage.fromCode(Platform.localeName);
  final chosen = device == SupportedLanguage.de ? 'it' : 'de';
  final chosenProduct = chosen == 'de' ? 'Brot' : 'Pane';

  group('AppLocale', () {
    test('follows the device until the app chooses', () {
      expect(
        shippedLocales.keys,
        contains(AppLocale.localeName.split('_').first),
        reason: 'the system fallback resolves against the shipped locales',
      );
    });

    test('resolves the device preference list as MaterialApp does', () {
      // Unshipped French first, shipped German second: the UI shows German,
      // so food names must be German too — not the first locale, and not
      // English.
      AppLocale.preferredLocales = () => const [
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
      ];
      expect(AppLocale.localeName, 'de');
      expect(
        SupportedLanguage.fromCode(AppLocale.localeName),
        SupportedLanguage.de,
      );

      // A device with no shipped language at all falls to English, the
      // first shipped locale, as the UI does.
      AppLocale.preferredLocales = () => const [Locale('fr', 'FR')];
      expect(AppLocale.localeName, 'en');
    });

    test('LocaleProvider is its writer, at creation and on update', () {
      final provider = LocaleProvider(locale: Locale(chosen));
      expect(AppLocale.localeName, chosen);

      provider.updateLocale(null);
      expect(
        shippedLocales.keys,
        contains(AppLocale.localeName.split('_').first),
        reason: '"System default" hands the decision back to the device',
      );

      provider.updateLocale(const Locale('hu'));
      expect(AppLocale.localeName, 'hu');
    });
  });

  group('what follows the chosen language', () {
    test('the Open Food Facts word search asks for it under langs', () async {
      LocaleProvider(locale: Locale(chosen));
      Uri? requested;
      final dataSource = OFFDataSource(
        clientFactory: () => MockClient((request) async {
          requested ??= request.url;
          return http.Response(
            jsonEncode({'hits': [], 'count': 0, 'page': 1, 'page_size': 100}),
            200,
          );
        }),
      );

      await dataSource.fetchSearchWordResults('brot');

      expect(requested!.queryParameters['langs'], '$chosen,en');
    });

    test('an Open Food Facts product is named in it', () {
      LocaleProvider(locale: Locale(chosen));
      final product = OFFProductDTO(
        code: '1',
        product_name: 'Bread',
        product_name_en: 'Bread',
        product_name_fr: 'Pain',
        product_name_de: 'Brot',
        product_name_it: 'Pane',
        brands: null,
        image_front_thumb_url: null,
        image_front_url: null,
        image_ingredients_url: null,
        image_nutrition_url: null,
        image_url: null,
        url: null,
        quantity: null,
        product_quantity: null,
        serving_quantity: null,
        serving_size: null,
        nutriments: null,
      );

      expect(MealEntity.fromOFFProduct(product).name, chosenProduct);
      expect(SupportedLanguage.fromCode(AppLocale.localeName).name, chosen);
    });
  });
}
