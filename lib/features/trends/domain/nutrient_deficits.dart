import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';

/// How often a micronutrient fell short over a period (#59).
class NutrientDeficit {
  /// The `NutrientPanelKeys` entry.
  final String key;
  final int deficitDays;

  /// The days the nutrient could be judged on: mostly known values and a
  /// reference.
  final int evaluatedDays;

  const NutrientDeficit({
    required this.key,
    required this.deficitDays,
    required this.evaluatedDays,
  });

  double get share => deficitDays / evaluatedDays;
}

/// The minerals and vitamins that most often stayed below [threshold] of
/// their reference, best [top] first by the share of days (#59).
///
/// A day counts when more of its entries gave a value for the nutrient than
/// did not: a day of mostly unknown values says nothing and is neither a
/// deficit nor judged. [referenceOf] gives the value the day's panel
/// measures against; limits such as sodium are never deficits.
List<NutrientDeficit> nutrientDeficits({
  required Map<DateTime, List<IntakeEntity>> intakesByDay,
  required double? Function(String key, DateTime day) referenceOf,
  double threshold = 0.7,
  int top = 5,
}) {
  final rows = NutrientPanelRow.all.where(
    (row) =>
        !row.excessMatters &&
        (row.group == NutrientPanelGroup.minerals ||
            row.group == NutrientPanelGroup.vitamins),
  );
  final deficits = <NutrientDeficit>[];
  for (final row in rows) {
    var judged = 0;
    var short = 0;
    for (final MapEntry(key: day, value: intakes) in intakesByDay.entries) {
      final total = NutrientTotal.over(
        intakes,
        per100: (intake) => row.field.per100(intake.meal.nutriments),
        amountG: (intake) => intake.amount,
      );
      if (total.knownEntries == 0 ||
          total.unknownEntries > total.knownEntries) {
        continue;
      }
      final reference = referenceOf(row.key, day);
      if (reference == null || reference <= 0) continue;
      judged++;
      if (total.sum < reference * threshold) short++;
    }
    if (short > 0) {
      deficits.add(
        NutrientDeficit(
          key: row.key,
          deficitDays: short,
          evaluatedDays: judged,
        ),
      );
    }
  }
  deficits.sort((a, b) {
    final byShare = b.share.compareTo(a.share);
    return byShare != 0 ? byShare : b.deficitDays.compareTo(a.deficitDays);
  });
  return deficits.take(top).toList();
}
