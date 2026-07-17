import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealTitleExpanded extends StatelessWidget {
  final MealEntity meal;
  final bool usesImperialUnits;

  const MealTitleExpanded({
    super.key,
    required this.meal,
    required this.usesImperialUnits,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AutoSizeText.rich(
              minFontSize: 6,
              maxFontSize: 16,
              TextSpan(
                text: meal.name ?? '',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: palette.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                children: [
                  TextSpan(
                    text: ' ${meal.brands ?? ''}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Disclosure for unreviewed machine-translated food names from
            // the backend's translation table. The column is bottom-aligned
            // in the app bar's flexible space and this row is the last
            // visible child for backend foods (no package-quantity line),
            // so without the bottom padding it sits on the clipping edge
            // and gets cut off.
            if (meal.machineTranslatedName)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 12,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        S.of(context).machineTranslatedNameHint,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.textMuted,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            meal.mealQuantity != null
                ? Center(
                    child: MealValueUnitText(
                      value: double.tryParse(meal.mealQuantity ?? '') ?? 0,
                      meal: meal,
                      usesImperialUnits: usesImperialUnits,
                      textStyle:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: palette.textMuted,
                              ),
                      prefix: '',
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
