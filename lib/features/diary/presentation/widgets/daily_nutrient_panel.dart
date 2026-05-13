import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
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
class DailyNutrientPanel extends StatelessWidget {
  final List<IntakeEntity> intakes;

  const DailyNutrientPanel({super.key, required this.intakes});

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

    // Reference values are sensible adult DRIs / FDA Daily Values. Iron's
    // reference uses UserEntity.gender so women see 18mg and men see 8mg;
    // non-binary users get a midpoint of 14mg, in line with the app's
    // existing averaged-reference convention for non-binary calculations.
    const fiberRefG = 30.0;
    const sodiumRefMg = 2300.0;
    const saturatedFatRefG = 20.0;
    const sugarRefG = 50.0;
    const calciumRefMg = 1000.0;
    final ironRefMg = _ironRefForGender(user?.gender);
    const potassiumRefMg = 3500.0;

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
