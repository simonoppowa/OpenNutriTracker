import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// One muted line under a search result's title: energy and protein /
/// carbs / fat per 100 g/ml, so foods with the same name can be told apart
/// without opening each one (#1285).
///
/// Always per 100 g/ml, never per the quantity the row shows: that figure
/// is the package size for Open Food Facts and the whole weight for a
/// recipe, so values for it would not compare across rows.
///
/// A value the food does not carry is left out rather than shown as 0, and
/// the line is left out entirely when the food carries none of them.
class MealMacrosLine extends StatelessWidget {
  final MealEntity meal;

  const MealMacrosLine({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final n = meal.nutriments;
    final kcal = _finite(n.energyKcal100);
    final protein = _finite(n.proteins100);
    final carbs = _finite(n.carbohydrates100);
    final fat = _finite(n.fat100);
    if (kcal == null && protein == null && carbs == null && fat == null) {
      return const SizedBox.shrink();
    }

    final s = S.of(context);
    // Nullable so a row pumped without the app's provider (tests, the
    // add-item sheet's previews) reads kcal instead of throwing.
    final useKj = context.watch<EnergyUnitProvider?>()?.usesKilojoules ?? false;
    final basis = '100 ${s.gramMilliliterUnit}';
    final energy = kcal == null
        ? null
        : '${(useKj ? UnitCalc.kcalToKj(kcal) : kcal).round()} '
              '${useKj ? s.kjLabel : s.kcalLabel}';

    final shown = [
      basis,
      ?energy,
      if (protein != null)
        '${s.proteinLabelShort.toUpperCase()} ${_oneDecimal(protein)}',
      if (carbs != null)
        '${s.carbsLabelShort.toUpperCase()} ${_oneDecimal(carbs)}',
      if (fat != null) '${s.fatLabelShort.toUpperCase()} ${_oneDecimal(fat)}',
    ].join(' · ');

    // Spoken with whole words: "P 30" reads as a letter and a number.
    final spoken = [
      ?energy,
      if (protein != null)
        '${s.proteinLabel} ${_oneDecimal(protein)} ${s.gramUnit}',
      if (carbs != null) '${s.carbsLabel} ${_oneDecimal(carbs)} ${s.gramUnit}',
      if (fat != null) '${s.fatLabel} ${_oneDecimal(fat)} ${s.gramUnit}',
    ].join(', ');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Padding(
      padding: const EdgeInsets.only(top: Dimens.spacing4),
      child: Semantics(
        label: '$basis: $spoken',
        excludeSemantics: true,
        child: Text(
          shown,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ),
    );
  }

  static double? _finite(double? value) =>
      value != null && value.isFinite ? value : null;

  /// One decimal, without a trailing ".0" — the bulk-add screen's format.
  static String _oneDecimal(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
