import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/energy_plausibility.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

MealNutrimentsEntity _per100({
  double? kcal,
  double? fat,
  double? carbs,
  double? protein,
  double? fiber,
  double? sugars,
  double? saturatedFat,
}) => MealNutrimentsEntity(
  energyKcal100: kcal,
  fat100: fat,
  carbohydrates100: carbs,
  proteins100: protein,
  fiber100: fiber,
  sugars100: sugars,
  saturatedFat100: saturatedFat,
);

void main() {
  group('flags the Open Food Facts entries from the barcode test', () {
    test('Mitakos Hirtenkäse: 102 kcal stated, ~249 from the macros', () {
      final issue = checkEnergyPlausibility(
        _per100(kcal: 102, fat: 19.8, carbs: 0.6, protein: 17.2),
      );

      expect(issue, isNotNull);
      expect(issue!.statedKcal, 102);
      expect(issue.expectedKcal, closeTo(249, 1));
    });
  });

  group('leaves plausible products alone', () {
    final plausible = {
      'Milbona Skyr': _per100(kcal: 62.4, fat: 0.2, carbs: 4, protein: 11),
      'ja! Magerquark': _per100(kcal: 68, fat: 0.5, carbs: 4, protein: 12),
      'KoRo Erdnussmus': _per100(
        kcal: 619,
        fat: 51,
        carbs: 9,
        protein: 29,
        fiber: 7.1,
      ),
      'Milbona Mozzarella leicht': _per100(
        kcal: 165,
        fat: 8.5,
        carbs: 2,
        protein: 20.5,
      ),
      'orto mio Ajvar': _per100(
        kcal: 90,
        fat: 4.5,
        carbs: 9.7,
        protein: 1.2,
        fiber: 3,
      ),
      'Paradiso Mango-Maracuja': _per100(
        kcal: 46,
        fat: 0.5,
        carbs: 11,
        protein: 0.5,
      ),
      'water': _per100(kcal: 0, fat: 0, carbs: 0, protein: 0),
    };
    plausible.forEach((name, nutriments) {
      test(name, () => expect(checkEnergyPlausibility(nutriments), isNull));
    });
  });

  test('carbohydrate that includes fibre (FDC) is no mismatch', () {
    // 9*4 + 4*(25-20) + 4*20 + 2*20 = 176 kcal with fibre inside the carbs.
    expect(
      checkEnergyPlausibility(
        _per100(kcal: 176, fat: 4, carbs: 25, protein: 20, fiber: 20),
      ),
      isNull,
    );
  });

  test('a small absolute gap on a light drink is no mismatch', () {
    expect(
      checkEnergyPlausibility(_per100(kcal: 30, fat: 0, carbs: 11, protein: 0)),
      isNull,
      reason: '30 vs 44 kcal is under the 25 kcal floor',
    );
  });

  test('cannot judge without kcal or any macro', () {
    expect(
      checkEnergyPlausibility(_per100(fat: 10, carbs: 10, protein: 10)),
      isNull,
    );
    expect(
      checkEnergyPlausibility(_per100(kcal: 500, fat: 10, protein: 10)),
      isNull,
      reason: 'carbs unknown',
    );
  });

  test('sugar alcohols are flagged: the hint asks to check, nothing more', () {
    // Sugar-free chewing gum: polyols count as carbohydrate at 2.4 kcal/g,
    // which the 4 kcal/g estimate overshoots.
    expect(
      checkEnergyPlausibility(
        _per100(kcal: 220, fat: 0, carbs: 90, protein: 0),
      ),
      isNotNull,
    );
  });

  test('also reports what the search filter rejects', () {
    final issue = checkEnergyPlausibility(
      _per100(kcal: 400, fat: 10, carbs: 50, protein: 30, sugars: 80),
    );

    expect(issue, isNotNull);
    expect(issue!.rule, 'sugars_exceed_carbs');
  });
}
