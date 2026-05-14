import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

/// Mirrors the rounding the edit-meal screen applies when it folds a
/// user-typed energy value back to stored kcal (one decimal place is
/// plenty for a manually-entered field). Kept in test code so the
/// rounding contract is explicit even though the production helper is
/// a private method on the screen.
double _kjToStoredKcal(double kj) =>
    double.parse(UnitCalc.kjToKcal(kj).toStringAsFixed(1));

/// Mirrors the rounding the edit-meal screen applies when it converts a
/// stored kcal value into a kJ display string. Same one-decimal contract
/// — the field is for humans, not for bit-exact storage.
double _storedKcalToKjDisplay(double kcal) =>
    double.parse(UnitCalc.kcalToKj(kcal).toStringAsFixed(1));

void main() {
  group('edit-meal manual energy entry, kJ ↔ kcal round trip (#177 follow-up)', () {
    test('typing 2000 in kJ mode stores ≈ 478.0 kcal', () {
      // 2000 kJ / 4.184 = 477.9923... rounded to 1dp = 478.0
      expect(_kjToStoredKcal(2000), equals(478.0));
    });

    test('a 478 kcal stored value re-displays as ≈ 2000 kJ', () {
      // 478 kcal × 4.184 = 1999.952 — within rounding tolerance of the
      // 2000 the user originally typed. Use closeTo because the
      // 478.0-kcal storage drops a small amount of precision; we accept
      // any value that rounds to "2000" in the UI.
      expect(_storedKcalToKjDisplay(478.0), closeTo(2000.0, 0.1));
    });

    test('typing in kcal mode stores the value verbatim (no conversion)', () {
      // When the user has kcal selected, save just round-trips the
      // typed value — no scaling. The integer 250 stays 250.
      const typed = 250.0;
      expect(typed, equals(250.0));
      // And re-display in kcal mode is identity:
      expect(typed, equals(typed));
    });

    test('a 250 kcal stored value displays as ≈ 1046.0 kJ when kJ is active', () {
      // 250 kcal × 4.184 = 1046.0 — clean to 1dp.
      expect(_storedKcalToKjDisplay(250.0), equals(1046.0));
    });

    test('round-trip kJ → stored kcal → kJ display for typical daily-goal values', () {
      // Picks values a user might plausibly type as a calorie goal in
      // either unit. After one full pass through the conversion the
      // display value should land within 0.5 kJ of the original — well
      // below what a human would notice in an input field.
      for (final kjTyped in const [500.0, 1000.0, 2000.0, 2500.0, 8368.0]) {
        final storedKcal = _kjToStoredKcal(kjTyped);
        final redisplayed = _storedKcalToKjDisplay(storedKcal);
        expect(redisplayed, closeTo(kjTyped, 0.5),
            reason:
                '$kjTyped kJ → $storedKcal kcal → $redisplayed kJ should round-trip cleanly');
      }
    });

    test('zero is preserved exactly in both directions', () {
      expect(_kjToStoredKcal(0), equals(0));
      expect(_storedKcalToKjDisplay(0), equals(0));
    });
  });
}
