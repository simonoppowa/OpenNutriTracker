import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';
import 'package:opennutritracker/features/add_meal/presentation/nutrient_field_label.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Every nutrient of a recipe per 100 g and, with portions, per portion
/// (#54). A value some ingredients lack reads "≥ x" with the number of
/// those ingredients, one none of them has reads "—". The micronutrients
/// show only with the "Show micronutrients" setting, as in the meal detail.
class RecipeNutrientsTable extends StatelessWidget {
  /// Per nutrient, the ingredients' sum and how many gave no value
  /// (`ComputeRecipeNutritionUseCase.coverage`).
  final Map<NutrientField, NutrientTotal> coverage;
  final double totalWeightG;
  final int? servingsCount;
  final bool showMicronutrients;

  const RecipeNutrientsTable({
    super.key,
    required this.coverage,
    required this.totalWeightG,
    required this.servingsCount,
    required this.showMicronutrients,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final servings = servingsCount ?? 0;
    final portionG = servings > 0 ? totalWeightG / servings : null;
    final columnsG = [100.0, ?portionG];
    final strong =
        theme.textTheme.bodyMedium?.copyWith(color: palette.textStrong) ??
        const TextStyle();
    final muted =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textMuted,
        ) ??
        const TextStyle();

    String format(NutrientField field, double grams) {
      final total = coverage[field]!;
      if (total.valueOrNull == null || totalWeightG <= 0) return '—';
      final value = total.sum * grams / totalWeightG;
      final text = field == NutrientField.energyKcal
          ? EnergyDisplay.formatWithUnit(context, value)
          : '${value.roundToPrecision(2)}${field.unit}';
      return total.isPartial ? '≥ $text' : text;
    }

    TableRow row((NutrientField, bool) entry) {
      final (field, indented) = entry;
      final unknown = coverage[field]!.unknownEntries;
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${indented ? '   ' : ''}${field.label(s)}',
                  style: strong,
                ),
                if (coverage[field]!.isPartial)
                  Text(
                    s.recipeIngredientsWithoutValueHint(unknown),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          for (final grams in columnsG)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
              child: Text(
                format(field, grams),
                style: strong,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      );
    }

    Widget table(List<TableRow> rows) => AppCard(
      color: palette.surfaceMuted,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing8,
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: FlexColumnWidth(1.6)},
        border: TableBorder(
          horizontalInside: BorderSide(
            color: palette.border,
            width: Dimens.hairline,
          ),
        ),
        children: rows,
      ),
    );

    final header = TableRow(
      children: [
        const SizedBox.shrink(),
        for (final label in [
          s.recipeNutritionPer100Label,
          if (portionG != null)
            s.recipeNutritionPerServingLabel(portionG.toStringAsFixed(0)),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.spacing12),
            child: Text(label, style: muted, textAlign: TextAlign.right),
          ),
      ],
    );
    final hasMicroData = MealDetailNutrimentsTable.microRows.any(
      (entry) => coverage[entry.$1]!.valueOrNull != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.nutritionInfoLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Dimens.spacing8),
        table([
          header,
          for (final entry in MealDetailNutrimentsTable.mainRows) row(entry),
        ]),
        if (showMicronutrients) ...[
          const SizedBox(height: Dimens.spacing8),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                s.micronutrientsLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              initiallyExpanded: hasMicroData,
              children: [
                table([
                  header,
                  for (final entry in MealDetailNutrimentsTable.microRows)
                    row(entry),
                ]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
