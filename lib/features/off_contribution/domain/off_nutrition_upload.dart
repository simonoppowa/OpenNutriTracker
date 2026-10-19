import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// The nutrition values of one product as Open Food Facts' product write
/// form takes them: per 100 g, each value with its unit, salt instead of
/// the app's sodium (salt = sodium × 2.5).
class OffNutritionUpload {
  final String barcode;
  final Map<String, String> fields;

  const OffNutritionUpload._(this.barcode, this.fields);

  /// Whether there is any value to send.
  bool get hasValues => fields.keys.any((key) => key.startsWith('nutriment_'));

  factory OffNutritionUpload.fromNutriments(
    String barcode,
    MealNutrimentsEntity nutriments,
  ) {
    final sodiumMg = nutriments.sodium100;
    final values = <String, (double?, String)>{
      'energy-kcal': (nutriments.energyKcal100, 'kcal'),
      'fat': (nutriments.fat100, 'g'),
      'saturated-fat': (nutriments.saturatedFat100, 'g'),
      'carbohydrates': (nutriments.carbohydrates100, 'g'),
      'sugars': (nutriments.sugars100, 'g'),
      'fiber': (nutriments.fiber100, 'g'),
      'proteins': (nutriments.proteins100, 'g'),
      'salt': (sodiumMg == null ? null : sodiumMg * 2.5 / 1000, 'g'),
    };
    return OffNutritionUpload._(barcode, {
      'nutrition_data_per': '100g',
      for (final MapEntry(key: name, value: (value, unit)) in values.entries)
        if (value != null) ...{
          'nutriment_$name': _format(value),
          'nutriment_${name}_unit': unit,
        },
    });
  }

  static String _format(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}
