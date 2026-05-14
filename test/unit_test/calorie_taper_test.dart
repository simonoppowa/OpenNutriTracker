import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

/// #119 follow-up: tests for the optional linear calorie taper.
///
/// The taper scales the daily kcal deficit (or surplus, for gainers)
/// down as the user's current weight approaches their target weight,
/// so the last few kg feel like maintenance rather than an ever-thinner
/// slice of food. These tests pin the four corners of the curve plus
/// the toggle-off escape hatch.
void main() {
  group('Calorie taper helper', () {
    test('toggle off returns the raw adjustment regardless of distance', () {
      final result = CalorieGoalCalc.applyTargetWeightTaper(
        baseAdjustment: -500,
        currentWeightKg: 80,
        targetWeightKg: 75,
        goal: UserWeightGoalEntity.loseWeight,
        taperEnabled: false,
      );
      expect(result, equals(-500));
    });

    test('null target weight returns the raw adjustment', () {
      final result = CalorieGoalCalc.applyTargetWeightTaper(
        baseAdjustment: -500,
        currentWeightKg: 80,
        targetWeightKg: null,
        goal: UserWeightGoalEntity.loseWeight,
        taperEnabled: true,
      );
      expect(result, equals(-500));
    });

    test('maintenance goal is unaffected by the taper', () {
      final result = CalorieGoalCalc.applyTargetWeightTaper(
        baseAdjustment: 0,
        currentWeightKg: 80,
        targetWeightKg: 75,
        goal: UserWeightGoalEntity.maintainWeight,
        taperEnabled: true,
      );
      expect(result, equals(0));
    });

    group('loseWeight', () {
      test('above 5kg from target keeps the full deficit', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 90, // 15kg above a 75kg target
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(-500));
      });

      test('exactly 5kg from target is still the full deficit', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 80,
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(-500));
      });

      test('midway through the taper interpolates linearly', () {
        // 3kg away → 3km is halfway between the 5kg full and 1kg zero
        // anchors, so the deficit should be half of -500.
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 78,
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, closeTo(-250, 0.0001));
      });

      test('within 1kg of target collapses to zero', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 75.5,
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });

      test('exactly 1kg from target collapses to zero', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 76,
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });

      test('at the target the deficit is zero (maintenance)', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 75,
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });

      test('past the target the deficit is zero', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: -500,
          currentWeightKg: 70, // already below the 75kg target
          targetWeightKg: 75,
          goal: UserWeightGoalEntity.loseWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });
    });

    group('gainWeight', () {
      test('more than 5kg below target keeps the full surplus', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: 500,
          currentWeightKg: 60,
          targetWeightKg: 70,
          goal: UserWeightGoalEntity.gainWeight,
          taperEnabled: true,
        );
        expect(result, equals(500));
      });

      test('midway through the taper interpolates linearly', () {
        // 3kg below target → halfway between full surplus and zero.
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: 500,
          currentWeightKg: 67,
          targetWeightKg: 70,
          goal: UserWeightGoalEntity.gainWeight,
          taperEnabled: true,
        );
        expect(result, closeTo(250, 0.0001));
      });

      test('within 1kg of target collapses to zero', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: 500,
          currentWeightKg: 69.5,
          targetWeightKg: 70,
          goal: UserWeightGoalEntity.gainWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });

      test('past the target the surplus is zero', () {
        final result = CalorieGoalCalc.applyTargetWeightTaper(
          baseAdjustment: 500,
          currentWeightKg: 72, // already above the 70kg target
          targetWeightKg: 70,
          goal: UserWeightGoalEntity.gainWeight,
          taperEnabled: true,
        );
        expect(result, equals(0));
      });
    });
  });
}
