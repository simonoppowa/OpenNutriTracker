import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// One tracked nutrient for the nutrient widget: today's amount and its
/// goal, in the nutrient's own unit. The id is the key the nutrient panel
/// already uses ([NutrientPanelKeys]), so a stored choice stays valid.
///
/// The in-app unit preferences are not applied here, just as the kilojoule
/// preference is not applied to the calories. A nutrient has one unit in
/// the app (grams, milligrams or micrograms), so [unit] is that string.
class CalorieWidgetNutrient {
  final String id;
  final double consumed;

  /// Null when there is no goal to compare with. The widget then shows the
  /// amount alone, with no ring.
  final double? goal;
  final String unit;

  const CalorieWidgetNutrient({
    required this.id,
    required this.consumed,
    this.goal,
    required this.unit,
  });

  /// The goal key is left out when there is no goal, so a reader never
  /// sees a null where it expects a number.
  Map<String, Object> toJson() => {
    'id': id,
    'consumed': consumed,
    'goal': ?goal,
    'unit': unit,
  };

  /// Reads the shape [toJson] wrote. An entry without an id, an amount or
  /// a unit is not a nutrient and reads as null, as does anything that is
  /// not a map. A goal of zero or less reads as no goal.
  static CalorieWidgetNutrient? fromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final id = value['id'];
    final consumed = value['consumed'];
    final unit = value['unit'];
    if (id is! String || id.isEmpty) return null;
    if (consumed is! num || unit is! String || unit.isEmpty) return null;
    final goal = value['goal'];
    return CalorieWidgetNutrient.normalised(
      id: id,
      consumed: consumed,
      goal: goal is num ? goal : null,
      unit: unit,
    );
  }

  /// A nutrient with its figures made safe to store: one decimal place,
  /// a negative or non-finite amount as zero, and a goal of zero or less,
  /// or a non-finite one, as no goal.
  factory CalorieWidgetNutrient.normalised({
    required String id,
    required num consumed,
    num? goal,
    required String unit,
  }) => CalorieWidgetNutrient(
    id: id,
    consumed: consumed.isFinite && !consumed.isNegative ? _round(consumed) : 0,
    goal: goal != null && goal.isFinite && goal > 0 ? _round(goal) : null,
    unit: unit,
  );

  /// Reads a stored `nutrients` list. Older snapshots have none and read
  /// as empty, and an entry that cannot be read is skipped, not fatal.
  static List<CalorieWidgetNutrient> listFromJson(Object? value) {
    if (value is! List<Object?>) return const [];
    return [for (final entry in value) ?fromJson(entry)];
  }

  static double _round(num value) => (value * 10).round() / 10;

  @override
  bool operator ==(Object other) =>
      other is CalorieWidgetNutrient &&
      other.id == id &&
      other.consumed == consumed &&
      other.goal == goal &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(id, consumed, goal, unit);

  @override
  String toString() => 'CalorieWidgetNutrient($id $consumed/$goal $unit)';
}

/// The ids of the nutrients the widget offers that the snapshot already
/// carries as top-level figures: calories, and the three macros. Every
/// other id is a [NutrientPanelKeys] key and travels in the `nutrients`
/// list.
class CalorieWidgetNutrientIds {
  CalorieWidgetNutrientIds._();

  static const String calories = 'calories';
  static const String protein = 'protein';
  static const String carbs = 'carbs';
  static const String fat = 'fat';
}

/// Builds the nutrient list Home publishes, from what the nutrient panel
/// already reads: the day's intakes, the person's own goals, and the
/// panel's show or hide choices. It adds no read of the intakes.
class CalorieWidgetNutrients {
  CalorieWidgetNutrients._();

  /// The unit the panel prints for each key.
  static const Map<String, String> units = {
    NutrientPanelKeys.fiber: 'g',
    NutrientPanelKeys.sodium: 'mg',
    NutrientPanelKeys.saturatedFat: 'g',
    NutrientPanelKeys.sugar: 'g',
    NutrientPanelKeys.calcium: 'mg',
    NutrientPanelKeys.iron: 'mg',
    NutrientPanelKeys.potassium: 'mg',
    NutrientPanelKeys.vitaminD: 'µg',
    NutrientPanelKeys.vitaminB12: 'µg',
    NutrientPanelKeys.magnesium: 'mg',
  };

  /// The panel nutrients that are visible, in the panel's order. A
  /// nutrient the person hid is left out, so the widget never shows a
  /// figure the app itself hides. Anything missing from [visibility] is
  /// visible, as in the panel.
  ///
  /// The goal is the one the panel shows: the day's own goal, else the
  /// reference for [user], else the published default.
  static List<CalorieWidgetNutrient> forDay({
    required List<IntakeEntity> intakes,
    required Map<String, bool> visibility,
    UserEntity? user,
    TrackedDayEntity? trackedDay,
  }) {
    final totals = NutrientPanelTotals.fromIntakes(intakes);
    double consumedOf(String key) => switch (key) {
      NutrientPanelKeys.fiber => totals.fiberG,
      NutrientPanelKeys.sodium => totals.sodiumMg,
      NutrientPanelKeys.saturatedFat => totals.saturatedFatG,
      NutrientPanelKeys.sugar => totals.sugarG,
      NutrientPanelKeys.calcium => totals.calciumMg,
      NutrientPanelKeys.iron => totals.ironMg,
      NutrientPanelKeys.potassium => totals.potassiumMg,
      NutrientPanelKeys.vitaminD => totals.vitaminDMcg,
      NutrientPanelKeys.vitaminB12 => totals.vitaminB12Mcg,
      _ => totals.magnesiumMg,
    };

    return [
      for (final key in NutrientPanelKeys.all)
        if (visibility[key] ?? true)
          CalorieWidgetNutrient.normalised(
            id: key,
            consumed: consumedOf(key),
            goal: DailyNutrientPanel.referenceFor(key, user, trackedDay),
            unit: units[key]!,
          ),
    ];
  }
}
