import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditDialog extends StatefulWidget {
  /// The amount field, for tests.
  static const amountFieldKey = Key('edit-dialog-amount');

  /// The macros stack once the text scale is above this (130 %), the same
  /// point at which the home macro rings stack (`MacroNutrientsView`).
  /// It is measured on 10 px text, so a non-linear scaler is judged by
  /// how it treats small labels like these.
  static const stackAboveTextScale = 1.3;

  final IntakeEntity intakeEntity;
  final bool usesImperialUnits;

  const EditDialog({
    super.key,
    required this.intakeEntity,
    required this.usesImperialUnits,
  });

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController amountEditingController;

  @override
  void initState() {
    super.initState();
    double initialAmount = _convertValue(
      widget.intakeEntity.amount,
      widget.intakeEntity.meal.mealUnit,
    );
    amountEditingController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrolls rather than overflows with a large font and the keyboard up.
      scrollable: true,
      title: Text(S.of(context).editItemDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: EditDialog.amountFieldKey,
            controller: amountEditingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
              labelText: S.of(context).quantityLabel,
              suffixText: _convertUnit(widget.intakeEntity.meal.mealUnit ?? ''),
            ),
          ),
          const SizedBox(height: Dimens.spacing16),
          // The energy and macros of the amount being typed (#1330).
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: amountEditingController,
            builder: (context, _, _) => _buildNutrition(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final newAmount = _typedAmount();
            if (newAmount == null) return;
            Navigator.of(context).pop(
              _convertBackToMetricValue(
                newAmount,
                widget.intakeEntity.meal.mealUnit,
              ),
            );
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }

  double? _typedAmount() =>
      double.tryParse(amountEditingController.text.replaceAll(',', '.'));

  /// The typed amount in the meal's metric unit, or null when the field
  /// holds no usable amount (empty, not a number, negative, too large).
  double? _typedMetricAmount() {
    final typed = _typedAmount();
    if (typed == null || !typed.isFinite || typed < 0) return null;
    final metric = _convertBackToMetricValue(
      typed,
      widget.intakeEntity.meal.mealUnit,
    );
    return metric.isFinite ? metric : null;
  }

  /// [perUnit] scaled to [amount], the way [IntakeEntity.totalKcal] and its
  /// siblings do it. Null, shown as unknown, when the food lacks the value
  /// or there is no amount: a missing value must not read as 0 (#1474).
  double? _total(double? amount, double? perUnit) {
    if (amount == null || perUnit == null) return null;
    final total = amount * perUnit;
    return total.isFinite ? total : null;
  }

  Widget _buildNutrition(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final nutriments = widget.intakeEntity.meal.nutriments;
    final amount = _typedMetricAmount();
    final kcal = _total(amount, nutriments.energyPerUnit);

    final macros = [
      MealDetailMacroNutrients(
        typeString: S.of(context).carbsLabel,
        value: _total(amount, nutriments.carbohydratesPerUnit),
        color: palette.carbs,
      ),
      MealDetailMacroNutrients(
        typeString: S.of(context).fatLabel,
        value: _total(amount, nutriments.fatPerUnit),
        color: palette.fat,
      ),
      MealDetailMacroNutrients(
        typeString: S.of(context).proteinLabel,
        value: _total(amount, nutriments.proteinsPerUnit),
        color: palette.protein,
      ),
    ];
    // Side by side the three share a narrow dialog; at a large font they
    // stack, as the home macro rings do. Either way a label too long for
    // its space ("Kohlenhydrate") shrinks rather than overflows.
    final stack =
        MediaQuery.textScalerOf(context).scale(10) / 10 >
        EditDialog.stackAboveTextScale;
    Widget fit(Widget macro) => FittedBox(fit: BoxFit.scaleDown, child: macro);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            kcal == null
                ? missingNutrientPlaceholder
                : EnergyDisplay.formatWithUnit(context, kcal),
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: Dimens.spacing16),
        if (stack)
          for (final (i, macro) in macros.indexed) ...[
            if (i > 0) const SizedBox(height: Dimens.spacing12),
            fit(macro),
          ]
        else
          Row(
            children: [for (final macro in macros) Expanded(child: fit(macro))],
          ),
      ],
    );
  }

  double _convertValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.gToOz(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.mlToFlOz(value) : value;
      default:
        return value;
    }
  }

  double _convertBackToMetricValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.ozToG(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.flOzToMl(value) : value;
      default:
        return value;
    }
  }

  String _convertUnit(String unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? 'oz' : 'g';
      case 'ml':
        return widget.usesImperialUnits ? 'fl.oz' : 'ml';
      default:
        return unit;
    }
  }
}
