import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/home/domain/entity/nutrient_contribution_entity.dart';

import '../../../fixture/intake_entity_fixtures.dart';

void main() {
  test('foods are listed by what they gave, most first, without the ones '
      'that gave none', () {
    final contributions = NutrientContributionEntity.fromIntakes([
      intakeOf('Oats', 80, protein100: 13, carbs100: 60),
      intakeOf('Chicken breast', 150, protein100: 23),
      intakeOf('Apple', 150, carbs100: 12),
    ], MacroNutrient.protein);

    expect([for (final c in contributions) c.name], ['Chicken breast', 'Oats']);
    expect(contributions.first.grams, closeTo(34.5, 0.01));
    expect(contributions.last.grams, closeTo(10.4, 0.01));
  });

  test('a food logged in two meals is one row with both meals', () {
    final contributions = NutrientContributionEntity.fromIntakes([
      intakeOf('Milk', 200, protein100: 3.5, type: IntakeTypeEntity.breakfast),
      intakeOf('Milk', 200, protein100: 3.5, type: IntakeTypeEntity.dinner),
    ], MacroNutrient.protein);

    expect(contributions, hasLength(1));
    expect(contributions.single.grams, closeTo(14, 0.01));
    expect(contributions.single.meals, [
      IntakeTypeEntity.breakfast,
      IntakeTypeEntity.dinner,
    ]);
  });
}
