import 'package:meta/meta.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

/// A single logged meal intake as exported to the platform health store
/// (Health Connect on Android, Apple Health on iOS).
///
/// Plugin-agnostic: carries only primitive values and strings so nothing above
/// the data-source layer depends on the `health` package.
@immutable
class ExternalMealIntake {
  /// Stable client record id used for deduplication / in-place updates.
  final String id;

  /// Optional display name of the food or meal.
  final String? name;

  /// The meal slot: 'BREAKFAST', 'LUNCH', 'DINNER', 'SNACK', or 'UNKNOWN'.
  final String mealTypeName;

  /// Timestamp when the food was consumed.
  final DateTime dateTime;

  /// Total energy in kcal.
  final double? calories;

  /// Total carbohydrates in grams.
  final double? carbohydrates;

  /// Total protein in grams.
  final double? protein;

  /// Total fat in grams.
  final double? fatTotal;

  /// Dietary fiber in grams.
  final double? fiber;

  /// Sugars in grams.
  final double? sugar;

  /// Saturated fat in grams.
  final double? fatSaturated;

  /// Monounsaturated fat in grams.
  final double? fatMonounsaturated;

  /// Polyunsaturated fat in grams.
  final double? fatPolyunsaturated;

  /// Cholesterol in grams.
  final double? cholesterol;

  /// Sodium in grams.
  final double? sodium;

  /// Potassium in grams.
  final double? potassium;

  /// Calcium in grams.
  final double? calcium;

  /// Iron in grams.
  final double? iron;

  /// Magnesium in grams.
  final double? magnesium;

  /// Phosphorus in grams.
  final double? phosphorus;

  /// Zinc in grams.
  final double? zinc;

  /// Vitamin A in grams.
  final double? vitaminA;

  /// Vitamin C in grams.
  final double? vitaminC;

  /// Vitamin D in grams.
  final double? vitaminD;

  /// Vitamin B6 in grams.
  final double? vitaminB6;

  /// Vitamin B12 in grams.
  final double? vitaminB12;

  /// Niacin in grams.
  final double? niacin;

  const ExternalMealIntake({
    required this.id,
    required this.mealTypeName,
    required this.dateTime,
    this.name,
    this.calories,
    this.carbohydrates,
    this.protein,
    this.fatTotal,
    this.fiber,
    this.sugar,
    this.fatSaturated,
    this.fatMonounsaturated,
    this.fatPolyunsaturated,
    this.cholesterol,
    this.sodium,
    this.potassium,
    this.calcium,
    this.iron,
    this.magnesium,
    this.phosphorus,
    this.zinc,
    this.vitaminA,
    this.vitaminC,
    this.vitaminD,
    this.vitaminB6,
    this.vitaminB12,
    this.niacin,
  });

  /// Maps an [IntakeEntity] to an [ExternalMealIntake] ready for export.
  factory ExternalMealIntake.fromIntake(IntakeEntity intake) {
    final nutriments = intake.meal.nutriments;
    final amount = intake.amount;

    // Helper to scale a per-100g value to grams for the given intake amount.
    double? scaleGrams(double? per100g) {
      if (per100g == null || amount <= 0) return null;
      return amount * (per100g / 100.0);
    }

    // Helper for values stored in mg per 100g (converts mg to grams: / 1000).
    double? scaleMgToGrams(double? mgPer100g) {
      final inMg = scaleGrams(mgPer100g);
      return inMg != null ? inMg / 1000.0 : null;
    }

    // Helper for values stored in µg per 100g (converts µg to grams: / 1000000).
    double? scaleUgToGrams(double? ugPer100g) {
      final inUg = scaleGrams(ugPer100g);
      return inUg != null ? inUg / 1000000.0 : null;
    }

    String mealTypeString;
    switch (intake.type) {
      case IntakeTypeEntity.breakfast:
        mealTypeString = 'BREAKFAST';
        break;
      case IntakeTypeEntity.lunch:
        mealTypeString = 'LUNCH';
        break;
      case IntakeTypeEntity.dinner:
        mealTypeString = 'DINNER';
        break;
      case IntakeTypeEntity.snack:
        mealTypeString = 'SNACK';
        break;
    }

    final name = intake.meal.name?.trim();

    return ExternalMealIntake(
      id: 'ont_intake_${intake.id}',
      name: (name != null && name.isNotEmpty) ? name : null,
      mealTypeName: mealTypeString,
      dateTime: intake.dateTime,
      calories: intake.totalKcal,
      carbohydrates: intake.totalCarbsGram,
      protein: intake.totalProteinsGram,
      fatTotal: intake.totalFatsGram,
      fiber: scaleGrams(nutriments.fiber100),
      sugar: scaleGrams(nutriments.sugars100),
      fatSaturated: scaleGrams(nutriments.saturatedFat100),
      fatMonounsaturated: scaleGrams(nutriments.monounsaturatedFat100),
      fatPolyunsaturated: scaleGrams(nutriments.polyunsaturatedFat100),
      cholesterol: scaleMgToGrams(nutriments.cholesterol100),
      sodium: scaleMgToGrams(nutriments.sodium100),
      potassium: scaleMgToGrams(nutriments.potassium100),
      calcium: scaleMgToGrams(nutriments.calcium100),
      iron: scaleMgToGrams(nutriments.iron100),
      magnesium: scaleMgToGrams(nutriments.magnesium100),
      phosphorus: scaleMgToGrams(nutriments.phosphorus100),
      zinc: scaleMgToGrams(nutriments.zinc100),
      vitaminA: scaleUgToGrams(nutriments.vitaminA100),
      vitaminC: scaleMgToGrams(nutriments.vitaminC100),
      vitaminD: scaleUgToGrams(nutriments.vitaminD100),
      vitaminB6: scaleMgToGrams(nutriments.vitaminB6100),
      vitaminB12: scaleUgToGrams(nutriments.vitaminB12100),
      niacin: scaleMgToGrams(nutriments.niacin100),
    );
  }

  @override
  String toString() =>
      'ExternalMealIntake($id, $mealTypeName, $name, $dateTime, ${calories}kcal)';
}
