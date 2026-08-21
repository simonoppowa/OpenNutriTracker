import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/core/utils/calc/healthy_weight_calc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';

void main() {
  group('HealthyWeightRange.forHeightCm', () {
    test('180 cm spans roughly 60 to 81 kg', () {
      final range = HealthyWeightRange.forHeightCm(180);

      expect(range.minKg, closeTo(59.9, 0.1));
      expect(range.maxKg, closeTo(80.7, 0.1));
    });

    test('the edges land exactly on the WHO band', () {
      const heightCm = 172.0;
      final range = HealthyWeightRange.forHeightCm(heightCm);
      final heightM2 = (heightCm / 100) * (heightCm / 100);

      expect(range.minKg / heightM2, closeTo(BMICalc.healthyBmiMin, 0.0001));
      expect(
        range.maxKg / heightM2,
        closeTo(BMICalc.healthyBmiMaxInclusive, 0.0001),
      );
    });

    test('both edges classify as normal weight', () {
      const heightCm = 165.0;
      final range = HealthyWeightRange.forHeightCm(heightCm);
      final heightM2 = (heightCm / 100) * (heightCm / 100);

      expect(
        BMICalc.getNutritionalStatus(range.minKg / heightM2),
        UserNutritionalStatus.normalWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(range.maxKg / heightM2),
        UserNutritionalStatus.normalWeight,
        reason: 'the upper edge must not already read as pre-obesity',
      );
    });

    test('midpoint is BMI 21.7 at any height', () {
      for (final heightCm in [150.0, 175.0, 200.0]) {
        final range = HealthyWeightRange.forHeightCm(heightCm);
        final heightM2 = (heightCm / 100) * (heightCm / 100);
        expect(
          range.midpointKg / heightM2,
          closeTo(21.7, 0.0001),
          reason: '$heightCm cm',
        );
      }
    });
  });

  group('suggestionFor', () {
    final range = HealthyWeightRange.forHeightCm(180);

    test('offers the current weight when it is already healthy', () {
      expect(range.suggestionFor(75), 75);
      expect(
        range.suggestionFor(range.maxKg),
        range.maxKg,
        reason: 'the upper edge is inside the band, so maintain',
      );
    });

    test('offers the midpoint when above the band', () {
      expect(range.suggestionFor(110), range.midpointKg);
    });

    test('offers the midpoint when below the band', () {
      expect(range.suggestionFor(50), range.midpointKg);
    });
  });

  group('plausibility bands', () {
    test('ordinary heights and weights pass without asking', () {
      expect(ValueValidator.isPlausibleHeightCm(170), isTrue);
      expect(ValueValidator.isPlausibleWeightKg(70), isTrue);
    });

    test('typos inside the hard bounds are caught', () {
      // Both of these are accepted by Ranges (30-300 cm, 2-640 kg), which
      // is why the softer band exists.
      expect(ValueValidator.isPlausibleHeightCm(9), isFalse);
      expect(ValueValidator.isPlausibleWeightKg(4.5), isFalse);
    });

    test('the band edges themselves are plausible', () {
      expect(ValueValidator.isPlausibleHeightCm(120), isTrue);
      expect(ValueValidator.isPlausibleHeightCm(230), isTrue);
      expect(ValueValidator.isPlausibleWeightKg(30), isTrue);
      expect(ValueValidator.isPlausibleWeightKg(300), isTrue);
    });

    test('just outside the edges is not', () {
      expect(ValueValidator.isPlausibleHeightCm(119.9), isFalse);
      expect(ValueValidator.isPlausibleHeightCm(230.1), isFalse);
      expect(ValueValidator.isPlausibleWeightKg(29.9), isFalse);
      expect(ValueValidator.isPlausibleWeightKg(300.1), isFalse);
    });
  });
}
