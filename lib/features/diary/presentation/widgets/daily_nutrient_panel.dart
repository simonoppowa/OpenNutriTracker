import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Daily micronutrient summary that aggregates the seven nutrients reporters
/// keep asking for — fibre, sodium, saturated fat, sugar, calcium, iron,
/// potassium — across the day's intake list and renders each as a
/// "value / reference" row with a small progress bar.
///
/// The references are sensible DRIs for an average adult (FDA Daily Values
/// where applicable). Iron's reference is gender-aware because the gap
/// between female (18mg) and male (8mg) DRIs is large enough that a single
/// number would mislead one group or the other.
///
/// Computation is on the fly from [intakes] — no DBO migration, no extra
/// persistence. PR #314 added the per-meal micronutrient fields on
/// [MealNutrimentsDBO]; this widget simply sums them.
///
/// #173 (+follow-up): every nutrient reference on the panel can be
/// overridden per day via [trackedDay]. When the entity carries a
/// non-null goal field, the panel uses the user's configured target
/// instead of the built-in default. The first commit covered fibre /
/// saturated fat / sugars; the follow-up extends the same pattern to
/// sodium, calcium, iron, potassium, vitamin D, vitamin B12, and
/// magnesium. The vitamin D / B12 / magnesium rows themselves only
/// appear once #160's expansion follow-up rebases through, but the
/// resolver helpers and constants are wired here ready for that.
class DailyNutrientPanel extends StatelessWidget {
  // Default reference values exposed as static so the test (and future
  // callers) can assert the fallback without re-declaring magic numbers.
  static const double defaultFibreRefG = 30.0;
  static const double defaultSaturatedFatRefG = 20.0;
  static const double defaultSugarRefG = 50.0;
  static const double defaultSodiumRefMg = 2300.0;
  static const double defaultCalciumRefMg = 1000.0;
  static const double defaultPotassiumRefMg = 3500.0;
  // Vitamin D, B12, magnesium — defaults chosen to align with the
  // expansion follow-up so the rows render consistently once that
  // branch rebases through.
  static const double defaultVitaminDRefUg = 15.0;
  static const double defaultVitaminB12RefUg = 2.4;
  static const double defaultMagnesiumRefMg = 400.0;

  final List<IntakeEntity> intakes;
  final TrackedDayEntity? trackedDay;

  const DailyNutrientPanel({
    super.key,
    required this.intakes,
    this.trackedDay,
  });

  /// #173: resolve the reference value for fibre, taking the user's
  /// per-day override into account when present. Exposed as a static so
  /// the test can drive it without spinning up a widget.
  static double resolveFibreReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.fibreGoal ?? defaultFibreRefG;

  /// #173: resolve the reference value for saturated fat.
  static double resolveSatFatReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.satFatGoal ?? defaultSaturatedFatRefG;

  /// #173: resolve the reference value for sugars.
  static double resolveSugarsReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.sugarsGoal ?? defaultSugarRefG;

  /// Follow-up to #173: resolve sodium reference (mg).
  static double resolveSodiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.sodiumGoal ?? defaultSodiumRefMg;

  /// Follow-up to #173: resolve calcium reference (mg).
  static double resolveCalciumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.calciumGoal ?? defaultCalciumRefMg;

  /// Follow-up to #173: resolve iron reference (mg). Falls back to the
  /// gender-aware DRI when no override is set; the caller passes the
  /// gender-based default in so the helper itself stays pure.
  static double resolveIronReference(
    TrackedDayEntity? trackedDay,
    double genderDefault,
  ) =>
      trackedDay?.ironGoal ?? genderDefault;

  /// Follow-up to #173: resolve potassium reference (mg).
  static double resolvePotassiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.potassiumGoal ?? defaultPotassiumRefMg;

  /// Follow-up to #173: resolve vitamin D reference (µg). Only renders
  /// once the panel expansion follow-up adds the row.
  static double resolveVitaminDReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.vitaminDGoal ?? defaultVitaminDRefUg;

  /// Follow-up to #173: resolve vitamin B12 reference (µg).
  static double resolveVitaminB12Reference(TrackedDayEntity? trackedDay) =>
      trackedDay?.vitaminB12Goal ?? defaultVitaminB12RefUg;

  /// Follow-up to #173: resolve magnesium reference (mg).
  static double resolveMagnesiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.magnesiumGoal ?? defaultMagnesiumRefMg;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserEntity?>(
      future: _maybeGetUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return _buildPanel(context, user);
      },
    );
  }

  Future<UserEntity?> _maybeGetUser() async {
    try {
      return await locator<GetUserUsecase>().getUserData();
    } catch (_) {
      // If the user data isn't available (e.g. in tests or pre-onboarding),
      // fall back to the gender-neutral defaults below.
      return null;
    }
  }

  Widget _buildPanel(BuildContext context, UserEntity? user) {
    // Aggregate per-100g values into totals using the same pattern the rest of
    // the app uses: amount × (value100 / 100).
    final fiberG = _sum((n) => n.fiber100, intakes);
    final sodiumMg = _sum((n) => n.sodium100, intakes);
    final saturatedFatG = _sum((n) => n.saturatedFat100, intakes);
    final sugarG = _sum((n) => n.sugars100, intakes);
    final calciumMg = _sum((n) => n.calcium100, intakes);
    final ironMg = _sum((n) => n.iron100, intakes);
    final potassiumMg = _sum((n) => n.potassium100, intakes);

    // #173 (+follow-up): every nutrient reference picks up the per-day
    // override when one is set; otherwise it falls back to the built-in
    // default. Iron's fallback stays gender-aware — the user can still
    // override that explicitly via the slider.
    final fiberRefG = resolveFibreReference(trackedDay);
    final saturatedFatRefG = resolveSatFatReference(trackedDay);
    final sugarRefG = resolveSugarsReference(trackedDay);
    final sodiumRefMg = resolveSodiumReference(trackedDay);
    final calciumRefMg = resolveCalciumReference(trackedDay);
    final ironRefMg =
        resolveIronReference(trackedDay, _ironRefForGender(user?.gender));
    final potassiumRefMg = resolvePotassiumReference(trackedDay);

    final s = S.of(context);
    final rows = <Widget>[
      _NutrientRow(
        label: s.fiberLabel,
        value: fiberG,
        reference: fiberRefG,
        unit: 'g',
        excessMatters: false,
      ),
      _NutrientRow(
        label: s.sodiumLabel,
        value: sodiumMg,
        reference: sodiumRefMg,
        unit: 'mg',
        excessMatters: true,
      ),
      _NutrientRow(
        label: s.saturatedFatLabel,
        value: saturatedFatG,
        reference: saturatedFatRefG,
        unit: 'g',
        excessMatters: true,
      ),
      _NutrientRow(
        label: s.sugarLabel,
        value: sugarG,
        reference: sugarRefG,
        unit: 'g',
        excessMatters: true,
      ),
      _NutrientRow(
        label: s.calciumLabel,
        value: calciumMg,
        reference: calciumRefMg,
        unit: 'mg',
        excessMatters: false,
      ),
      _NutrientRow(
        label: s.ironLabel,
        value: ironMg,
        reference: ironRefMg,
        unit: 'mg',
        excessMatters: false,
      ),
      _NutrientRow(
        label: s.potassiumLabel,
        value: potassiumMg,
        reference: potassiumRefMg,
        unit: 'mg',
        excessMatters: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.diaryNutrientPanelTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8.0),
          ...rows,
        ],
      ),
    );
  }

  static double _sum(
    double? Function(MealNutrimentsEntity n) selector,
    List<IntakeEntity> list,
  ) {
    return list.fold<double>(0, (running, intake) {
      final per100 = selector(intake.meal.nutriments);
      if (per100 == null) return running;
      return running + intake.amount * per100 / 100.0;
    });
  }

  static double _ironRefForGender(UserGenderEntity? gender) {
    switch (gender) {
      case UserGenderEntity.female:
        return 18.0;
      case UserGenderEntity.male:
        return 8.0;
      case UserGenderEntity.nonBinary:
      case null:
        return 14.0;
    }
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final double value;
  final double reference;
  final String unit;

  /// Whether going over the reference is a problem (sodium, saturated fat,
  /// sugar) versus simply not meeting a target (fibre, calcium, iron,
  /// potassium). Affects the colour the bar turns when the user goes over.
  final bool excessMatters;

  const _NutrientRow({
    required this.label,
    required this.value,
    required this.reference,
    required this.unit,
    required this.excessMatters,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = reference > 0 ? value / reference : 0.0;
    final clamped = ratio.clamp(0.0, 1.0).toDouble();
    final color = _colorForRatio(context, ratio);
    final valueLabel = '${value.toStringAsFixed(value >= 10 ? 0 : 1)}'
        ' / ${reference.toStringAsFixed(reference >= 10 ? 0 : 1)}$unit';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6.0,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRatio(BuildContext context, double ratio) {
    final scheme = Theme.of(context).colorScheme;
    if (excessMatters) {
      // Sodium / saturated fat / sugar: amber as you approach the reference,
      // red once you cross it, green while comfortably below.
      if (ratio >= 1.0) return scheme.error;
      if (ratio >= 0.8) return Colors.amber.shade700;
      return scheme.primary;
    } else {
      // Fibre / calcium / iron / potassium: amber while still well short of
      // the reference, primary green once you reach it. Going over isn't a
      // concern at these values from food alone.
      if (ratio >= 1.0) return scheme.primary;
      if (ratio >= 0.5) return Colors.amber.shade700;
      return scheme.primary.withValues(alpha: 0.6);
    }
  }
}
