import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';

UserEntity _user(UserGenderEntity gender) => UserEntity(
  birthday: DateTime(1990, 1, 1),
  heightCM: 180,
  weightKG: 80,
  gender: gender,
  goal: UserWeightGoalEntity.maintainWeight,
  pal: UserPALEntity.active,
);

TrackedDayEntity _day({
  Map<String, double> extra = const {},
  double calorieGoal = 2400,
  double? carbsGoal,
}) => TrackedDayEntity(
  day: DateTime(2026, 10, 19),
  calorieGoal: calorieGoal,
  caloriesTracked: 0,
  carbsGoal: carbsGoal,
  extraNutrientGoals: extra,
);

void main() {
  group('NutrientPanelRow.all', () {
    test('lists every panel key exactly once', () {
      final keys = [for (final row in NutrientPanelRow.all) row.key];
      expect(keys.toSet(), NutrientPanelKeys.all.toSet());
      expect(keys, hasLength(NutrientPanelKeys.all.length));
    });

    test('covers all 24 stored nutrients', () {
      expect({
        for (final row in NutrientPanelRow.all) row.field,
      }, NutrientField.values.toSet());
    });

    test('keeps each group together', () {
      final groups = [for (final row in NutrientPanelRow.all) row.group];
      final seen = <NutrientPanelGroup>[];
      for (final group in groups) {
        if (seen.isEmpty || seen.last != group) {
          expect(seen, isNot(contains(group)));
          seen.add(group);
        }
      }
      expect(seen, NutrientPanelGroup.values);
    });

    test('extra goal keys are the new non-energy, non-macro keys', () {
      expect(NutrientPanelKeys.extraGoalKeys, hasLength(10));
      expect(
        NutrientPanelKeys.all.toSet().containsAll(
          NutrientPanelKeys.extraGoalKeys,
        ),
        isTrue,
      );
      expect(NutrientPanelKeys.extraGoalKeys, isNot(contains('energy')));
    });
  });

  group('NutrientPanelRow.extraReference', () {
    test('the own goal of the day wins', () {
      expect(
        NutrientPanelRow.extraReference(
          NutrientPanelKeys.zinc,
          trackedDay: _day(extra: {NutrientPanelKeys.zinc: 14}),
          user: _user(UserGenderEntity.male),
        ),
        14,
      );
    });

    test('energy and macros follow the day goals', () {
      final day = _day(calorieGoal: 2400, carbsGoal: 300);
      expect(
        NutrientPanelRow.extraReference(
          NutrientPanelKeys.energy,
          trackedDay: day,
        ),
        2400,
      );
      expect(
        NutrientPanelRow.extraReference(
          NutrientPanelKeys.carbohydrates,
          trackedDay: day,
        ),
        300,
      );
      expect(
        NutrientPanelRow.extraReference(NutrientPanelKeys.fat, trackedDay: day),
        78,
      );
    });

    test('the IOM value for the user, else the default', () {
      expect(
        NutrientPanelRow.extraReference(
          NutrientPanelKeys.zinc,
          user: _user(UserGenderEntity.male),
        ),
        11,
      );
      expect(
        NutrientPanelRow.extraReference(
          NutrientPanelKeys.vitaminC,
          user: _user(UserGenderEntity.female),
        ),
        75,
      );
      expect(NutrientPanelRow.extraReference(NutrientPanelKeys.zinc), 9.5);
    });

    test('mono- and polyunsaturated and trans fat have none', () {
      for (final key in [
        NutrientPanelKeys.monounsaturatedFat,
        NutrientPanelKeys.polyunsaturatedFat,
        NutrientPanelKeys.transFat,
      ]) {
        expect(
          NutrientPanelRow.extraReference(
            key,
            user: _user(UserGenderEntity.male),
          ),
          isNull,
        );
      }
    });
  });

  group('extra nutrient goals on the tracked day', () {
    test('survive the JSON of the backup', () {
      final dbo = TrackedDayDBO(
        day: DateTime(2026, 10, 19),
        calorieGoal: 2000,
        caloriesTracked: 0,
        extraNutrientGoals: {NutrientPanelKeys.zinc: 12, 'vitamin_c': 100},
      );

      final restored = TrackedDayDBO.fromJson(dbo.toJson());

      expect(restored.extraNutrientGoals, {
        NutrientPanelKeys.zinc: 12.0,
        'vitamin_c': 100.0,
      });
    });

    test('an old backup without them reads as none', () {
      final json = TrackedDayDBO(
        day: DateTime(2026, 10, 19),
        calorieGoal: 2000,
        caloriesTracked: 0,
      ).toJson()..remove('extraNutrientGoals');

      final restored = TrackedDayDBO.fromJson(json);

      expect(restored.extraNutrientGoals, isNull);
      expect(
        TrackedDayEntity.fromTrackedDayDBO(restored).extraNutrientGoals,
        isEmpty,
      );
    });

    test('pass from the entity to the DBO and back', () {
      final entity = _day(extra: {NutrientPanelKeys.niacin: 18});

      final dbo = TrackedDayDBO.fromTrackedDayEntity(entity);

      expect(dbo.extraNutrientGoals, {NutrientPanelKeys.niacin: 18});
      expect(TrackedDayEntity.fromTrackedDayDBO(dbo).extraNutrientGoals, {
        NutrientPanelKeys.niacin: 18,
      });
    });
  });
}
