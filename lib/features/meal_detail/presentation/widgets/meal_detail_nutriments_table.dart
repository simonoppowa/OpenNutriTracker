import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The nutrition table of the meal detail. Every stored value is listed, a
/// missing one as "—" instead of 0, per 100 g (or per serving in imperial
/// mode) and, when [selectedAmountG] is given, for that amount too (#48).
/// The micronutrients show only with the "Show micronutrients" setting.
class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;
  final bool usesImperialUnits;
  final double? servingQuantity;
  final String? servingUnit;
  final bool showMicronutrients;

  /// The amount the user is about to log, in grams.
  final double? selectedAmountG;

  const MealDetailNutrimentsTable({
    super.key,
    required this.product,
    required this.usesImperialUnits,
    this.servingQuantity,
    this.servingUnit,
    this.showMicronutrients = false,
    this.selectedAmountG,
  });

  static const _mainRows = <(NutrientField, bool)>[
    (NutrientField.energyKcal, false),
    (NutrientField.fat, false),
    (NutrientField.saturatedFat, true),
    (NutrientField.carbohydrates, false),
    (NutrientField.sugars, true),
    (NutrientField.fiber, false),
    (NutrientField.proteins, false),
  ];

  static const _microRows = <(NutrientField, bool)>[
    (NutrientField.monounsaturatedFat, true),
    (NutrientField.polyunsaturatedFat, true),
    (NutrientField.transFat, true),
    (NutrientField.cholesterol, false),
    (NutrientField.sodium, false),
    (NutrientField.potassium, false),
    (NutrientField.magnesium, false),
    (NutrientField.calcium, false),
    (NutrientField.iron, false),
    (NutrientField.zinc, false),
    (NutrientField.phosphorus, false),
    (NutrientField.vitaminA, false),
    (NutrientField.vitaminC, false),
    (NutrientField.vitaminD, false),
    (NutrientField.vitaminB6, false),
    (NutrientField.vitaminB12, false),
    (NutrientField.niacin, false),
  ];

  bool get _perServing => usesImperialUnits && servingQuantity != null;

  /// Whether a column for the selected amount adds anything.
  bool get _showAmountColumn {
    final amount = selectedAmountG;
    return amount != null && amount > 0 && (_perServing || amount != 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textStyleNormal =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.textStrong) ??
        const TextStyle();
    final textStyleBold =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textMuted,
        ) ??
        const TextStyle();

    final s = S.of(context);
    final headerText = _perServing
        ? "${s.perServingLabel} (${servingQuantity!.roundToPrecision(1)}${servingUnit ?? 'g/ml'})"
        : s.per100gmlLabel;
    final headers = [
      headerText,
      if (_showAmountColumn)
        s.nutritionForAmountLabel(
          '${selectedAmountG!.roundToPrecision(1)} ${product.isLiquid ? 'ml' : 'g'}',
        ),
    ];

    TableRow row((NutrientField, bool) entry, TextStyle style) {
      final (field, indented) = entry;
      final per100 = field.per100(product.nutriments);
      final base = per100 == null || !_perServing
          ? per100
          : per100 * servingQuantity! / 100;
      return _tableRow('${indented ? '   ' : ''}${_label(context, field)}', [
        _format(context, field, base),
        if (_showAmountColumn)
          _format(
            context,
            field,
            per100 == null ? null : per100 * selectedAmountG! / 100,
          ),
      ], style);
    }

    Widget table(List<TableRow> rows) => AppCard(
      color: palette.surfaceMuted,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing8,
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: FlexColumnWidth(1.4)},
        border: TableBorder(
          horizontalInside: BorderSide(
            color: palette.border,
            width: Dimens.hairline,
          ),
        ),
        children: rows,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.nutritionInfoLabel,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Dimens.spacing16),
        table([
          _tableRow('', headers, textStyleBold),
          for (final entry in _mainRows) row(entry, textStyleNormal),
        ]),
        if (showMicronutrients) ...[
          const SizedBox(height: Dimens.spacing8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                s.micronutrientsLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              initiallyExpanded: product.nutriments.hasMicronutrientData,
              children: [
                table([
                  for (final entry in _microRows) row(entry, textStyleNormal),
                ]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _format(
    BuildContext context,
    NutrientField field,
    double? value,
  ) {
    if (value == null) return '—';
    if (field == NutrientField.energyKcal) {
      return EnergyDisplay.formatWithUnit(context, value);
    }
    return '${value.roundToPrecision(2)}${field.unit}';
  }

  static String _label(BuildContext context, NutrientField field) {
    final s = S.of(context);
    return switch (field) {
      NutrientField.energyKcal => s.energyLabel,
      NutrientField.carbohydrates => s.carbohydrateLabel,
      NutrientField.fat => s.fatLabel,
      NutrientField.proteins => s.proteinLabel,
      NutrientField.sugars => s.sugarLabel,
      NutrientField.saturatedFat => s.saturatedFatLabel,
      NutrientField.fiber => s.fiberLabel,
      NutrientField.monounsaturatedFat => s.monounsaturatedFatLabel,
      NutrientField.polyunsaturatedFat => s.polyunsaturatedFatLabel,
      NutrientField.transFat => s.transFatLabel,
      NutrientField.cholesterol => s.cholesterolLabel,
      NutrientField.sodium => s.sodiumLabel,
      NutrientField.potassium => s.potassiumLabel,
      NutrientField.magnesium => s.magnesiumLabel,
      NutrientField.calcium => s.calciumLabel,
      NutrientField.iron => s.ironLabel,
      NutrientField.zinc => s.zincLabel,
      NutrientField.phosphorus => s.phosphorusLabel,
      NutrientField.vitaminA => s.vitaminALabel,
      NutrientField.vitaminC => s.vitaminCLabel,
      NutrientField.vitaminD => s.vitaminDLabel,
      NutrientField.vitaminB6 => s.vitaminB6Label,
      NutrientField.vitaminB12 => s.vitaminB12Label,
      NutrientField.niacin => s.niacinLabel,
    };
  }

  static TableRow _tableRow(
    String label,
    List<String> values,
    TextStyle textStyle,
  ) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
          child: Text(label, style: textStyle),
        ),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
            child: Text(value, style: textStyle, textAlign: TextAlign.right),
          ),
      ],
    );
  }
}
