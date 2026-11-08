import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/util/hydrate_off_meal.dart';

/// #1475: in an English UI, the Open Food Facts bread a German UI names
/// "Vollkornbrot" was added from Recent as "pâine integrala cu secară".
/// The product has no English name, and its `product_name` (the name in its
/// main language) is Romanian, which the fallback took first.
void main() {
  const romanian = 'pâine integrala cu secară';
  const german = 'Vollkornbrot';

  // The product as OFF sends it: no English name, a German one, and a
  // Romanian product_name. Only the fields the name lookup reads matter.
  Map<String, dynamic> offJson({bool withGerman = true}) => {
    'code': '4337185000000',
    'product_name': romanian,
    if (withGerman) 'product_name_de': german,
    'brands': 'Kaufland',
  };

  OFFProductDTO product({bool withGerman = true}) =>
      OFFProductDTO.fromJson(offJson(withGerman: withGerman));

  tearDown(AppLocale.reset);

  group('getLocaleName with no name in the language asked for', () {
    test('English takes the German name, not the Romanian product_name', () {
      expect(product().getLocaleName(SupportedLanguage.en), german);
    });

    test('German still shows the German name', () {
      expect(product().getLocaleName(SupportedLanguage.de), german);
    });

    test('other languages with their own field take the German name too', () {
      for (final language in [
        SupportedLanguage.cs,
        SupportedLanguage.it,
        SupportedLanguage.sk,
        SupportedLanguage.tr,
        SupportedLanguage.uk,
        SupportedLanguage.hu,
        SupportedLanguage.es,
      ]) {
        expect(
          product().getLocaleName(language),
          german,
          reason: language.name,
        );
      }
    });

    test('product_name is still the last resort among the names', () {
      expect(
        product(withGerman: false).getLocaleName(SupportedLanguage.en),
        romanian,
      );
    });

    test('a known name stands in before any other language', () {
      expect(
        product().getLocaleName(SupportedLanguage.en, knownName: 'Brot'),
        'Brot',
      );
      expect(
        product(
          withGerman: false,
        ).getLocaleName(SupportedLanguage.en, knownName: german),
        german,
      );
    });

    test(
      'a known name does not override the name in the language asked for',
      () {
        expect(
          product().getLocaleName(SupportedLanguage.de, knownName: 'Brot'),
          german,
        );
      },
    );

    test('an empty known name is ignored', () {
      expect(
        product().getLocaleName(SupportedLanguage.en, knownName: ''),
        german,
      );
    });
  });

  group('MealEntity.fromOFFProduct follows the app language', () {
    test('English', () {
      AppLocale.select('en');
      expect(MealEntity.fromOFFProduct(product()).name, german);
    });

    test('German', () {
      AppLocale.select('de');
      expect(MealEntity.fromOFFProduct(product()).name, german);
    });

    test('Hungarian', () {
      AppLocale.select('hu');
      expect(MealEntity.fromOFFProduct(product()).name, german);
    });
  });

  // The + on a Recent entry swaps the stored, thin record for the full one
  // before it is added (fetchDetailedOffMeal); that swap is where the
  // Romanian name came in.
  group('adding a Recent entry keeps the name it was logged with', () {
    late _FakeOffDataSource off;
    late _FakeCache cache;
    late ProductsRepository products;

    setUp(() {
      off = _FakeOffDataSource();
      cache = _FakeCache();
      products = ProductsRepository(off, _UnusedSpFoodDataSource());
    });

    MealEntity loggedInGerman() {
      AppLocale.select('de');
      final meal = MealEntity.fromOFFProduct(product());
      expect(meal.detailed, isFalse);
      return meal;
    }

    test('the full record names it as logged in an English UI', () async {
      final recent = loggedInGerman();
      AppLocale.select('en');
      off.product = product();

      final full = await fetchDetailedOffMeal(recent, cache, products);

      expect(full!.detailed, isTrue);
      expect(full.name, german);
      expect(cache.written.single.name, german);
    });

    test(
      'when OFF no longer has a name the app ships, the logged name wins',
      () async {
        final recent = loggedInGerman();
        AppLocale.select('en');
        off.product = product(withGerman: false);

        final full = await fetchDetailedOffMeal(recent, cache, products);

        expect(full!.name, german);
      },
    );

    test('a name in the app language still replaces the logged one', () async {
      final recent = loggedInGerman();
      AppLocale.select('en');
      off.product = OFFProductDTO.fromJson({
        ...offJson(),
        'product_name_en': 'Wholegrain bread',
      });

      final full = await fetchDetailedOffMeal(recent, cache, products);

      expect(full!.name, 'Wholegrain bread');
    });

    test('a cached full record does not rename it either', () async {
      final recent = loggedInGerman();
      AppLocale.select('en');
      // Cached by an older build, with the old fallback's name.
      cache.detailed = MealDBO.fromMealEntity(
        MealEntity.fromOFFProduct(product(withGerman: false), detailed: true),
      );
      expect(cache.detailed!.name, romanian);

      final full = await fetchDetailedOffMeal(recent, cache, products);

      expect(full!.detailed, isTrue);
      expect(full.name, german);
      expect(off.lookups, 0);
    });
  });
}

class _FakeOffDataSource extends Fake implements OFFDataSource {
  OFFProductDTO? product;
  int lookups = 0;

  @override
  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    lookups++;
    return OFFProductResponseDTO(
      status: 1,
      status_verbose: 'product found',
      product: product,
    );
  }
}

class _UnusedSpFoodDataSource extends Fake implements SpFoodDataSource {}

class _FakeCache extends Fake implements RemoteSearchCacheDataSource {
  MealDBO? detailed;
  final written = <MealDBO>[];

  @override
  MealDBO? getDetailedByBarcode(String barcode) => detailed;

  @override
  Future<void> cache(MealDBO meal) async => written.add(meal);
}
