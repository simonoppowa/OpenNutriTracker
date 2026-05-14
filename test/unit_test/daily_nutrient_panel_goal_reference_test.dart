import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// #173 (+follow-up): the daily micronutrient panel uses ten nutrient
/// references the user can override per day. The original commit
/// covered fibre, saturated fat, and sugars; the follow-up extends the
/// same pattern to sodium, calcium, iron, potassium, vitamin D,
/// vitamin B12, and magnesium. When the per-day `TrackedDayEntity`
/// carries a non-null override the panel must respect it; when null
/// (or when no entity is present at all) it has to fall back to the
/// default reference values the panel exposes as static constants.
/// The test exercises the resolver helpers the panel actually uses
/// rather than rendering the widget tree, which keeps it both quick
/// and immune to layout churn.
void main() {
  TrackedDayEntity trackedDay({
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
    double? sodiumGoal,
    double? calciumGoal,
    double? ironGoal,
    double? potassiumGoal,
    double? vitaminDGoal,
    double? vitaminB12Goal,
    double? magnesiumGoal,
  }) {
    return TrackedDayEntity(
      day: DateTime.utc(2026, 5, 13),
      calorieGoal: 2000,
      caloriesTracked: 0,
      fibreGoal: fibreGoal,
      satFatGoal: satFatGoal,
      sugarsGoal: sugarsGoal,
      sodiumGoal: sodiumGoal,
      calciumGoal: calciumGoal,
      ironGoal: ironGoal,
      potassiumGoal: potassiumGoal,
      vitaminDGoal: vitaminDGoal,
      vitaminB12Goal: vitaminB12Goal,
      magnesiumGoal: magnesiumGoal,
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

  // Follow-up to #173: same expectations, applied to the remaining
  // seven nutrients. Each one falls back to its default when the goal
  // field is null and uses the override otherwise.
  group('DailyNutrientPanel goal resolution (follow-up nutrients)', () {
    test('falls back to default sodium reference when null', () {
      expect(
        DailyNutrientPanel.resolveSodiumReference(null),
        DailyNutrientPanel.defaultSodiumRefMg,
      );
      expect(
        DailyNutrientPanel.resolveSodiumReference(trackedDay()),
        DailyNutrientPanel.defaultSodiumRefMg,
      );
    });

    test('uses user sodium goal when set on the tracked day', () {
      // A tighter cap — e.g. 1500mg as recommended for adults managing
      // blood pressure.
      const userSodiumGoal = 1500.0;
      expect(
        DailyNutrientPanel.resolveSodiumReference(
          trackedDay(sodiumGoal: userSodiumGoal),
        ),
        userSodiumGoal,
      );
    });

    test('falls back to default calcium reference when null', () {
      expect(
        DailyNutrientPanel.resolveCalciumReference(null),
        DailyNutrientPanel.defaultCalciumRefMg,
      );
      expect(
        DailyNutrientPanel.resolveCalciumReference(trackedDay()),
        DailyNutrientPanel.defaultCalciumRefMg,
      );
    });

    test('uses user calcium goal when set on the tracked day', () {
      const userCalciumGoal = 1200.0;
      expect(
        DailyNutrientPanel.resolveCalciumReference(
          trackedDay(calciumGoal: userCalciumGoal),
        ),
        userCalciumGoal,
      );
    });

    test('falls back to gender-aware iron default when goal is null', () {
      // The caller supplies the gender-based default so the helper
      // stays pure — passing 18 here simulates the female fallback.
      expect(
        DailyNutrientPanel.resolveIronReference(null, 18.0),
        18.0,
      );
      expect(
        DailyNutrientPanel.resolveIronReference(trackedDay(), 8.0),
        8.0,
      );
    });

    test('uses user iron goal when set on the tracked day', () {
      // Iron supplementation for someone managing anaemia — a value
      // well above the standard DRI.
      const userIronGoal = 27.0;
      expect(
        DailyNutrientPanel.resolveIronReference(
          trackedDay(ironGoal: userIronGoal),
          // Gender default is passed through but ignored when the
          // goal is non-null.
          8.0,
        ),
        userIronGoal,
      );
    });

    test('falls back to default potassium reference when null', () {
      expect(
        DailyNutrientPanel.resolvePotassiumReference(null),
        DailyNutrientPanel.defaultPotassiumRefMg,
      );
      expect(
        DailyNutrientPanel.resolvePotassiumReference(trackedDay()),
        DailyNutrientPanel.defaultPotassiumRefMg,
      );
    });

    test('uses user potassium goal when set on the tracked day', () {
      const userPotassiumGoal = 4700.0;
      expect(
        DailyNutrientPanel.resolvePotassiumReference(
          trackedDay(potassiumGoal: userPotassiumGoal),
        ),
        userPotassiumGoal,
      );
    });

    test('falls back to default vitamin D reference when null', () {
      expect(
        DailyNutrientPanel.resolveVitaminDReference(null),
        DailyNutrientPanel.defaultVitaminDRefUg,
      );
      expect(
        DailyNutrientPanel.resolveVitaminDReference(trackedDay()),
        DailyNutrientPanel.defaultVitaminDRefUg,
      );
    });

    test('uses user vitamin D goal when set on the tracked day', () {
      // A higher target — e.g. 25µg as sometimes prescribed for
      // people with low baseline vitamin D status.
      const userVitaminDGoal = 25.0;
      expect(
        DailyNutrientPanel.resolveVitaminDReference(
          trackedDay(vitaminDGoal: userVitaminDGoal),
        ),
        userVitaminDGoal,
      );
    });

    test('falls back to default vitamin B12 reference when null', () {
      expect(
        DailyNutrientPanel.resolveVitaminB12Reference(null),
        DailyNutrientPanel.defaultVitaminB12RefUg,
      );
      expect(
        DailyNutrientPanel.resolveVitaminB12Reference(trackedDay()),
        DailyNutrientPanel.defaultVitaminB12RefUg,
      );
    });

    test('uses user vitamin B12 goal when set on the tracked day', () {
      const userVitaminB12Goal = 5.0;
      expect(
        DailyNutrientPanel.resolveVitaminB12Reference(
          trackedDay(vitaminB12Goal: userVitaminB12Goal),
        ),
        userVitaminB12Goal,
      );
    });

    test('falls back to default magnesium reference when null', () {
      expect(
        DailyNutrientPanel.resolveMagnesiumReference(null),
        DailyNutrientPanel.defaultMagnesiumRefMg,
      );
      expect(
        DailyNutrientPanel.resolveMagnesiumReference(trackedDay()),
        DailyNutrientPanel.defaultMagnesiumRefMg,
      );
    });

    test('uses user magnesium goal when set on the tracked day', () {
      const userMagnesiumGoal = 500.0;
      expect(
        DailyNutrientPanel.resolveMagnesiumReference(
          trackedDay(magnesiumGoal: userMagnesiumGoal),
        ),
        userMagnesiumGoal,
      );
    });

    test('resolves each follow-up nutrient independently', () {
      // Only sodium is overridden. Every other follow-up nutrient
      // must still fall back to its own default rather than picking
      // up the sodium value.
      final day = trackedDay(sodiumGoal: 1500);
      expect(DailyNutrientPanel.resolveSodiumReference(day), 1500);
      expect(
        DailyNutrientPanel.resolveCalciumReference(day),
        DailyNutrientPanel.defaultCalciumRefMg,
      );
      // Iron's gender-aware default is supplied by the caller; passing
      // 14 here simulates the non-binary / unknown fallback path.
      expect(DailyNutrientPanel.resolveIronReference(day, 14.0), 14.0);
      expect(
        DailyNutrientPanel.resolvePotassiumReference(day),
        DailyNutrientPanel.defaultPotassiumRefMg,
      );
      expect(
        DailyNutrientPanel.resolveMagnesiumReference(day),
        DailyNutrientPanel.defaultMagnesiumRefMg,
      );
      expect(
        DailyNutrientPanel.resolveVitaminDReference(day),
        DailyNutrientPanel.defaultVitaminDRefUg,
      );
      expect(
        DailyNutrientPanel.resolveVitaminB12Reference(day),
        DailyNutrientPanel.defaultVitaminB12RefUg,
      );
    });
  });
}
