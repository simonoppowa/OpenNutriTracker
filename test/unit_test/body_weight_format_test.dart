import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';

void main() {
  // Labels are passed as plain strings so the pure function can be tested
  // without a widget tree — matching what S.of(context) would return.
  const kgLabel = 'kg';
  const lbLabel = 'lbs';
  const stLabel = 'st';

  group('formatBodyWeight — kg unit', () {
    test('whole-number weight trims trailing .0 (72.0 -> "72 kg")', () {
      expect(
        formatBodyWeight(72.0, BodyWeightUnit.kg, kgLabel: kgLabel, lbLabel: lbLabel, stLabel: stLabel),
        equals('72 kg'),
      );
    });

    test('fractional weight keeps one decimal (72.5 -> "72.5 kg")', () {
      expect(
        formatBodyWeight(72.5, BodyWeightUnit.kg, kgLabel: kgLabel, lbLabel: lbLabel, stLabel: stLabel),
        equals('72.5 kg'),
      );
    });

    test('rounding noise around a whole number is trimmed (80.0000001 -> "80 kg")', () {
      expect(
        formatBodyWeight(80.0000001, BodyWeightUnit.kg, kgLabel: kgLabel, lbLabel: lbLabel, stLabel: stLabel),
        equals('80 kg'),
      );
    });
  });

  group('formatBodyWeight — lb unit', () {
    test('converts via kgToLbs and appends label', () {
      const kg = 70.0;
      final expectedLbs = formatProfileWeight(UnitCalc.kgToLbs(kg));
      expect(
        formatBodyWeight(kg, BodyWeightUnit.lb, kgLabel: kgLabel, lbLabel: lbLabel, stLabel: stLabel),
        equals('$expectedLbs lbs'),
      );
    });

    test('whole-pound result trims decimal (68.04 kg rounds to a whole number of lbs)', () {
      // 150 lbs = 68.04 kg. kgToLbs(68.04) should give exactly 150.0, and
      // formatProfileWeight trims the .0.
      const kg = 68.04;
      final label = formatBodyWeight(
        kg,
        BodyWeightUnit.lb,
        kgLabel: kgLabel,
        lbLabel: lbLabel,
        stLabel: stLabel,
      );
      // The formatted string should not end with '.0 lbs'.
      expect(label, isNot(contains('.0 lbs')));
      expect(label, endsWith(lbLabel));
    });
  });

  group('formatBodyWeight — st unit', () {
    test('1 stone exactly shows "1 st 0 lbs"', () {
      // 1 stone = 6.35029 kg. The pounds remainder at 2dp is 0.00; after
      // formatProfileWeight that trims the .0 to '0'.
      const oneStoneKg = 6.35029;
      expect(
        formatBodyWeight(oneStoneKg, BodyWeightUnit.st, kgLabel: kgLabel, lbLabel: lbLabel, stLabel: stLabel),
        equals('1 st 0 lbs'),
      );
    });

    test('fractional stone shows stones and remaining pounds', () {
      // 70 kg is roughly 11 st. Verify the format contains both the stones
      // component and the 'st' / 'lbs' labels.
      const kg = 70.0;
      final result = formatBodyWeight(
        kg,
        BodyWeightUnit.st,
        kgLabel: kgLabel,
        lbLabel: lbLabel,
        stLabel: stLabel,
      );
      expect(result, contains(stLabel));
      expect(result, contains(lbLabel));
      // Should start with the stones integer.
      final (stones, _) = UnitCalc.kgToStLb(kg);
      expect(result, startsWith('$stones '));
    });

    test('kgToStLb raw pounds value never reaches 14.0', () {
      // The rollover guard in kgToStLb ensures the raw pounds value stays
      // strictly below 14.0 before formatProfileWeight sees it. Note that
      // formatProfileWeight may round 13.99 up to 14.0 for display — that is
      // a separate display concern and not tested here.
      for (final kg in const [50.0, 63.5, 70.0, 80.0, 100.0]) {
        final (_, pounds) = UnitCalc.kgToStLb(kg);
        expect(pounds, lessThan(14.0),
            reason: 'raw pounds from kgToStLb($kg) should be less than 14, got $pounds');
      }
    });
  });

  group('formatHeight', () {
    test('metric shows whole cm with the cm label', () {
      expect(
        formatHeight(170, false, cmLabel: 'cm', ftLabel: 'ft', inLabel: 'in'),
        '170 cm',
      );
    });

    test('imperial shows feet and inches, not decimal feet', () {
      // 175 cm -> 5 ft 9 in.
      expect(
        formatHeight(175, true, cmLabel: 'cm', ftLabel: 'ft', inLabel: 'in'),
        '5 ft 9 in',
      );
    });

    test('imperial rolls 12 inches into the next foot', () {
      // 182 cm rounds to 6 ft 0 in rather than 5 ft 12 in.
      expect(
        formatHeight(182, true, cmLabel: 'cm', ftLabel: 'ft', inLabel: 'in'),
        '6 ft 0 in',
      );
    });
  });
}
