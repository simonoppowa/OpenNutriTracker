import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/barcode_validator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

/// The Barcode field on Edit Meal (#167) was meant to clear a stored code
/// when blanked, but the screen turned an empty field into `null`, which
/// keeps the old code, so a barcode could never be removed again (#1403).
MealEntity _meal({required String? code, required MealSourceEntity source}) =>
    MealEntity(
      code: code,
      name: 'Oats',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: source,
    );

void main() {
  group('codeAfterEdit', () {
    final barcoded =
        _meal(code: '4006381333931', source: MealSourceEntity.custom);

    test('a blanked field clears a custom meal\'s barcode', () {
      final code = codeAfterEdit(barcoded, '');

      expect(code, isNotNull,
          reason: 'the meal keeps a code, so it is not keyed by its name');
      expect(code, isNot('4006381333931'));
      expect(isBarcodeFormatValid(code!), isFalse,
          reason: 'the field shows nothing for an internal id');
    });

    test('a blanked field keeps the internal id of a meal with no barcode',
        () {
      final meal = _meal(code: 'b9f7c1e2-uuid', source: MealSourceEntity.custom);

      expect(codeAfterEdit(meal, ''), equals('b9f7c1e2-uuid'));
    });

    test('a blanked field keeps a code-less meal code-less', () {
      final meal = _meal(code: null, source: MealSourceEntity.custom);

      expect(codeAfterEdit(meal, ''), isNull);
    });

    test('a blanked field leaves a product\'s own code alone', () {
      final meal = _meal(code: '4006381333931', source: MealSourceEntity.off);

      expect(codeAfterEdit(meal, ''), equals('4006381333931'));
    });

    test('a typed barcode replaces the code', () {
      expect(codeAfterEdit(barcoded, '96385074'), equals('96385074'));
    });

    test('no override keeps the code', () {
      expect(codeAfterEdit(barcoded, null), equals('4006381333931'));
    });
  });
}
