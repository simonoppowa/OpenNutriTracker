import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/presentation/widgets/empty_hint.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/home/domain/entity/nutrient_contribution_entity.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Which of today's foods a macro total on the dashboard came from (#1266):
/// the total against its goal, then each food from the most to the least.
/// Tapping a food opens its details.
class NutrientContributionsScreen extends StatelessWidget {
  final MacroNutrient nutrient;
  final List<IntakeEntity> intakes;
  final double total;
  final double goal;

  /// The day and units a food's details open with.
  final DateTime day;
  final bool usesImperialUnits;

  const NutrientContributionsScreen({
    super.key,
    required this.nutrient,
    required this.intakes,
    required this.total,
    required this.goal,
    required this.day,
    this.usesImperialUnits = false,
  });

  static String nutrientLabel(BuildContext context, MacroNutrient nutrient) =>
      switch (nutrient) {
        MacroNutrient.carbs => S.of(context).carbsLabel,
        MacroNutrient.fat => S.of(context).fatLabel,
        MacroNutrient.protein => S.of(context).proteinLabel,
      };

  static String _mealLabel(BuildContext context, IntakeTypeEntity meal) =>
      switch (meal) {
        IntakeTypeEntity.breakfast => S.of(context).breakfastLabel,
        IntakeTypeEntity.lunch => S.of(context).lunchLabel,
        IntakeTypeEntity.dinner => S.of(context).dinnerLabel,
        IntakeTypeEntity.snack => S.of(context).snackLabel,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final color = switch (nutrient) {
      MacroNutrient.carbs => palette.carbs,
      MacroNutrient.fat => palette.fat,
      MacroNutrient.protein => palette.protein,
    };
    final label = nutrientLabel(context, nutrient);
    final contributions = NutrientContributionEntity.fromIntakes(
      intakes,
      nutrient,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nutrientContributionsTitle(label))),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.spacing16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(Dimens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Truncated as the dashboard tile shows them, so the two agree.
                  l10n.nutrientContributionsTotal(
                    total.toInt().toString(),
                    goal.toInt().toString(),
                  ),
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: Dimens.spacing12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal <= 0 ? 0 : (total / goal).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: palette.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          if (contributions.isEmpty)
            EmptyHint(
              icon: Icons.pie_chart_outline_rounded,
              title: l10n.nutrientContributionsEmpty(label),
            ),
          for (final contribution in contributions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pushNamed(
                NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  contribution.meal,
                  contribution.meals.first,
                  day,
                  usesImperialUnits,
                ),
              ),
              title: Text(contribution.name),
              subtitle: Text(
                [
                  contribution.meals
                      .map((meal) => _mealLabel(context, meal))
                      .join(', '),
                  if (contribution.brands?.isNotEmpty ?? false)
                    contribution.brands!,
                ].join(' · '),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    contribution.grams < 0.5
                        ? '<1 g'
                        : '${contribution.grams.round()} g',
                    style: textTheme.titleMedium,
                  ),
                  if (total > 0)
                    Text(
                      '${(100 * contribution.grams / total).round()}%',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
