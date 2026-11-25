import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// The three macros the dashboard tiles total (#1266).
enum MacroNutrient {
  carbs,
  fat,
  protein;

  double gramsIn(IntakeEntity intake) => switch (this) {
    MacroNutrient.carbs => intake.totalCarbsGram,
    MacroNutrient.fat => intake.totalFatsGram,
    MacroNutrient.protein => intake.totalProteinsGram,
  };
}

/// One food's share of a macro over a day's intakes: every entry of the
/// same food summed, so milk at breakfast and again at dinner is one row.
class NutrientContributionEntity {
  final String name;
  final String? brands;
  final double grams;

  /// The food as first logged that day, for its details.
  final MealEntity meal;

  /// The meals it was logged in, in the day's order.
  final List<IntakeTypeEntity> meals;

  const NutrientContributionEntity({
    required this.name,
    required this.brands,
    required this.grams,
    required this.meal,
    required this.meals,
  });

  /// [intakes]' contributions to [nutrient], highest first. Foods that add
  /// none of it are left out; a food is matched by its code, else its name,
  /// as the recently-added list matches them.
  static List<NutrientContributionEntity> fromIntakes(
    List<IntakeEntity> intakes,
    MacroNutrient nutrient,
  ) {
    final byFood = <String, NutrientContributionEntity>{};
    for (final intake in intakes) {
      final grams = nutrient.gramsIn(intake);
      if (grams <= 0) continue;
      final key = intake.meal.code ?? intake.meal.name ?? '';
      final previous = byFood[key];
      byFood[key] = NutrientContributionEntity(
        name: intake.meal.name ?? '',
        brands: intake.meal.brands,
        grams: (previous?.grams ?? 0) + grams,
        meal: previous?.meal ?? intake.meal,
        meals: [
          ...?previous?.meals,
          if (!(previous?.meals.contains(intake.type) ?? false)) intake.type,
        ],
      );
    }
    return byFood.values.toList()..sort((a, b) => b.grams.compareTo(a.grams));
  }
}
