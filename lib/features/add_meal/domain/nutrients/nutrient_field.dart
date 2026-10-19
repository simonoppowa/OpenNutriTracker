import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Every value a [MealNutrimentsEntity] stores per 100 g, with its unit, so
/// code that handles all of them (sums, coverage, lists) does not repeat
/// the 24 fields (#46).
enum NutrientField {
  energyKcal('kcal'),
  carbohydrates('g'),
  fat('g'),
  proteins('g'),
  sugars('g'),
  saturatedFat('g'),
  fiber('g'),
  monounsaturatedFat('g'),
  polyunsaturatedFat('g'),
  transFat('g'),
  cholesterol('mg'),
  sodium('mg'),
  potassium('mg'),
  magnesium('mg'),
  calcium('mg'),
  iron('mg'),
  zinc('mg'),
  phosphorus('mg'),
  vitaminA('µg'),
  vitaminC('mg'),
  vitaminD('µg'),
  vitaminB6('mg'),
  vitaminB12('µg'),
  niacin('mg');

  final String unit;

  const NutrientField(this.unit);

  /// The value per 100 g in [n], or null when unknown.
  double? per100(MealNutrimentsEntity n) => switch (this) {
    energyKcal => n.energyKcal100,
    carbohydrates => n.carbohydrates100,
    fat => n.fat100,
    proteins => n.proteins100,
    sugars => n.sugars100,
    saturatedFat => n.saturatedFat100,
    fiber => n.fiber100,
    monounsaturatedFat => n.monounsaturatedFat100,
    polyunsaturatedFat => n.polyunsaturatedFat100,
    transFat => n.transFat100,
    cholesterol => n.cholesterol100,
    sodium => n.sodium100,
    potassium => n.potassium100,
    magnesium => n.magnesium100,
    calcium => n.calcium100,
    iron => n.iron100,
    zinc => n.zinc100,
    phosphorus => n.phosphorus100,
    vitaminA => n.vitaminA100,
    vitaminC => n.vitaminC100,
    vitaminD => n.vitaminD100,
    vitaminB6 => n.vitaminB6100,
    vitaminB12 => n.vitaminB12100,
    niacin => n.niacin100,
  };

  /// Nutriments holding [values] per 100 g; a field not given is unknown.
  static MealNutrimentsEntity entityFrom(Map<NutrientField, double?> values) =>
      MealNutrimentsEntity(
        energyKcal100: values[energyKcal],
        carbohydrates100: values[carbohydrates],
        fat100: values[fat],
        proteins100: values[proteins],
        sugars100: values[sugars],
        saturatedFat100: values[saturatedFat],
        fiber100: values[fiber],
        monounsaturatedFat100: values[monounsaturatedFat],
        polyunsaturatedFat100: values[polyunsaturatedFat],
        transFat100: values[transFat],
        cholesterol100: values[cholesterol],
        sodium100: values[sodium],
        potassium100: values[potassium],
        magnesium100: values[magnesium],
        calcium100: values[calcium],
        iron100: values[iron],
        zinc100: values[zinc],
        phosphorus100: values[phosphorus],
        vitaminA100: values[vitaminA],
        vitaminC100: values[vitaminC],
        vitaminD100: values[vitaminD],
        vitaminB6100: values[vitaminB6],
        vitaminB12100: values[vitaminB12],
        niacin100: values[niacin],
      );
}
