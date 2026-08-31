import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

/// Source-anchored fixtures for the IOM 2005 TDEE equations.
///
/// #987 was a transcription bug — the activity coefficient was applied to the
/// weight term but not the height term — and the existing tests did not catch
/// it, because their expected values were computed by the same person reading
/// the same code. A test whose expectation comes from the implementation can
/// only ever confirm what the implementation already does.
///
/// So none of the numbers in [_publishedCases] were computed by this project.
/// They are printed in the source itself: Tables 5-29 (men, pp. 206-209) and
/// 5-30 (women, pp. 210-213) of
///
///   Institute of Medicine. 2005. Dietary Reference Intakes for Energy,
///   Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and
///   Amino Acids. Washington, DC: The National Academies Press.
///   https://doi.org/10.17226/10490
///
/// which tabulate 24-hour TEE for 30-year-old men and women across heights and
/// BMIs. If our output stops matching the book's own table, this fails.
///
/// Two traps are baked into the selection, both documented in
/// `docs/tdee-iom-2005-verification.md`:
///
/// 1. **Only the BMI >= 25 columns of those tables use the p. 204 equations.**
///    The book says so on p. 208 and the arithmetic confirms it: the BMI 18.5,
///    22.5 and 24.99 columns were computed with the *p. 185* normal-weight EER
///    set, which has different coefficients entirely. Every case below is from
///    a BMI 25/30/35/40 column. Do not extend this list with a normal-weight
///    column — it will not reproduce and the equations are not wrong.
/// 2. **Tolerance is +/-1.5 kcal, not exact.** The book computed its tables
///    with the unrounded intercepts of Appendix Table I-11 (864.1 for men,
///    386.5 for women); p. 204 prints 864 and 387, which is what we implement.
///    The gap is at most 0.98 kcal across these 26 cases.
///
/// Weights are BMI x height^2, not the rounded kg the table prints in its
/// input column.
void main() {
  // Yesterday, so the constructed birthday stays valid on the 1st of a month
  // and cannot straddle a midnight rollover mid-run.
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  UserEntity userAged30({
    required UserGenderEntity gender,
    required double weightKG,
    required double heightM,
    required UserPALEntity pal,
  }) {
    return UserEntity(
      birthday: DateTime(yesterday.year - 30, yesterday.month, yesterday.day),
      heightCM: heightM * 100,
      weightKG: weightKG,
      gender: gender,
      goal: UserWeightGoalEntity.maintainWeight,
      pal: pal,
    );
  }

  group('IOM 2005 Tables 5-29 / 5-30 — values printed in the source', () {
    for (final c in _publishedCases) {
      test('${c.citation} → ${c.publishedKcal} kcal', () {
        final tdee = TDEECalc.getTDEEKcalIOM2005(
          userAged30(
            gender: c.gender,
            weightKG: c.weightKG,
            heightM: c.heightM,
            pal: c.pal,
          ),
        );
        expect(tdee, closeTo(c.publishedKcal.toDouble(), 1.5));
      });
    }

    test('the fixtures actually discriminate — the #987 grouping fails them',
        () {
      // Guard on the guard. If someone "simplifies" these fixtures into
      // something the buggy formula also satisfies, they stop being a test.
      // The pre-#987 code left the height term outside the PA multiplier;
      // reproduced here so the failure it would produce is measurable.
      double buggy(_PublishedCase c) {
        final isMale = c.gender == UserGenderEntity.male;
        final pa = _paFor(c.pal, isMale: isMale);
        return isMale
            ? 864 - 9.72 * 30 + pa * 14.2 * c.weightKG + 503 * c.heightM
            : 387 - 7.31 * 30 + pa * 10.9 * c.weightKG + 660.7 * c.heightM;
      }

      final discriminating = _publishedCases
          .where((c) => c.pal != UserPALEntity.sedentary)
          .toList();

      // Sedentary rows carry PA = 1.00, so the bug is invisible there — which
      // is exactly why the old sedentary-only pins passed for years.
      expect(discriminating, hasLength(16));
      for (final c in discriminating) {
        expect(
          (buggy(c) - c.publishedKcal).abs(),
          greaterThan(50),
          reason: 'the buggy grouping should miss ${c.citation} badly',
        );
      }
    });
  });

  group('IOM 2005 p. 204 — independently derived, ages other than 30', () {
    // Every cell of Tables 5-29/5-30 is age 30, so those fixtures cannot
    // exercise the age coefficient at all. These values were derived from the
    // p. 204 page image by three agents that were denied access to this
    // repository, and reconciled by a fourth; see
    // `docs/tdee-iom-2005-verification.md`. They are not hand-computed here.
    void expectTdee({
      required UserGenderEntity gender,
      required int age,
      required double weightKG,
      required double heightCM,
      required UserPALEntity pal,
      required double expected,
    }) {
      final user = UserEntity(
        birthday: DateTime(yesterday.year - age, yesterday.month, yesterday.day),
        heightCM: heightCM,
        weightKG: weightKG,
        gender: gender,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: pal,
      );
      expect(TDEECalc.getTDEEKcalIOM2005(user), closeTo(expected, 0.01));
    }

    test('male 25 y, 80 kg, 180 cm, sedentary', () {
      expectTdee(
        gender: UserGenderEntity.male,
        age: 25,
        weightKG: 80,
        heightCM: 180,
        pal: UserPALEntity.sedentary,
        expected: 2662.40,
      );
    });

    test('male 25 y, 80 kg, 180 cm, very active', () {
      expectTdee(
        gender: UserGenderEntity.male,
        age: 25,
        weightKG: 80,
        heightCM: 180,
        pal: UserPALEntity.veryActive,
        expected: 3764.76,
      );
    });

    test('male 19 y, 60 kg, 155 cm, very active (youngest in-range age)', () {
      expectTdee(
        gender: UserGenderEntity.male,
        age: 19,
        weightKG: 60,
        heightCM: 155,
        pal: UserPALEntity.veryActive,
        expected: 3192.06,
      );
    });

    test('female 54 y, 75 kg, 160 cm, active', () {
      expectTdee(
        gender: UserGenderEntity.female,
        age: 54,
        weightKG: 75,
        heightCM: 160,
        pal: UserPALEntity.active,
        expected: 2373.03,
      );
    });

    test('female 25 y, 80 kg, 180 cm, low active — the p. 185 / p. 204 trap',
        () {
      // The p. 185 women's PA table is 1.00 / 1.12 / 1.27 / 1.45, identical to
      // p. 204's except at low active, where p. 204 says 1.14. This is the one
      // profile that separates them, and the only thing standing between us
      // and silently sharing the men's low-active coefficient.
      expectTdee(
        gender: UserGenderEntity.female,
        age: 25,
        weightKG: 80,
        heightCM: 180,
        pal: UserPALEntity.lowActive,
        expected: 2554.09,
      );
    });

    test('female 35 y, 70 kg, 165 cm, sedentary', () {
      expectTdee(
        gender: UserGenderEntity.female,
        age: 35,
        weightKG: 70,
        heightCM: 165,
        pal: UserPALEntity.sedentary,
        expected: 1984.31,
      );
    });
  });
}

/// The PA coefficients printed under the p. 204 equations. Duplicated here on
/// purpose: a fixture file that imports the production lookup would validate
/// the code against itself.
double _paFor(UserPALEntity pal, {required bool isMale}) {
  switch (pal) {
    case UserPALEntity.sedentary:
      return 1.00;
    case UserPALEntity.lowActive:
      return isMale ? 1.12 : 1.14;
    case UserPALEntity.active:
      return 1.27;
    case UserPALEntity.veryActive:
      return isMale ? 1.54 : 1.45;
  }
}

class _PublishedCase {
  final UserGenderEntity gender;
  final double weightKG;
  final double heightM;
  final UserPALEntity pal;
  final int publishedKcal;
  final String citation;

  const _PublishedCase({
    required this.gender,
    required this.weightKG,
    required this.heightM,
    required this.pal,
    required this.publishedKcal,
    required this.citation,
  });
}

const _m = UserGenderEntity.male;
const _f = UserGenderEntity.female;
const _sed = UserPALEntity.sedentary;
const _low = UserPALEntity.lowActive;
const _act = UserPALEntity.active;
const _very = UserPALEntity.veryActive;

/// Transcribed from the page images at
/// `https://nap.nationalacademies.org/books/10490/gif/<page>.gif`
const List<_PublishedCase> _publishedCases = [
  // Table 5-29 (men), inputs p. 206 / results p. 207.
  _PublishedCase(gender: _m, weightKG: 52.5625, heightM: 1.45, pal: _sed, publishedKcal: 2048, citation: 'T5-29 p.207 h1.45 BMI25 sedentary'),
  _PublishedCase(gender: _m, weightKG: 52.5625, heightM: 1.45, pal: _low, publishedKcal: 2225, citation: 'T5-29 p.207 h1.45 BMI25 low active'),
  _PublishedCase(gender: _m, weightKG: 52.5625, heightM: 1.45, pal: _act, publishedKcal: 2447, citation: 'T5-29 p.207 h1.45 BMI25 active'),
  _PublishedCase(gender: _m, weightKG: 52.5625, heightM: 1.45, pal: _very, publishedKcal: 2845, citation: 'T5-29 p.207 h1.45 BMI25 very active'),
  _PublishedCase(gender: _m, weightKG: 63.075, heightM: 1.45, pal: _sed, publishedKcal: 2197, citation: 'T5-29 p.207 h1.45 BMI30 sedentary'),
  _PublishedCase(gender: _m, weightKG: 84.1, heightM: 1.45, pal: _very, publishedKcal: 3535, citation: 'T5-29 p.207 h1.45 BMI40 very active'),
  _PublishedCase(gender: _m, weightKG: 78.75, heightM: 1.50, pal: _act, publishedKcal: 2951, citation: 'T5-29 p.207 h1.50 BMI35 active'),
  _PublishedCase(gender: _m, weightKG: 64.0, heightM: 1.60, pal: _sed, publishedKcal: 2286, citation: 'T5-29 p.207 h1.60 BMI25 sedentary'),
  _PublishedCase(gender: _m, weightKG: 102.4, heightM: 1.60, pal: _very, publishedKcal: 4051, citation: 'T5-29 p.207 h1.60 BMI40 very active'),
  // Table 5-29 continued, inputs p. 208 / results p. 209.
  _PublishedCase(gender: _m, weightKG: 97.2, heightM: 1.80, pal: _sed, publishedKcal: 2858, citation: 'T5-29 p.209 h1.80 BMI30 sedentary'),
  _PublishedCase(gender: _m, weightKG: 97.2, heightM: 1.80, pal: _low, publishedKcal: 3132, citation: 'T5-29 p.209 h1.80 BMI30 low active'),
  _PublishedCase(gender: _m, weightKG: 97.2, heightM: 1.80, pal: _act, publishedKcal: 3475, citation: 'T5-29 p.209 h1.80 BMI30 active'),
  _PublishedCase(gender: _m, weightKG: 97.2, heightM: 1.80, pal: _very, publishedKcal: 4092, citation: 'T5-29 p.209 h1.80 BMI30 very active'),
  _PublishedCase(gender: _m, weightKG: 152.1, heightM: 1.95, pal: _sed, publishedKcal: 3713, citation: 'T5-29 p.209 h1.95 BMI40 sedentary'),
  _PublishedCase(gender: _m, weightKG: 152.1, heightM: 1.95, pal: _very, publishedKcal: 5409, citation: 'T5-29 p.209 h1.95 BMI40 very active'),
  // Table 5-30 (women), inputs p. 210 / results p. 211.
  _PublishedCase(gender: _f, weightKG: 52.5625, heightM: 1.45, pal: _sed, publishedKcal: 1698, citation: 'T5-30 p.211 h1.45 BMI25 sedentary'),
  _PublishedCase(gender: _f, weightKG: 52.5625, heightM: 1.45, pal: _low, publishedKcal: 1912, citation: 'T5-30 p.211 h1.45 BMI25 low active'),
  _PublishedCase(gender: _f, weightKG: 52.5625, heightM: 1.45, pal: _act, publishedKcal: 2112, citation: 'T5-30 p.211 h1.45 BMI25 active'),
  _PublishedCase(gender: _f, weightKG: 52.5625, heightM: 1.45, pal: _very, publishedKcal: 2387, citation: 'T5-30 p.211 h1.45 BMI25 very active'),
  _PublishedCase(gender: _f, weightKG: 84.1, heightM: 1.45, pal: _sed, publishedKcal: 2042, citation: 'T5-30 p.211 h1.45 BMI40 sedentary'),
  _PublishedCase(gender: _f, weightKG: 64.0, heightM: 1.60, pal: _sed, publishedKcal: 1922, citation: 'T5-30 p.211 h1.60 BMI25 sedentary'),
  _PublishedCase(gender: _f, weightKG: 102.4, heightM: 1.60, pal: _very, publishedKcal: 3318, citation: 'T5-30 p.211 h1.60 BMI40 very active'),
  // Table 5-30 continued, inputs p. 212 / results p. 213.
  _PublishedCase(gender: _f, weightKG: 97.2, heightM: 1.80, pal: _sed, publishedKcal: 2416, citation: 'T5-30 p.213 h1.80 BMI30 sedentary'),
  _PublishedCase(gender: _f, weightKG: 97.2, heightM: 1.80, pal: _very, publishedKcal: 3428, citation: 'T5-30 p.213 h1.80 BMI30 very active'),
  _PublishedCase(gender: _f, weightKG: 152.1, heightM: 1.95, pal: _sed, publishedKcal: 3113, citation: 'T5-30 p.213 h1.95 BMI40 sedentary'),
  _PublishedCase(gender: _f, weightKG: 152.1, heightM: 1.95, pal: _very, publishedKcal: 4439, citation: 'T5-30 p.213 h1.95 BMI40 very active'),
];
