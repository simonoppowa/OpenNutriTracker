import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Shown in place of a nutrient value the food doesn't carry, so a missing
/// value never reads as a real 0 (#1474).
const missingNutrientPlaceholder = '—';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textStyleNormal =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.textStrong) ??
            const TextStyle();
    final textStyleBold = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: palette.textMuted) ??
        const TextStyle();

    final headerText = usesImperialUnits && servingQuantity != null
        ? "${S.of(context).perServingLabel} (${servingQuantity!.roundToPrecision(1)}${servingUnit ?? 'g/ml'})"
        : S.of(context).per100gmlLabel;

    final n = product.nutriments;
    final hasMicroData = n.hasMicronutrientData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).nutritionInfoLabel,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Dimens.spacing16),
        AppCard(
          color: palette.surfaceMuted,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.spacing16,
            vertical: Dimens.spacing8,
          ),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: palette.border, width: Dimens.hairline),
            ),
            children: <TableRow>[
            _getNutrimentsTableRow("", headerText, textStyleBold),
            _getNutrimentsTableRow(
              S.of(context).energyLabel,
              n.energyKcal100 == null
                  ? missingNutrientPlaceholder
                  : EnergyDisplay.formatWithUnit(context,
                      _adjustValueForServing(n.energyKcal100!.toDouble())),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).fatLabel,
              _formatValue(n.fat100, 'g'),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              '   ${S.of(context).saturatedFatLabel}',
              _formatValue(n.saturatedFat100, 'g'),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).carbohydrateLabel,
              _formatValue(n.carbohydrates100, 'g'),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              '    ${S.of(context).sugarLabel}',
              _formatValue(n.sugars100, 'g'),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).fiberLabel,
              _formatValue(n.fiber100, 'g'),
              textStyleNormal,
            ),
            _getNutrimentsTableRow(
              S.of(context).proteinLabel,
              _formatValue(n.proteins100, 'g'),
              textStyleNormal,
            ),
            ],
          ),
        ),
        // The Settings switch decides whether the section exists at all
        // (#1361); the data only decides whether it opens expanded.
        if (showMicronutrients) ...[
          const SizedBox(height: Dimens.spacing8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                S.of(context).micronutrientsLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              initiallyExpanded: hasMicroData,
              children: [
                AppCard(
                  color: palette.surfaceMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spacing16,
                    vertical: Dimens.spacing8,
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: palette.border, width: Dimens.hairline),
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

  String _formatValue(double? valuePer100, String unit) {
    if (valuePer100 == null) return missingNutrientPlaceholder;
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
      _formatValue(valuePer100, unit),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
          child: Text(label, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
          child: Text(
            quantityString,
            style: textStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
