import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// #173: the daily micronutrient panel uses three nutrient references
/// that the user can override per day — fibre, saturated fat, and
/// sugars. When the per-day `TrackedDayEntity` carries a non-null
/// override the panel must respect it; when null (or when no entity is
/// present at all) it has to fall back to the default reference values
/// the panel exposes as static constants. The reporter on #173 was
/// explicit that this needs to work the same way carbs / fat / protein
/// already do, so the test is intentionally small and focused — it
/// exercises the resolver helpers the panel actually uses, rather than
/// rendering the widget tree.
void main() {
  TrackedDayEntity trackedDay({
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
  }) {
    return TrackedDayEntity(
      day: DateTime.utc(2026, 5, 13),
      calorieGoal: 2000,
      caloriesTracked: 0,
      fibreGoal: fibreGoal,
      satFatGoal: satFatGoal,
      sugarsGoal: sugarsGoal,
    );
  }

  group('DailyNutrientPanel goal resolution', () {
    test('falls back to default fibre reference when no tracked day', () {
      expect(
        DailyNutrientPanel.resolveFibreReference(null),
        DailyNutrientPanel.defaultFibreRefG,
      );
    });

    test('falls back to default fibre reference when goal is null', () {
      expect(
        DailyNutrientPanel.resolveFibreReference(trackedDay()),
        DailyNutrientPanel.defaultFibreRefG,
      );
    });

    test('uses user fibre goal when set on the tracked day', () {
      // A fibre target set higher than the default — common for people
      // following plant-forward diets where 30g is the floor, not the
      // ceiling.
      const userFibreGoal = 45.0;
      expect(
        DailyNutrientPanel.resolveFibreReference(
          trackedDay(fibreGoal: userFibreGoal),
        ),
        userFibreGoal,
      );
    });

    test('falls back to default saturated fat reference when null', () {
      expect(
        DailyNutrientPanel.resolveSatFatReference(null),
        DailyNutrientPanel.defaultSaturatedFatRefG,
      );
      expect(
        DailyNutrientPanel.resolveSatFatReference(trackedDay()),
        DailyNutrientPanel.defaultSaturatedFatRefG,
      );
    });

    test('uses user saturated fat goal when set on the tracked day', () {
      // A tighter cap — e.g. a clinician-suggested 13g for someone
      // managing cardiovascular risk.
      const userSatFatGoal = 13.0;
      expect(
        DailyNutrientPanel.resolveSatFatReference(
          trackedDay(satFatGoal: userSatFatGoal),
        ),
        userSatFatGoal,
      );
    });

    test('falls back to default sugars reference when null', () {
      expect(
        DailyNutrientPanel.resolveSugarsReference(null),
        DailyNutrientPanel.defaultSugarRefG,
      );
      expect(
        DailyNutrientPanel.resolveSugarsReference(trackedDay()),
        DailyNutrientPanel.defaultSugarRefG,
      );
    });

    test('uses user sugars goal when set on the tracked day', () {
      const userSugarsGoal = 25.0;
      expect(
        DailyNutrientPanel.resolveSugarsReference(
          trackedDay(sugarsGoal: userSugarsGoal),
        ),
        userSugarsGoal,
      );
    });

    test('resolves each nutrient independently', () {
      // Only fibre is overridden; sat fat and sugars must still fall
      // back to defaults rather than getting tangled together.
      final day = trackedDay(fibreGoal: 40);
      expect(DailyNutrientPanel.resolveFibreReference(day), 40);
      expect(
        DailyNutrientPanel.resolveSatFatReference(day),
        DailyNutrientPanel.defaultSaturatedFatRefG,
      );
      expect(
        DailyNutrientPanel.resolveSugarsReference(day),
        DailyNutrientPanel.defaultSugarRefG,
      );
    });
  });
}
