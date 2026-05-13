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
    test('rounds to whole pounds', () {
      expect(UnitCalc.kgToLbs(50), equals(110));
      expect(UnitCalc.kgToLbs(70), equals(154));
      expect(UnitCalc.kgToLbs(100), equals(220));
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
}
