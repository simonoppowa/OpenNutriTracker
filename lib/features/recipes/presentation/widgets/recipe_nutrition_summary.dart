import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class RecipeNutritionSummary extends StatelessWidget {
  final MealNutrimentsEntity nutrimentsPer100;
  final double totalWeightG;

  const RecipeNutritionSummary({
    super.key,
    required this.nutrimentsPer100,
    required this.totalWeightG,
  });

  double _total(double? per100) {
    return (per100 ?? 0) * totalWeightG / 100;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = theme.colorScheme.primary;
    // #177: energy values are stored as kcal; only the rendering layer
    // applies the kJ conversion when the user has selected that unit.
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    final energyLabel = usesKilojoules ? s.kjLabel : s.kcalLabel;
    final energyTotalKcal = _total(nutrimentsPer100.energyKcal100);
    final energyTotalDisplay =
        usesKilojoules ? UnitCalc.kcalToKj(energyTotalKcal) : energyTotalKcal;
    final energyPer100Kcal = nutrimentsPer100.energyKcal100 ?? 0;
    final energyPer100Display = usesKilojoules
        ? UnitCalc.kcalToKj(energyPer100Kcal)
        : energyPer100Kcal;
    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.recipeNutritionPreviewLabel,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Dimens.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NutrientCell(
                value: energyTotalDisplay,
                label: energyLabel,
                color: accent,
                palette: palette,
              ),
              _NutrientCell(
                value: _total(nutrimentsPer100.carbohydrates100),
                label: '${s.carbsLabel} g',
                color: palette.carbs,
                palette: palette,
              ),
              _NutrientCell(
                value: _total(nutrimentsPer100.fat100),
                label: '${s.fatLabel} g',
                color: palette.fat,
                palette: palette,
              ),
              _NutrientCell(
                value: _total(nutrimentsPer100.proteins100),
                label: '${s.proteinLabel} g',
                color: palette.protein,
                palette: palette,
              ),
            ],
          ),
          Divider(height: Dimens.spacing24 + Dimens.spacing8, color: palette.border),
          Text(
            '${s.recipeNutritionPer100Label} · '
            '${energyPer100Display.toStringAsFixed(0)} $energyLabel · '
            '${s.carbsLabelShort.toUpperCase()} ${(nutrimentsPer100.carbohydrates100 ?? 0).toStringAsFixed(1)}g · '
            '${s.fatLabelShort.toUpperCase()} ${(nutrimentsPer100.fat100 ?? 0).toStringAsFixed(1)}g · '
            '${s.proteinLabelShort.toUpperCase()} ${(nutrimentsPer100.proteins100 ?? 0).toStringAsFixed(1)}g',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NutrientCell extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final AppPalette palette;

  const _NutrientCell({
    required this.value,
    required this.label,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
