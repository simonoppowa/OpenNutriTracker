import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SharedMealCodeDialog extends StatefulWidget {
  const SharedMealCodeDialog({super.key});

  @override
  State<SharedMealCodeDialog> createState() => _SharedMealCodeDialogState();
}

class _SharedMealCodeDialogState extends State<SharedMealCodeDialog> {
  String _code = '';
  String? _error;

  void _parse() {
    try {
      final payload = SharedMealPayload.fromJsonString(_code.trim());
      Navigator.of(context).pop(payload);
    } on SharedMealParseException {
      setState(() => _error = S.of(context).sharedMealInvalidCodeLabel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: Dimens.shapeL,
      title: Text(S.of(context).pasteCodeLabel),
      content: SingleChildScrollView(
        child: Semantics(
          identifier: 'import-meal-code-input',
          child: TextField(
            onChanged: (value) => _code = value,
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText: S.of(context).pasteCodeHint,
              errorText: _error,
              errorMaxLines: 3,
              border: const OutlineInputBorder(
                borderRadius: Dimens.borderRadiusS,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        Semantics(
          identifier: 'import-meal-code-parse',
          child: TextButton(
            onPressed: _parse,
            child: Text(S.of(context).sharedMealParseLabel),
          ),
        ),
      ],
    );
  }
}

class SharedMealPreviewItem {
  final MealEntity? meal;
  final RecipeEntity? recipe;

  /// Whether [recipe]'s total weight was entered by hand on the sender's
  /// side (#1194). Passed to SaveRecipeUseCase.save so the import keeps it.
  final bool totalWeightOverridden;
  final double amount;
  final String unit;
  final String? barcode;

  const SharedMealPreviewItem({
    required this.meal,
    required this.amount,
    required this.unit,
    this.recipe,
    this.totalWeightOverridden = false,
    this.barcode,
  });

  double? get energyKcal {
    final energy = meal?.nutriments.energyPerUnit;
    return energy == null ? null : amount * energy;
  }
}

class SharedMealPreviewDialog extends StatelessWidget {
  final List<SharedMealPreviewItem> items;
  final String mealType;
  final bool usesImperialUnits;

  const SharedMealPreviewDialog({
    super.key,
    required this.items,
    required this.mealType,
    this.usesImperialUnits = false,
  });

  @override
  Widget build(BuildContext context) {
    final available = items.where((item) => item.meal != null).toList();
    // Summed as the rows show them, so the total adds up on screen (#1469).
    final kcals = available.map((item) => item.energyKcal ?? 0.0);
    // A skipped row (failed lookup) is missing from the sum too, so it makes
    // the total incomplete just like a food without energy data.
    final incomplete = items.any((item) => item.energyKcal == null);
    final numbers =
        NumberFormat('0.##', Localizations.localeOf(context).toString());
    return AlertDialog(
      shape: Dimens.shapeL,
      title: Text(S.of(context).importMealConfirmTitle(items.length)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).importMealConfirmContent(mealType)),
              const SizedBox(height: Dimens.spacing16),
              Text(mealType, style: Theme.of(context).textTheme.titleMedium),
              for (final item in items)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: Dimens.spacing8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.meal?.name?.trim().isNotEmpty == true
                          ? item.meal!.name!
                          : item.barcode ??
                              S.of(context).sharedMealUnnamedLabel),
                      Wrap(
                        spacing: Dimens.spacing16,
                        children: [
                          // The shared amount is already in the food's base
                          // unit (a "4 oz" intake is stored as 113.4 g), so
                          // show it the way the Diary shows the intake.
                          if (item.meal != null)
                            MealValueUnitText(
                              value: item.amount,
                              meal: item.meal!,
                              usesImperialUnits: usesImperialUnits,
                            )
                          else
                            Text('${numbers.format(item.amount)} '
                                '${_baseUnit(context, item.unit)}'),
                          Text(item.energyKcal == null
                              ? '—'
                              : EnergyDisplay.formatWithUnit(
                                  context, item.energyKcal!)),
                        ],
                      ),
                      if (item.meal == null)
                        Text(S.of(context).sharedMealUnavailableLabel),
                    ],
                  ),
                ),
              const Divider(),
              Wrap(
                spacing: Dimens.spacing16,
                children: [
                  Text(incomplete
                      ? S.of(context).sharedMealPartialTotalLabel
                      : S.of(context).sharedMealTotalLabel),
                  Text(EnergyDisplay.formatSumWithUnit(context, kcals)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        Semantics(
          identifier: 'import-meal-preview-import',
          child: TextButton(
            onPressed: available.isEmpty
                ? null
                : () => Navigator.of(context).pop(true),
            child: Text(S.of(context).importAction),
          ),
        ),
      ],
    );
  }

  /// Without the food we cannot tell its base unit from the meal, so derive
  /// it from the unit the amount was entered in.
  static String _baseUnit(BuildContext context, String unit) {
    switch (sharedBaseUnitOf(unit)) {
      case 'g':
        return S.of(context).gramUnit;
      case 'ml':
        return S.of(context).milliliterUnit;
      default:
        return S.of(context).gramMilliliterUnit;
    }
  }
}
