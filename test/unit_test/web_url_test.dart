import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/utils/web_url.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

OFFProductDTO _offProduct(String? url) => OFFProductDTO(
  code: '123',
  product_name: 'Test product',
  product_name_en: 'Test product',
  product_name_fr: null,
  product_name_de: null,
  brands: null,
  image_front_thumb_url: null,
  image_front_url: null,
  image_ingredients_url: null,
  image_nutrition_url: null,
  image_url: null,
  url: url,
  quantity: null,
  product_quantity: null,
  serving_quantity: 30,
  serving_size: null,
  serving_quantity_unit: null,
  nutriments: null,
);

MealDBO _storedMeal(String? url) => MealDBO(
  code: '123',
  name: 'Stored',
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: url,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsDBO.fromProductNutrimentsEntity(
    MealNutrimentsEntity.empty(),
  ),
  source: MealSourceDBO.off,
);

void main() {
  group('normalizeWebUrl', () {
    test('keeps a valid absolute http(s) URL as is', () {
      expect(
        normalizeWebUrl('https://world.openfoodfacts.org/product/123'),
        'https://world.openfoodfacts.org/product/123',
      );
      expect(normalizeWebUrl('http://example.com/a'), 'http://example.com/a');
    });

    test('trims surrounding whitespace', () {
      expect(
        normalizeWebUrl('  https://example.com/a \n'),
        'https://example.com/a',
      );
    });

    test('returns null for null, empty and whitespace-only input', () {
      expect(normalizeWebUrl(null), isNull);
      expect(normalizeWebUrl(''), isNull);
      expect(normalizeWebUrl('   '), isNull);
    });

    test('percent-encodes spaces and non-ASCII characters', () {
      expect(
        normalizeWebUrl('https://example.com/a b?q=x y'),
        'https://example.com/a%20b?q=x%20y',
      );
      expect(
        normalizeWebUrl('https://ru.openfoodfacts.org/продукт/1'),
        'https://ru.openfoodfacts.org/'
        '%D0%BF%D1%80%D0%BE%D0%B4%D1%83%D0%BA%D1%82/1',
      );
    });

    test('does not double-encode and is idempotent', () {
      const encoded = 'https://example.com/a%20b';
      expect(normalizeWebUrl(encoded), encoded);
      final once = normalizeWebUrl('https://example.com/é x')!;
      expect(normalizeWebUrl(once), once);
    });

    test('rejects URLs without an http(s) scheme', () {
      expect(normalizeWebUrl('world.openfoodfacts.org/product/1'), isNull);
      expect(normalizeWebUrl('/product/1'), isNull);
      expect(normalizeWebUrl('ftp://example.com/x'), isNull);
      expect(normalizeWebUrl('javascript:alert(1)'), isNull);
    });

    test('rejects URLs without a usable host', () {
      expect(normalizeWebUrl('https://'), isNull);
      expect(normalizeWebUrl('https:///x'), isNull);
      expect(normalizeWebUrl('http://a b.org/'), isNull);
      expect(normalizeWebUrl('https://example.com:abc/x'), isNull);
    });
  });

  group('MealEntity url normalization', () {
    test('OFF product with an empty url gets a null url', () {
      expect(MealEntity.fromOFFProduct(_offProduct('')).url, isNull);
    });

    test('OFF product with a bare path or spaces is repaired or dropped', () {
      expect(MealEntity.fromOFFProduct(_offProduct('product/123')).url, isNull);
      expect(
        MealEntity.fromOFFProduct(
          _offProduct('https://world.openfoodfacts.org/product/1/my product'),
        ).url,
        'https://world.openfoodfacts.org/product/1/my%20product',
      );
    });

    test('OFF product with a valid url keeps it', () {
      expect(
        MealEntity.fromOFFProduct(
          _offProduct('https://world.openfoodfacts.org/product/123'),
        ).url,
        'https://world.openfoodfacts.org/product/123',
      );
    });

    test('a stored meal with a bad url reads back with a null url', () {
      expect(MealEntity.fromMealDBO(_storedMeal('')).url, isNull);
      expect(MealEntity.fromMealDBO(_storedMeal('not a url')).url, isNull);
      expect(
        MealEntity.fromMealDBO(_storedMeal('https://example.com/a b')).url,
        'https://example.com/a%20b',
      );
      expect(MealEntity.fromMealDBO(_storedMeal(null)).url, isNull);
    });

    test('an FDC backend food links to its detail page', () {
      final meal = MealEntity.fromSpFood(
        SpFoodDTO(
          foodId: 1,
          source: 'fdc_survey',
          sourceCode: '2707172',
          name: 'Test food',
        ),
      );
      expect(
        meal.url,
        'https://fdc.nal.usda.gov/fdc-app.html#/food-details/2707172/nutrients',
      );
    });
  });
}
