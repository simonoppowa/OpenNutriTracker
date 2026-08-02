import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/goal_suggestion_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';

void main() {
  group('a target weight was entered — it wins over BMI', () {
    test('a lower target suggests losing', () {
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 80,
        targetWeightKg: 72,
      );

      expect(suggestion?.goal, UserGoalSelectionEntity.loseWeight);
      expect(suggestion?.basis, GoalSuggestionBasis.targetWeight);
    });

    test('a higher target suggests gaining', () {
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 60,
        targetWeightKg: 70,
      );

      expect(suggestion?.goal, UserGoalSelectionEntity.gainWeigh);
    });

    test('a target within a kilo of the current weight is maintain', () {
      for (final target in [70.0, 70.9, 69.1]) {
        expect(
          GoalSuggestionEntity.from(
            heightCm: 180,
            weightKg: 70,
            targetWeightKg: target,
          )?.goal,
          UserGoalSelectionEntity.maintainWeight,
          reason: 'target $target',
        );
      }
    });

    test('a healthy BMI does not override the target the user typed', () {
      // BMI 24.7 reads as normal weight, so a BMI-only rule would answer
      // "maintain" to someone who just asked to lose 8 kg.
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 80,
        targetWeightKg: 72,
      );

      expect(suggestion?.goal, UserGoalSelectionEntity.loseWeight);
    });
  });

  group('no target — the WHO BMI band decides', () {
    test('underweight suggests gaining', () {
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 55, // BMI 17.0
        targetWeightKg: null,
      );

      expect(suggestion?.goal, UserGoalSelectionEntity.gainWeigh);
      expect(suggestion?.basis, GoalSuggestionBasis.bmi);
      expect(suggestion?.nutritionalStatus, UserNutritionalStatus.underWeight);
    });

    test('a normal BMI suggests maintaining', () {
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 70, // BMI 21.6
        targetWeightKg: null,
      );

      expect(suggestion?.goal, UserGoalSelectionEntity.maintainWeight);
    });

    test('every band above normal suggests losing', () {
      // 88 kg -> BMI 27.2 (pre-obesity), 110 kg -> 34.0 (class I),
      // 125 kg -> 38.6 (class II), 140 kg -> 43.2 (class III).
      for (final weightKg in [88.0, 110.0, 125.0, 140.0]) {
        expect(
          GoalSuggestionEntity.from(
            heightCm: 180,
            weightKg: weightKg,
            targetWeightKg: null,
          )?.goal,
          UserGoalSelectionEntity.loseWeight,
          reason: '$weightKg kg',
        );
      }
    });

    test('the quoted BMI matches the weight and height', () {
      final suggestion = GoalSuggestionEntity.from(
        heightCm: 180,
        weightKg: 88,
        targetWeightKg: null,
      );

      expect(suggestion?.bmi, closeTo(27.2, 0.05));
      expect(suggestion?.nutritionalStatus, UserNutritionalStatus.preObesity);
    });
  });

  group('not enough information', () {
    test('no weight means no suggestion', () {
      expect(
        GoalSuggestionEntity.from(
          heightCm: 180,
          weightKg: null,
          targetWeightKg: null,
        ),
        isNull,
      );
    });

    test('no height and no target means no suggestion', () {
      expect(
        GoalSuggestionEntity.from(
          heightCm: null,
          weightKg: 80,
          targetWeightKg: null,
        ),
        isNull,
      );
    });

    test('a target still works without a height', () {
      expect(
        GoalSuggestionEntity.from(
          heightCm: null,
          weightKg: 80,
          targetWeightKg: 70,
        )?.goal,
        UserGoalSelectionEntity.loseWeight,
      );
    });
  });
}
