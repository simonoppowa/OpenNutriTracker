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

  /// The recipe's portions; with one or more the card also shows the values
  /// of one portion (#53).
  final int? servingsCount;

  const RecipeNutritionSummary({
    super.key,
    required this.nutrimentsPer100,
    required this.totalWeightG,
    this.servingsCount,
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
    final servings = servingsCount ?? 0;
    String summaryLine(String label, double grams) {
      final factor = grams / 100;
      final energyKcal = (nutrimentsPer100.energyKcal100 ?? 0) * factor;
      final energy = usesKilojoules ? UnitCalc.kcalToKj(energyKcal) : energyKcal;
      String macro(String short, double? per100) =>
          '${short.toUpperCase()} ${((per100 ?? 0) * factor).toStringAsFixed(1)}g';
      return '$label · '
          '${energy.toStringAsFixed(0)} $energyLabel · '
          '${macro(s.carbsLabelShort, nutrimentsPer100.carbohydrates100)} · '
          '${macro(s.fatLabelShort, nutrimentsPer100.fat100)} · '
          '${macro(s.proteinLabelShort, nutrimentsPer100.proteins100)}';
    }
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
              Expanded(
                child: _NutrientCell(
                  value: energyTotalDisplay,
                  label: energyLabel,
                  color: accent,
                  palette: palette,
                ),
              ),
              Expanded(
                child: _NutrientCell(
                  value: _total(nutrimentsPer100.carbohydrates100),
                  label: '${s.carbsLabel} g',
                  color: palette.carbs,
                  palette: palette,
                ),
              ),
              Expanded(
                child: _NutrientCell(
                  value: _total(nutrimentsPer100.fat100),
                  label: '${s.fatLabel} g',
                  color: palette.fat,
                  palette: palette,
                ),
              ),
              Expanded(
                child: _NutrientCell(
                  value: _total(nutrimentsPer100.proteins100),
                  label: '${s.proteinLabel} g',
                  color: palette.protein,
                  palette: palette,
                ),
              ),
            ],
          ),
          Divider(height: Dimens.spacing24 + Dimens.spacing8, color: palette.border),
          Text(
            summaryLine(s.recipeNutritionPer100Label, 100),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
          if (servings > 0) ...[
            const SizedBox(height: Dimens.spacing4),
            Text(
              summaryLine(
                s.recipeNutritionPerServingLabel(
                  (totalWeightG / servings).toStringAsFixed(0),
                ),
                totalWeightG / servings,
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
