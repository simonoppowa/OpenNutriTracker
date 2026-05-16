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
    // reduction intake, the same number the FDA Daily Value uses.
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
    // 1200 mg women 51+ and everyone 71+.
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
    // IOM RDA: 15 µg (600 IU) adults to age 70, 20 µg (800 IU) 71+.
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

/// Canonical URL surfaced in the in-app "where do these come from" dialog.
/// Kept here next to the table so changes stay in one place.
const String driSourceUrl =
    'https://www.nationalacademies.org/our-work/summary-report-of-the-dietary-reference-intakes';
