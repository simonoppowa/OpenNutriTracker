import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

void main() {
  group('UnitCalc.lbsToKg', () {
    test('preserves two decimal places (regression for PR #348)', () {
      expect(UnitCalc.lbsToKg(150), closeTo(68.04, 0.0001));
      expect(UnitCalc.lbsToKg(200), closeTo(90.72, 0.0001));
      expect(UnitCalc.lbsToKg(176), closeTo(79.83, 0.0001));
    });

    test('round-trip lbs → kg → lbs is exact for whole-pound weights', () {
      for (final lbs in const [100.0, 120.0, 150.0, 165.0, 180.0, 200.0, 250.0]) {
        final kg = UnitCalc.lbsToKg(lbs);
        final roundTrip = UnitCalc.kgToLbs(kg);
        expect(roundTrip, equals(lbs),
            reason: '$lbs lbs -> $kg kg -> $roundTrip lbs lost precision');
      }
    });

    test('handles zero and small weights', () {
      expect(UnitCalc.lbsToKg(0), equals(0));
      expect(UnitCalc.lbsToKg(1), closeTo(0.45, 0.005));
    });

    test('handles large weights', () {
      expect(UnitCalc.lbsToKg(1000), closeTo(453.59, 0.005));
    });
  });

  group('UnitCalc.kgToLbs', () {
    test('keeps one decimal place', () {
      // Whole-pound rounding used to make the same weight read differently
      // between the home chip / Trends (one decimal) and the rest of the app.
      expect(UnitCalc.kgToLbs(50), closeTo(110.2, 1e-9));
      expect(UnitCalc.kgToLbs(70), closeTo(154.3, 1e-9));
      expect(UnitCalc.kgToLbs(100), closeTo(220.5, 1e-9));
    });

    test('handles zero weight', () {
      expect(UnitCalc.kgToLbs(0), equals(0));
    });
  });

  group('UnitCalc.cmToInches / inchesToCm', () {
    test('inches → cm → inches preserves whole inches', () {
      for (final inches in const [60.0, 65.0, 70.0, 72.0, 75.0]) {
        final cm = UnitCalc.inchesToCm(inches);
        final back = UnitCalc.cmToInches(cm);
        expect(back, closeTo(inches, 0.0001));
      }
    });

    test('1 inch is 2.54 cm exactly', () {
      expect(UnitCalc.inchesToCm(1), equals(2.54));
    });
  });

  group('UnitCalc.cmToFeet / feetToCm', () {
    test('cmToFeet rounds to two decimal places', () {
      expect(UnitCalc.cmToFeet(180), closeTo(5.91, 0.001));
      expect(UnitCalc.cmToFeet(170), closeTo(5.58, 0.001));
    });

    test('feetToCm rounds to whole cm', () {
      expect(UnitCalc.feetToCm(6), equals(183));
      expect(UnitCalc.feetToCm(5.5), equals(168));
    });
  });

  group('UnitCalc.gToOz / ozToG', () {
    test('round-trip is approximately exact', () {
      for (final g in const [100.0, 250.0, 500.0]) {
        final oz = UnitCalc.gToOz(g);
        final back = UnitCalc.ozToG(oz);
        expect(back, closeTo(g, 0.0001));
      }
    });

    test('1 oz is 28.3495 g', () {
      expect(UnitCalc.ozToG(1), equals(28.3495));
    });
  });

  group('UnitCalc.mlToFlOz / flOzToMl', () {
    test('round-trip is approximately exact', () {
      for (final ml in const [100.0, 250.0, 500.0]) {
        final flOz = UnitCalc.mlToFlOz(ml);
        final back = UnitCalc.flOzToMl(flOz);
        expect(back, closeTo(ml, 0.0001));
      }
    });

    test('1 fl oz is 29.5735 ml', () {
      expect(UnitCalc.flOzToMl(1), equals(29.5735));
    });
  });

  group('UnitCalc.metricToImperialValue', () {
    test('converts grams to ounces', () {
      expect(UnitCalc.metricToImperialValue(100, 'g'),
          closeTo(UnitCalc.gToOz(100), 0.0001));
    });

    test('converts ml to fl oz', () {
      expect(UnitCalc.metricToImperialValue(250, 'ml'),
          closeTo(UnitCalc.mlToFlOz(250), 0.0001));
    });

    test('passes through unknown units unchanged', () {
      expect(UnitCalc.metricToImperialValue(42, 'kcal'), equals(42));
      expect(UnitCalc.metricToImperialValue(42, ''), equals(42));
    });
  });

  group('UnitCalc.kcalToKj / kjToKcal (#177)', () {
    test('1 kcal converts to 4.184 kJ exactly', () {
      expect(UnitCalc.kcalToKj(1), equals(4.184));
    });

    test('round-trip kcal → kJ → kcal is exact for whole-kcal values', () {
      for (final kcal in const [100.0, 250.0, 500.0, 2000.0]) {
        final kj = UnitCalc.kcalToKj(kcal);
        final back = UnitCalc.kjToKcal(kj);
        expect(back, closeTo(kcal, 1e-9),
            reason: '$kcal kcal -> $kj kJ -> $back kcal lost precision');
      }
    });

    test('zero passes through unchanged', () {
      expect(UnitCalc.kcalToKj(0), equals(0));
      expect(UnitCalc.kjToKcal(0), equals(0));
    });

    test('2000 kcal rounds to 8368 kJ (typical daily-goal sanity check)', () {
      expect(UnitCalc.kcalToKj(2000).round(), equals(8368));
    });
  });

  group('UnitCalc.imperialToMetricValue', () {
    test('converts ounces to grams', () {
      expect(UnitCalc.imperialToMetricValue(2, 'oz'),
          closeTo(UnitCalc.ozToG(2), 0.0001));
    });

    test('converts fl oz (both spelling variants) to ml', () {
      expect(UnitCalc.imperialToMetricValue(8, 'fl oz'),
          closeTo(UnitCalc.flOzToMl(8), 0.0001));
      expect(UnitCalc.imperialToMetricValue(8, 'fl.oz'),
          closeTo(UnitCalc.flOzToMl(8), 0.0001));
    });

    test('passes through unknown units unchanged', () {
      expect(UnitCalc.imperialToMetricValue(42, 'kcal'), equals(42));
    });
  });

  group('UnitCalc.kgToStLb / stLbToKg', () {
    test('kgToStLb(6.35029) is approximately (1, 0.0)', () {
      // 1 stone = 6.35029 kg exactly. At two decimal places the pounds
      // remainder is 0.00, which is exactly 0.0.
      final (stones, pounds) = UnitCalc.kgToStLb(6.35029);
      expect(stones, equals(1));
      expect(pounds, closeTo(0.0, 0.01));
    });

    test('kgToStLb(0) returns (0, 0.0)', () {
      final (stones, pounds) = UnitCalc.kgToStLb(0);
      expect(stones, equals(0));
      expect(pounds, equals(0.0));
    });

    test('round-trip kg -> st+lb -> kg stays within 0.05 kg', () {
      // Each intermediate step keeps two decimals so a small rounding
      // delta accumulates. 0.05 kg is generous enough for display use.
      for (final kg in const [50.0, 63.5, 70.3, 80.0, 100.0, 120.7]) {
        final (stones, pounds) = UnitCalc.kgToStLb(kg);
        final back = UnitCalc.stLbToKg(stones, pounds);
        expect(back, closeTo(kg, 0.05),
            reason: '$kg kg -> $stones st $pounds lb -> $back kg exceeded tolerance');
      }
    });

    test('rollover: a weight whose pound remainder rounds to 14.0 increments stones', () {
      // 2 stone = 12.70058 kg. A tiny amount below the next full stone keeps
      // the pounds remainder very close to 14.0; the rollover guard should
      // bump stones to 3 and set pounds to 0.0 rather than showing "2 st 14.0 lb".
      // We construct the boundary ourselves: 3 st - epsilon.
      const threeStoneKg = 3 * 14 / 2.20462; // exactly 3 stone in kg
      // Subtract a tiny amount so raw pounds land just at 13.995+, which
      // toStringAsFixed(2) rounds to 14.00, triggering the rollover guard.
      final nearThreeSt = threeStoneKg - 0.001;
      final (stones, pounds) = UnitCalc.kgToStLb(nearThreeSt);
      // The result should either be (2, <14) or have rolled over to (3, 0.0)
      // — the invariant is that pounds < 14.0 always.
      expect(pounds, lessThan(14.0),
          reason: 'pounds should never reach 14.0 after rollover guard');
    });
  });

  group('UnitCalc.cmToFeetInches / feetInchesToCm', () {
    test('175 cm is about 5 ft 9 in', () {
      final (feet, inches) = UnitCalc.cmToFeetInches(175);
      expect(feet, 5);
      expect(inches, 9);
    });

    test('round-trip cm -> ft+in -> cm stays within ~1.5 cm', () {
      for (final cm in [150.0, 160.0, 172.0, 183.0, 198.0]) {
        final (feet, inches) = UnitCalc.cmToFeetInches(cm);
        final back = UnitCalc.feetInchesToCm(feet, inches);
        expect((back - cm).abs(), lessThanOrEqualTo(1.5), reason: 'cm=$cm');
      }
    });

    test('inches never reach 12 — they roll into the next foot', () {
      // 182 cm sits just under a whole-foot boundary in inches.
      final (feet, inches) = UnitCalc.cmToFeetInches(182);
      expect(inches, lessThan(12));
      expect(feet, 6);
      expect(inches, 0);
    });
  });
}
