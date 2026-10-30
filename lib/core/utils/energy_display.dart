import 'package:flutter/widgets.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Display-layer helpers for rendering energy values in either kcal or
/// kJ, depending on the user's setting (#177). Internal storage stays
/// in kcal everywhere — these helpers only translate at the point
/// values are shown.
class EnergyDisplay {
  /// Returns the localised energy unit suffix ("kcal" or "kJ").
  static String unitLabel(BuildContext context) {
    final useKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    return useKj ? S.of(context).kjLabel : S.of(context).kcalLabel;
  }

  /// Same as [unitLabel] but reads the provider without subscribing —
  /// safe to call from event handlers that don't need to rebuild on
  /// change.
  static String unitLabelStatic(BuildContext context) {
    final useKj =
        Provider.of<EnergyUnitProvider>(context, listen: false).usesKilojoules;
    return useKj ? S.of(context).kjLabel : S.of(context).kcalLabel;
  }

  /// Convert a stored kcal value into the display value for the
  /// currently-selected unit.
  static double convert(BuildContext context, double kcal) {
    final useKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    return useKj ? UnitCalc.kcalToKj(kcal) : kcal;
  }

  /// The whole number a stored kcal value shows as in the
  /// currently-selected unit. Rounded to nearest, not truncated, so the
  /// same value reads the same on every screen (#1469).
  static int displayValue(BuildContext context, double kcal) {
    return convert(context, kcal).round();
  }

  /// Format a stored kcal value as an integer string in the
  /// currently-selected unit (without the unit suffix).
  static String formatValue(BuildContext context, double kcal) {
    return displayValue(context, kcal).toString();
  }

  /// Convenience: format a stored kcal value as `"<value> <unit>"`.
  static String formatWithUnit(BuildContext context, double kcal) {
    return '${formatValue(context, kcal)} ${unitLabel(context)}';
  }

  /// The total under a list of rows that each show [kcals] through
  /// [formatWithUnit]: the sum of the rounded rows, so the figures on
  /// screen add up. Rounding the exact sum instead can drift from the
  /// rows by up to half a unit per row: 80.4 + 14.4 shows as "80" and
  /// "14", which this totals as "94" where the exact sum reads "95".
  static String formatSumWithUnit(
    BuildContext context,
    Iterable<double> kcals,
  ) {
    final sum = kcals.fold(0, (sum, kcal) => sum + displayValue(context, kcal));
    return '$sum ${unitLabel(context)}';
  }
}
