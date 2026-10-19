// IOM Dietary Reference Intakes — https://www.nationalacademies.org/our-work/summary-report-of-the-dietary-reference-intakes
//
// Age-banded reference values for adults, sourced from the Institute of
// Medicine (now the National Academies' Health and Medicine Division)
// Dietary Reference Intake tables. RDAs are used where the IOM publishes
// one; for sodium the value below is the Chronic Disease Risk Reduction
// Intake (CDRR / UL), since the IOM does not publish an RDA. The figures
// match the consolidated DRI tables linked from the URL above.
//
// Scope notes:
// * Adults only. Pregnancy and lactation reference rows are explicitly out
//   of scope for v1 — pregnant or lactating users currently fall back to
//   the female 19 to 30 row, with this comment as the trail of breadcrumbs
//   for whoever picks the work up.
// * Non-binary users are routed through `CaloriesProfileEntity`, mirroring
//   the existing dispatch convention used by `ConfigEntity` for water goals.
//   `estrogenTypical` resolves to the female row, `testosteroneTypical` to
//   the male row, and `averaged` (or null, since the field is nullable)
//   returns the midpoint of the two binary rows so iron, magnesium and
//   friends sit at a neutral starting point that doesn't pretend to know
//   more about the user's body than they've shared.
// * The map is keyed by the panel's `NutrientPanelKeys` strings so a single
//   call site at the top of the widget can fetch every value.
//
// Reading the rows: the constants below name each nutrient and its unit so
// the lookup table itself stays compact and easy to audit against the IOM
// PDF. Where a single age band is used the comment names the cohort the
// figure was drawn from.

import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';

/// A single reference-intake row returned from [getReferenceFor]. The value
/// is already in the unit the panel uses for that nutrient — grams for
/// fibre / saturated fat / sugar, milligrams for sodium / calcium / iron /
/// potassium / magnesium, micrograms for vitamin D / vitamin B12.
class DriReference {
  /// Reference amount in the nutrient's display unit.
  final double amount;

  /// Display unit, matching the panel: 'g', 'mg', or 'µg'.
  final String unit;

  /// IOM table the value came from. 'RDA' for recommended daily allowance,
  /// 'AI' for adequate intake (where the IOM has not set an RDA), 'UL' for
  /// tolerable upper intake level / chronic-disease-risk-reduction intake.
  final String basis;

  const DriReference({
    required this.amount,
    required this.unit,
    required this.basis,
  });
}

enum _LifeStage {
  m19to30,
  m31to50,
  m51to70,
  m71plus,
  f19to30,
  f31to50,
  f51to70,
  f71plus,
}

/// How the user's gender + calories profile should resolve against the
/// binary DRI rows. `female` and `male` map directly to a single row;
/// `averaged` means the caller should look up both rows and return the
/// midpoint, which is how non-binary users with the default profile land.
enum _DriRoute { female, male, averaged }

_DriRoute _routeFor(UserEntity user) {
  return switch (user.gender) {
    UserGenderEntity.female => _DriRoute.female,
    UserGenderEntity.male => _DriRoute.male,
    UserGenderEntity.nonBinary => switch (user.caloriesProfile) {
        CaloriesProfileEntity.estrogenTypical => _DriRoute.female,
        CaloriesProfileEntity.testosteroneTypical => _DriRoute.male,
        // averaged is the project's documented default and null falls back
        // to the same place; see [CaloriesProfileEntity.averaged].
        CaloriesProfileEntity.averaged || null => _DriRoute.averaged,
      },
  };
}

_LifeStage _femaleStage(int age) {
  if (age <= 30) return _LifeStage.f19to30;
  if (age <= 50) return _LifeStage.f31to50;
  if (age <= 70) return _LifeStage.f51to70;
  return _LifeStage.f71plus;
}

_LifeStage _maleStage(int age) {
  if (age <= 30) return _LifeStage.m19to30;
  if (age <= 50) return _LifeStage.m31to50;
  if (age <= 70) return _LifeStage.m51to70;
  return _LifeStage.m71plus;
}

// The lookup table itself. Outer key is the panel's nutrient identifier;
// inner key is the life-stage band. Every nutrient lists every band so a
// missing entry indicates a genuine gap rather than a silent fallback.
const Map<String, Map<_LifeStage, DriReference>> _driTable = {
  NutrientPanelKeys.fiber: {
    // IOM AI for fibre: 38g (men 19 to 50), 30g (men 51+),
    // 25g (women 19 to 50), 21g (women 51+).
    _LifeStage.m19to30: DriReference(amount: 38, unit: 'g', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 38, unit: 'g', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 30, unit: 'g', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 30, unit: 'g', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 25, unit: 'g', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 25, unit: 'g', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 21, unit: 'g', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 21, unit: 'g', basis: 'AI'),
  },
  NutrientPanelKeys.sodium: {
    // IOM CDRR / UL: 2300 mg/day for all adults. The IOM does not publish
    // a sodium RDA — the figure below is the chronic-disease-risk
    // reduction intake from the 2019 sodium/potassium update, the same
    // number the FDA Daily Value uses. Because it is a ceiling rather than
    // a target, the panel labels this row a "limit" (see _NutrientRow).
    // https://www.nationalacademies.org/projects/HMD-FNB-17-01
    _LifeStage.m19to30: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.m31to50: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.m51to70: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.m71plus: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.f19to30: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.f31to50: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.f51to70: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
    _LifeStage.f71plus: DriReference(amount: 2300, unit: 'mg', basis: 'UL'),
  },
  NutrientPanelKeys.calcium: {
    // IOM RDA: 1000 mg adults 19 to 50 (and men 51 to 70),
    // 1200 mg women 51+ and everyone 71+. The 2011 IOM report set an EAR
    // and RDA for calcium, replacing the 1997 AI — so these adult figures
    // are RDAs, not the AI the older table listed.
    // https://www.nationalacademies.org/our-work/dietary-reference-intakes-for-calcium-and-vitamin-d
    _LifeStage.m19to30: DriReference(amount: 1000, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 1000, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 1000, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 1200, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 1000, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 1000, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 1200, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 1200, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.iron: {
    // IOM RDA: men 8 mg, women 19 to 50 18 mg (menstruation),
    // women 51+ 8 mg (post-menopause).
    _LifeStage.m19to30: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 18, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 18, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.potassium: {
    // IOM AI (2019 update): men 3400 mg, women 2600 mg.
    // https://www.nationalacademies.org/projects/HMD-FNB-17-01
    _LifeStage.m19to30: DriReference(amount: 3400, unit: 'mg', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 3400, unit: 'mg', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 3400, unit: 'mg', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 3400, unit: 'mg', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 2600, unit: 'mg', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 2600, unit: 'mg', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 2600, unit: 'mg', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 2600, unit: 'mg', basis: 'AI'),
  },
  NutrientPanelKeys.vitaminD: {
    // IOM RDA: 15 µg (600 IU) adults to age 70, 20 µg (800 IU) 71+. The
    // 2011 IOM report established an EAR and RDA for vitamin D, superseding
    // the older 1997 AI values (5/5/10/15 µg by age band) — so these are
    // current RDAs, not the AI the 1997 table listed.
    // https://www.nationalacademies.org/our-work/dietary-reference-intakes-for-calcium-and-vitamin-d
    _LifeStage.m19to30: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 20, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 15, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 20, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminB12: {
    // IOM RDA: 2.4 µg for all adults.
    _LifeStage.m19to30: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 2.4, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.magnesium: {
    // IOM RDA: men 19 to 30 400 mg, men 31+ 420 mg,
    // women 19 to 30 310 mg, women 31+ 320 mg.
    _LifeStage.m19to30: DriReference(amount: 400, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 420, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 420, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 420, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 310, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 320, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 320, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 320, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.zinc: {
    // IOM RDA: men 11 mg, women 8 mg.
    _LifeStage.m19to30: DriReference(amount: 11, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 11, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 11, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 11, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 8, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.phosphorus: {
    // IOM RDA: 700 mg for all adults.
    _LifeStage.m19to30: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 700, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminA: {
    // IOM RDA (retinol activity equivalents): men 900 µg, women 700 µg.
    _LifeStage.m19to30: DriReference(amount: 900, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 900, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 900, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 900, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 700, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 700, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 700, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 700, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminC: {
    // IOM RDA: men 90 mg, women 75 mg.
    _LifeStage.m19to30: DriReference(amount: 90, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 90, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 90, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 90, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 75, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 75, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 75, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 75, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminB6: {
    // IOM RDA: 1.3 mg adults 19 to 50; men 51+ 1.7 mg, women 51+ 1.5 mg.
    _LifeStage.m19to30: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 1.7, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 1.7, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 1.5, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 1.5, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.niacin: {
    // IOM RDA (niacin equivalents): men 16 mg, women 14 mg.
    _LifeStage.m19to30: DriReference(amount: 16, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 16, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 16, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 16, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 14, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 14, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 14, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 14, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminE: {
    // IOM RDA (alpha-tocopherol): 15 mg for all adults.
    _LifeStage.m19to30: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 15, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.vitaminK: {
    // IOM AI: men 120 µg, women 90 µg.
    _LifeStage.m19to30: DriReference(amount: 120, unit: 'µg', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 120, unit: 'µg', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 120, unit: 'µg', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 120, unit: 'µg', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 90, unit: 'µg', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 90, unit: 'µg', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 90, unit: 'µg', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 90, unit: 'µg', basis: 'AI'),
  },
  NutrientPanelKeys.thiamin: {
    // IOM RDA: men 1.2 mg, women 1.1 mg.
    _LifeStage.m19to30: DriReference(amount: 1.2, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 1.2, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 1.2, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 1.2, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.riboflavin: {
    // IOM RDA: men 1.3 mg, women 1.1 mg.
    _LifeStage.m19to30: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 1.3, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 1.1, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.pantothenicAcid: {
    // IOM AI: 5 mg for all adults.
    _LifeStage.m19to30: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 5, unit: 'mg', basis: 'AI'),
  },
  NutrientPanelKeys.biotin: {
    // IOM AI: 30 µg for all adults.
    _LifeStage.m19to30: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 30, unit: 'µg', basis: 'AI'),
  },
  NutrientPanelKeys.folate: {
    // IOM RDA (dietary folate equivalents): 400 µg for all adults.
    _LifeStage.m19to30: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 400, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.iodine: {
    // IOM RDA: 150 µg for all adults.
    _LifeStage.m19to30: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 150, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.selenium: {
    // IOM RDA: 55 µg for all adults.
    _LifeStage.m19to30: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 55, unit: 'µg', basis: 'RDA'),
  },
  NutrientPanelKeys.copper: {
    // IOM RDA: 900 µg (0.9 mg) for all adults.
    _LifeStage.m19to30: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.m31to50: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.m51to70: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.m71plus: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.f19to30: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.f31to50: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.f51to70: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
    _LifeStage.f71plus: DriReference(amount: 0.9, unit: 'mg', basis: 'RDA'),
  },
  NutrientPanelKeys.manganese: {
    // IOM AI: men 2.3 mg, women 1.8 mg.
    _LifeStage.m19to30: DriReference(amount: 2.3, unit: 'mg', basis: 'AI'),
    _LifeStage.m31to50: DriReference(amount: 2.3, unit: 'mg', basis: 'AI'),
    _LifeStage.m51to70: DriReference(amount: 2.3, unit: 'mg', basis: 'AI'),
    _LifeStage.m71plus: DriReference(amount: 2.3, unit: 'mg', basis: 'AI'),
    _LifeStage.f19to30: DriReference(amount: 1.8, unit: 'mg', basis: 'AI'),
    _LifeStage.f31to50: DriReference(amount: 1.8, unit: 'mg', basis: 'AI'),
    _LifeStage.f51to70: DriReference(amount: 1.8, unit: 'mg', basis: 'AI'),
    _LifeStage.f71plus: DriReference(amount: 1.8, unit: 'mg', basis: 'AI'),
  },
};

/// Looks up the IOM reference intake for a given nutrient and user.
///
/// Returns null when the nutrient has no row in the table — saturated fat
/// and added sugar are the obvious ones, since the IOM publishes neither
/// as an RDA. Callers should treat a null as "no reference to display"
/// and render the row without a DRI bar rather than substituting a guess.
DriReference? getReferenceFor({
  required String nutrient,
  required UserEntity user,
}) {
  final rows = _driTable[nutrient];
  if (rows == null) return null;
  final route = _routeFor(user);
  switch (route) {
    case _DriRoute.female:
      return rows[_femaleStage(user.age)];
    case _DriRoute.male:
      return rows[_maleStage(user.age)];
    case _DriRoute.averaged:
      final f = rows[_femaleStage(user.age)];
      final m = rows[_maleStage(user.age)];
      if (f == null || m == null) return f ?? m;
      // Same unit on both rows by construction; the IOM doesn't change
      // units within a single nutrient. Basis follows the female row's
      // label so the dialog text stays accurate for whichever side it
      // came from — for averaged figures both rows always agree on basis.
      return DriReference(
        amount: (f.amount + m.amount) / 2,
        unit: f.unit,
        basis: f.basis,
      );
  }
}

/// Reference values of the German and Austrian nutrition societies
/// (DGE/ÖGE, formerly D-A-CH with the Swiss SGE until 2022; #49), keyed
/// like [_driTable]: per nutrient the male and the
/// female values for the DGE age bands 19 to under 25, 25 to under 51, 51
/// to under 65 and 65 and older, in the panel's units.
///
/// Source: DGE/ÖGE, Referenzwerte für die Nährstoffzufuhr, 3rd edition
/// 2025, as published per nutrient on [dgeSourceUrl] (read 2026-10-19;
/// derivation years: calcium 2013, sodium and potassium 2016, vitamin B12
/// 2018, vitamin B6 and zinc 2019, vitamin A 2020, magnesium and fibre
/// 2021, phosphorus 2022, iron 2023, vitamin C and niacin 2015, vitamin D
/// 2012; for #50: vitamin E 2024, vitamin K, copper and manganese 2000,
/// thiamin, riboflavin, folate and selenium 2015, biotin 2020, pantothenic
/// acid 2021, iodine 2025).
///
/// * Sodium: the DGE guidance of at most 6 g salt a day (2400 mg sodium),
///   since the panel treats sodium as a limit; the DGE estimate for an
///   adequate intake is 1500 mg.
/// * Iron: the DGE lists 16 mg for women before and 14 mg after the
///   menopause; the app does not know which applies and uses 16 mg up to
///   50 and 14 mg from 51.
/// * Zinc: the values for a medium phytate intake.
/// * Vitamin D: the estimate for when the skin makes none.
/// * Fibre: the guide value of at least 30 g.
/// * Copper and manganese: the lower end of the DGE ranges (1.0 to 1.5 mg
///   and 2.0 to 5.0 mg).
/// * Protein (2017 derivation, see [getDgeReferenceFor]): 0.8 g per kg body
///   weight, from 65 1.0 g; without a user the midpoint of the 25 to under
///   51 values per day, 57 g for men and 48 g for women.
///
/// Saturated fat, sugar, cholesterol, mono-, polyunsaturated and trans fat
/// have no DGE value; the panel falls back to its IOM/FDA reference.
const Map<String, (List<double>, List<double>)> _dgeTable = {
  NutrientPanelKeys.fiber: ([30, 30, 30, 30], [30, 30, 30, 30]),
  NutrientPanelKeys.sodium: (
    [2400, 2400, 2400, 2400],
    [2400, 2400, 2400, 2400],
  ),
  NutrientPanelKeys.potassium: (
    [4000, 4000, 4000, 4000],
    [4000, 4000, 4000, 4000],
  ),
  NutrientPanelKeys.calcium: (
    [1000, 1000, 1000, 1000],
    [1000, 1000, 1000, 1000],
  ),
  NutrientPanelKeys.phosphorus: ([550, 550, 550, 550], [550, 550, 550, 550]),
  NutrientPanelKeys.magnesium: ([350, 350, 350, 350], [300, 300, 300, 300]),
  NutrientPanelKeys.iron: ([11, 11, 11, 11], [16, 16, 14, 14]),
  NutrientPanelKeys.zinc: ([14, 14, 14, 14], [8, 8, 8, 8]),
  NutrientPanelKeys.vitaminA: ([850, 850, 850, 800], [700, 700, 700, 700]),
  NutrientPanelKeys.vitaminC: ([110, 110, 110, 110], [95, 95, 95, 95]),
  NutrientPanelKeys.vitaminD: ([20, 20, 20, 20], [20, 20, 20, 20]),
  NutrientPanelKeys.vitaminB6: ([1.6, 1.6, 1.6, 1.6], [1.4, 1.4, 1.4, 1.4]),
  NutrientPanelKeys.vitaminB12: ([4, 4, 4, 4], [4, 4, 4, 4]),
  NutrientPanelKeys.niacin: ([16, 15, 15, 14], [13, 12, 11, 11]),
  NutrientPanelKeys.vitaminE: (
    [8, 8, 8, 8],
    [8, 8, 8, 8],
  ),
  NutrientPanelKeys.vitaminK: (
    [70, 70, 80, 80],
    [60, 60, 65, 65],
  ),
  NutrientPanelKeys.thiamin: (
    [1.3, 1.2, 1.2, 1.1],
    [1, 1, 1, 1],
  ),
  NutrientPanelKeys.riboflavin: (
    [1.4, 1.4, 1.3, 1.3],
    [1.1, 1.1, 1, 1],
  ),
  NutrientPanelKeys.pantothenicAcid: (
    [5, 5, 5, 5],
    [5, 5, 5, 5],
  ),
  NutrientPanelKeys.biotin: (
    [40, 40, 40, 40],
    [40, 40, 40, 40],
  ),
  NutrientPanelKeys.folate: (
    [300, 300, 300, 300],
    [300, 300, 300, 300],
  ),
  NutrientPanelKeys.iodine: (
    [150, 150, 150, 150],
    [150, 150, 150, 150],
  ),
  NutrientPanelKeys.selenium: (
    [70, 70, 70, 70],
    [60, 60, 60, 60],
  ),
  NutrientPanelKeys.copper: (
    [1, 1, 1, 1],
    [1, 1, 1, 1],
  ),
  NutrientPanelKeys.manganese: (
    [2, 2, 2, 2],
    [2, 2, 2, 2],
  ),
};

int _dgeBand(int age) {
  if (age < 25) return 0;
  if (age < 51) return 1;
  if (age < 65) return 2;
  return 3;
}

/// The DGE reference for [nutrient], or null when the DGE gives none.
///
/// Users are routed like [getReferenceFor]; without a [user] the value is
/// the midpoint of the female and male values for 25 to under 51.
DriReference? getDgeReferenceFor({required String nutrient, UserEntity? user}) {
  if (nutrient == NutrientPanelKeys.protein) {
    return DriReference(
      amount: user == null
          ? (57 + 48) / 2
          : user.weightKG * (user.age < 65 ? 0.8 : 1.0),
      unit: 'g',
      basis: 'DGE',
    );
  }
  final row = _dgeTable[nutrient];
  if (row == null) return null;
  final (male, female) = row;
  final band = user == null ? 1 : _dgeBand(user.age);
  final amount = switch (user == null ? _DriRoute.averaged : _routeFor(user)) {
    _DriRoute.male => male[band],
    _DriRoute.female => female[band],
    _DriRoute.averaged => (male[band] + female[band]) / 2,
  };
  return DriReference(
    amount: amount,
    unit: NutrientPanelTotals.panelFields[nutrient]!.unit,
    basis: 'DGE',
  );
}

/// Where the DGE publishes its reference values.
const String dgeSourceUrl = 'https://www.dge.de/wissenschaft/referenzwerte/';

/// Canonical URL surfaced in the in-app "where do these come from" dialog.
/// Kept here next to the table so changes stay in one place.
const String driSourceUrl =
    'https://www.nationalacademies.org/our-work/summary-report-of-the-dietary-reference-intakes';
