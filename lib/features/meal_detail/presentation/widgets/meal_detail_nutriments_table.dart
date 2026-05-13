import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;
  final bool usesImperialUnits;
  final double? servingQuantity;
  final String? servingUnit;
  final bool showMicronutrients;

  const MealDetailNutrimentsTable({
    super.key,
    required this.product,
    required this.usesImperialUnits,
    this.servingQuantity,
    this.servingUnit,
    this.showMicronutrients = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyleNormal =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textStyleBold = Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle();

    final headerText = usesImperialUnits && servingQuantity != null
        ? "${S.of(context).perServingLabel} (${servingQuantity!.roundToPrecision(1)}${servingUnit ?? 'g/ml'})"
        : S.of(context).per100gmlLabel;

    final n = product.nutriments;
    final hasMicroData = n.hasMicronutrientData;
    final showSection = showMicronutrients || hasMicroData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).nutritionInfoLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          children: <TableRow>[
            _getNutrimentsTableRow("", headerText, textStyleBold),
            _getNutrimentsTableRow(
              S.of(context).energyLabel,
              EnergyDisplay.formatWithUnit(context,
                  _adjustValueForServing(n.energyKcal100?.toDouble() ?? 0)),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).fatLabel,
              "${_adjustValueForServing(n.fat100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              '   ${S.of(context).saturatedFatLabel}',
              "${_adjustValueForServing(n.saturatedFat100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).carbohydrateLabel,
              "${_adjustValueForServing(n.carbohydrates100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              '    ${S.of(context).sugarLabel}',
              "${_adjustValueForServing(n.sugars100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).fiberLabel,
              "${_adjustValueForServing(n.fiber100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).proteinLabel,
              "${_adjustValueForServing(n.proteins100 ?? 0).roundToPrecision(2)}g",
              textStyleNormal,
            ),
          ],
        ),
        if (showSection) ...[
          const SizedBox(height: 8.0),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                S.of(context).micronutrientsLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              initiallyExpanded: hasMicroData,
              children: [
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  children: [
                    // Extended lipid profile
                    _microRow(
                      '   ${S.of(context).monounsaturatedFatLabel}',
                      n.monounsaturatedFat100,
                      'g',
                      textStyleNormal,
                    ),
                    _microRow(
                      '   ${S.of(context).polyunsaturatedFatLabel}',
                      n.polyunsaturatedFat100,
                      'g',
                      textStyleNormal,
                    ),
                    _microRow(
                      '   ${S.of(context).transFatLabel}',
                      n.transFat100,
                      'g',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).cholesterolLabel,
                      n.cholesterol100,
                      'mg',
                      textStyleNormal,
                    ),
                    // Minerals
                    _microRow(
                      S.of(context).sodiumLabel,
                      n.sodium100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).potassiumLabel,
                      n.potassium100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).magnesiumLabel,
                      n.magnesium100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).calciumLabel,
                      n.calcium100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).ironLabel,
                      n.iron100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).zincLabel,
                      n.zinc100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).phosphorusLabel,
                      n.phosphorus100,
                      'mg',
                      textStyleNormal,
                    ),
                    // Vitamins
                    _microRow(
                      S.of(context).vitaminALabel,
                      n.vitaminA100,
                      'µg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).vitaminCLabel,
                      n.vitaminC100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).vitaminDLabel,
                      n.vitaminD100,
                      'µg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).vitaminB6Label,
                      n.vitaminB6100,
                      'mg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).vitaminB12Label,
                      n.vitaminB12100,
                      'µg',
                      textStyleNormal,
                    ),
                    _microRow(
                      S.of(context).niacinLabel,
                      n.niacin100,
                      'mg',
                      textStyleNormal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _adjustValueForServing(double value) {
    if (!usesImperialUnits || servingQuantity == null) {
      return value;
    }
    // Calculate per serving value based on 100g reference
    return (value * servingQuantity!) / 100;
  }

  String _formatMicroValue(double? valuePer100, String unit) {
    if (valuePer100 == null) return '—';
    final adjusted = _adjustValueForServing(valuePer100);
    return '${adjusted.roundToPrecision(2)}$unit';
  }

  TableRow _microRow(
    String label,
    double? valuePer100,
    String unit,
    TextStyle textStyle,
  ) {
    return _getNutrimentsTableRow(
      label,
      _formatMicroValue(valuePer100, unit),
      textStyle,
    );
  }

  TableRow _getNutrimentsTableRow(
    String label,
    String quantityString,
    TextStyle textStyle,
  ) {
    return TableRow(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(label, style: textStyle),
        ),
        Container(
          padding: const EdgeInsets.only(right: 8.0),
          alignment: Alignment.centerRight,
          child: Text(quantityString, style: textStyle),
        ),
      ],
    );
  }
}
