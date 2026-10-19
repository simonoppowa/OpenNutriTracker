import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';

typedef _Entry = ({double? per100, double grams});

NutrientTotal _total(List<_Entry> entries, {double divisor = 1}) =>
    NutrientTotal.over(
      entries,
      per100: (e) => e.per100,
      amountG: (e) => e.grams,
      divisor: divisor,
    );

void main() {
  test('all known: the plain sum', () {
    final total = _total([(per100: 10, grams: 200), (per100: 5, grams: 100)]);

    expect(total.sum, 25);
    expect(total.isUnknown, isFalse);
    expect(total.isPartial, isFalse);
    expect(total.valueOrNull, 25);
  });

  test('all unknown: unknown, not 0', () {
    final total = _total([
      (per100: null, grams: 200),
      (per100: null, grams: 50),
    ]);

    expect(total.isUnknown, isTrue);
    expect(total.valueOrNull, isNull);
    expect(total.unknownEntries, 2);
  });

  test('mixed: a lower bound with the number of entries without a value', () {
    final total = _total([(per100: 10, grams: 200), (per100: null, grams: 50)]);

    expect(total.sum, 20);
    expect(total.isPartial, isTrue);
    expect(total.knownEntries, 1);
    expect(total.unknownEntries, 1);
  });

  test('an empty list is 0 and not unknown', () {
    final total = _total(const []);

    expect(total.sum, 0);
    expect(total.isUnknown, isFalse);
    expect(total.isPartial, isFalse);
  });

  test('the weekly mean divides the sum, not the counts', () {
    final total = _total([
      (per100: 70, grams: 100),
      (per100: null, grams: 100),
    ], divisor: 7);

    expect(total.sum, 10);
    expect(total.knownEntries, 1);
    expect(total.unknownEntries, 1);
  });

  test('the fields read and write every stored value', () {
    final values = {
      for (final (i, field) in NutrientField.values.indexed) field: i + 1.0,
    };

    final entity = NutrientField.entityFrom(values);

    for (final field in NutrientField.values) {
      expect(field.per100(entity), values[field], reason: field.name);
    }
    expect(NutrientField.values, hasLength(24));
    expect(NutrientField.sodium.per100(MealNutrimentsEntity.empty()), isNull);
  });
}
