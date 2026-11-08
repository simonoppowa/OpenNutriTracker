import 'dart:convert';

import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';

/// The macro rows the widget shows under the ring, in grams. Grams are
/// what the home screen itself displays, and the macro goals already
/// arrive in grams (`GetMacroGoalUsecase`), so no unit conversion is
/// stored. The percentages are computed by the reader, not here.
class CalorieWidgetMacros {
  final int proteinIntakeG;
  final int proteinGoalG;
  final int carbsIntakeG;
  final int carbsGoalG;
  final int fatsIntakeG;
  final int fatsGoalG;

  const CalorieWidgetMacros({
    required this.proteinIntakeG,
    required this.proteinGoalG,
    required this.carbsIntakeG,
    required this.carbsGoalG,
    required this.fatsIntakeG,
    required this.fatsGoalG,
  });

  /// One value is one write ([CalorieWidgetSnapshot.storageKey]), so a
  /// reader either sees all three rows or none of them.
  Map<String, Object> toJson() => {
    'protein': {'g': proteinIntakeG, 'goalG': proteinGoalG},
    'carbs': {'g': carbsIntakeG, 'goalG': carbsGoalG},
    'fat': {'g': fatsIntakeG, 'goalG': fatsGoalG},
  };

  /// Reads the shape [toJson] wrote; older snapshots without a `macros`
  /// key read as null, so a reader falls back to the ring alone.
  static CalorieWidgetMacros? fromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;
    Map<String, Object?>? row(String name) {
      final row = value[name];
      return row is Map<String, Object?> ? row : null;
    }

    final protein = row('protein');
    final carbs = row('carbs');
    final fat = row('fat');
    if (protein == null || carbs == null || fat == null) return null;
    return CalorieWidgetMacros(
      proteinIntakeG: _nonNegative(protein['g']),
      proteinGoalG: _nonNegative(protein['goalG']),
      carbsIntakeG: _nonNegative(carbs['g']),
      carbsGoalG: _nonNegative(carbs['goalG']),
      fatsIntakeG: _nonNegative(fat['g']),
      fatsGoalG: _nonNegative(fat['goalG']),
    );
  }

  static int _nonNegative(Object? value) {
    final number = value is num ? value : 0;
    if (number.isNegative || !number.isFinite) return 0;
    return number.round();
  }

  @override
  bool operator ==(Object other) =>
      other is CalorieWidgetMacros &&
      other.proteinIntakeG == proteinIntakeG &&
      other.proteinGoalG == proteinGoalG &&
      other.carbsIntakeG == carbsIntakeG &&
      other.carbsGoalG == carbsGoalG &&
      other.fatsIntakeG == fatsIntakeG &&
      other.fatsGoalG == fatsGoalG;

  @override
  int get hashCode => Object.hash(
        proteinIntakeG,
        proteinGoalG,
        carbsIntakeG,
        carbsGoalG,
        fatsIntakeG,
        fatsGoalG,
      );
}

class CalorieWidgetSnapshot {
  /// Today's calorie figures for the iOS and Android home-screen widgets.
  ///
  /// The widget cannot open the encrypted Hive database, so the app writes
  /// this snapshot into the shared App Group (iOS) or the plugin's shared
  /// preferences (Android) whenever Home finishes loading. Kilocalories
  /// are the stored unit. The in-app kilojoule display preference is not
  /// applied here.

  static const appGroupId = 'group.com.opennutritracker.ont.opennutritracker';
  static const developAppGroupId =
      'group.com.opennutritracker.ont.opennutritracker.develop';
  static const iosWidgetKind = 'CalorieProgressWidget';
  /// The Android `AppWidgetProvider`, as its fully qualified source class
  /// name. The plugin's `androidName` would resolve against the running
  /// application id instead, which carries the develop flavour's `.develop`
  /// suffix while the class does not — so the qualified name is what is
  /// passed, and it is identical for both flavours.
  static const androidWidgetQualifiedName =
      'com.opennutritracker.ont.opennutritracker.CalorieWidgetProvider';

  /// The App Group key the snapshot lives under: the figures and the
  /// labels that describe them, as one JSON string. One key is one platform
  /// write, so the extension reads either the old snapshot or the new one,
  /// never a mix of the two.
  static const storageKey = 'ont_calorie_snapshot';

  final bool hasData;
  final String dayId;
  final int offsetMinutes;
  final int consumedKcal;
  final int goalKcal;

  /// Null when Home had no macro figures, or when the snapshot was
  /// decoded from an older write.
  final CalorieWidgetMacros? macros;

  const CalorieWidgetSnapshot({
    required this.hasData,
    required this.dayId,
    required this.offsetMinutes,
    required this.consumedKcal,
    required this.goalKcal,
    this.macros,
  });

  /// Builds the snapshot Home should publish.
  ///
  /// [consumedKcal] is today's supplied intake and [goalKcal] is the
  /// daily goal, both already computed by Home. A goal of zero, or a
  /// negative goal, means there is no profile figure to show.
  ///
  /// [logicalDay] is the day the figures were read for. Home passes the
  /// one its load started on, so a load that crosses the day boundary does
  /// not stamp the old day's figures with the new day. Without it, the
  /// logical day of [now] is used.
  factory CalorieWidgetSnapshot.fromHome({
    required double consumedKcal,
    required double goalKcal,
    required int offsetMinutes,
    CalorieWidgetMacros? macros,
    DateTime? logicalDay,
    DateTime? now,
  }) {
    final offset = sanitiseOffsetMinutes(offsetMinutes);
    final day =
        logicalDay ??
        DayBoundaryCalc.logicalDayOfMinutes(now ?? DateTime.now(), offset);
    final goal = goalKcal.round();
    final hasData = goal > 0;
    return CalorieWidgetSnapshot(
      hasData: hasData,
      dayId: formatDayId(day),
      offsetMinutes: offset,
      consumedKcal: hasData ? consumedKcal.round() : 0,
      goalKcal: hasData ? goal : 0,
      macros: hasData ? macros : null,
    );
  }

  /// True when this snapshot still belongs to the logical day of [moment].
  bool isCurrentAt(DateTime moment) {
    if (!hasData || dayId.isEmpty) return false;
    final logicalDay = DayBoundaryCalc.logicalDayOfMinutes(
      moment,
      offsetMinutes,
    );
    return dayId == formatDayId(logicalDay);
  }

  /// Wall-clock instant when this logical day ends and the widget should
  /// drop yesterday's numbers.
  DateTime nextBoundary() {
    final parts = dayId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final start = DateTime(year, month, day);
    return start.add(Duration(days: 1, minutes: offsetMinutes));
  }

  Map<String, Object> toJson() => {
    'hasData': hasData,
    'day': dayId,
    'offsetMinutes': offsetMinutes,
    'consumed': consumedKcal,
    'goal': goalKcal,
    // Omitted rather than null, so older readers (the iOS extension
    // today) decode the same snapshot without knowing about it.
    if (macros != null) 'macros': macros!.toJson(),
  };

  /// The value stored under [storageKey]: this snapshot with the figure
  /// labels in [labels].
  String encode(CalorieWidgetLabels labels) =>
      jsonEncode({...toJson(), 'labels': labels.figureJson()});

  /// The App Group for the build with [bundleId]. The develop flavour has
  /// its own bundle id and its own group, so a develop install next to the
  /// App Store build can never overwrite or clear that build's widget. It
  /// must agree with `ONT_APP_GROUP_ID` in the Xcode project.
  static String appGroupIdFor(String bundleId) =>
      bundleId.endsWith('.develop') ? developAppGroupId : appGroupId;

  static int sanitiseOffsetMinutes(int offsetMinutes) {
    if (offsetMinutes < 0 || offsetMinutes >= 24 * 60) return 0;
    return offsetMinutes;
  }

  static String formatDayId(DateTime day) {
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayOfMonth';
  }
}
