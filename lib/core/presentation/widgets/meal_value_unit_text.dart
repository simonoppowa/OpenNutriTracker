import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealValueUnitText extends StatelessWidget {
  final double value;
  final MealEntity meal;
  final bool usesImperialUnits;
  final TextStyle? textStyle;
  final String? prefix;

  const MealValueUnitText(
      {super.key,
      required this.value,
      required this.meal,
      required this.usesImperialUnits,
      this.textStyle,
      this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    final mealUnit = meal.mealUnit ?? S.of(context).gramMilliliterUnit;
    final displayUnit = _convertUnit(context, mealUnit);
    final displayValue = _convertValue(value, mealUnit);

    return Text(
      '$prefix${_formatValue(displayValue)} $displayUnit',
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  double _convertValue(double value, String unit) {
    switch (unit) {
      case 'g':
        return usesImperialUnits ? UnitCalc.gToOz(value) : value;
      case 'ml':
        return usesImperialUnits ? UnitCalc.mlToFlOz(value) : value;
      default:
        return value;
    }
  }

  String _convertUnit(BuildContext context, String unit) {
    switch (unit) {
      case 'g':
        return usesImperialUnits
            ? S.of(context).ozUnit
            : S.of(context).gramUnit;
      case 'ml':
        return usesImperialUnits
            ? S.of(context).flOzUnit
            : S.of(context).milliliterUnit;
      default:
        return unit;
    }
  }

  String _formatValue(double value) {
    final formattedValue = value.toStringAsFixed(2);
    return formattedValue.endsWith('.00')
        ? formattedValue.substring(0, formattedValue.length - 3)
        : formattedValue.endsWith('0')
            ? formattedValue.substring(0, formattedValue.length - 1)
            : formattedValue;
  }
}
