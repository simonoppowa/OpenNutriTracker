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

  /// Format a stored kcal value as an integer string in the
  /// currently-selected unit (without the unit suffix).
  static String formatValue(BuildContext context, double kcal) {
    return convert(context, kcal).toInt().toString();
  }

  /// Convenience: format a stored kcal value as `"<value> <unit>"`.
  static String formatWithUnit(BuildContext context, double kcal) {
    return '${formatValue(context, kcal)} ${unitLabel(context)}';
  }
}
