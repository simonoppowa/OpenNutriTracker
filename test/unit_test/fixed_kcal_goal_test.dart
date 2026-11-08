import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

import '../fixture/user_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #671: a fixed daily calorie goal the user types in, instead of only an
/// offset on the calculated estimate.
void main() {
  // Loses weight, so the calculated goal carries a −500 kcal adjustment the
  // fixed goal has to drop.
  final user = UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;

  double calculated({double activities = 0, double? offset}) =>
      CalorieGoalCalc.getTotalKcalGoal(
        user,
        activities,
        kcalUserAdjustment: offset,
      );

  group('CalorieGoalCalc.getTotalKcalGoal with a fixed goal', () {
    test('replaces the TDEE, the weight-goal adjustment and the offset', () {
      expect(
        CalorieGoalCalc.getTotalKcalGoal(
          user,
          0,
          kcalUserAdjustment: 300,
          fixedKcalGoal: 1660,
        ),
        1660,
      );
    });

    test('still adds the kcal burned by logged activities', () {
      expect(
        CalorieGoalCalc.getTotalKcalGoal(user, 250, fixedKcalGoal: 1660),
        1910,
      );
    });

    test('no fixed goal keeps the calculated goal', () {
      expect(
        CalorieGoalCalc.getTotalKcalGoal(
          user,
          120,
          kcalUserAdjustment: -200,
          fixedKcalGoal: null,
        ),
        CalorieGoalCalc.getTdee(user) - 500 - 200 + 120,
      );
    });

    test('accepts the range limits', () {
      for (final limit in [
        Ranges.minFixedDailyKcalGoal,
        Ranges.maxFixedDailyKcalGoal,
      ]) {
        expect(
          CalorieGoalCalc.getTotalKcalGoal(user, 0, fixedKcalGoal: limit),
          limit,
        );
      }
    });

    // A stored value outside the range the dialog allows can only come from
    // corruption or a hand-edited file. Falling back to the calculated goal
    // beats a goal of 0 or NaN on the dashboard.
    for (final bad in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
      0.0,
      -1500.0,
      Ranges.minFixedDailyKcalGoal - 1,
      Ranges.maxFixedDailyKcalGoal + 1,
    ]) {
      test('ignores an invalid stored value ($bad)', () {
        expect(
          CalorieGoalCalc.getTotalKcalGoal(
            user,
            80,
            kcalUserAdjustment: 100,
            fixedKcalGoal: bad,
          ),
          calculated(activities: 80, offset: 100),
        );
      });
    }
  });

  group('KcalGoalBreakdownEntity with a fixed goal', () {
    test('the total is the fixed goal plus activities, and the macros '
        'follow it', () {
      final breakdown = KcalGoalBreakdownEntity.compute(
        user: user,
        userKcalAdjustment: 300,
        fixedKcalGoal: 1800,
        totalKcalActivities: 200,
      );

      expect(breakdown.usesFixedGoal, isTrue);
      expect(breakdown.fixedKcalGoal, 1800);
      expect(breakdown.totalKcalGoal, 2000);
      expect(breakdown.carbsGoalGrams, MacroCalc.getTotalCarbsGoal(2000));
      // The calculated steps are still filled in, for reference.
      expect(breakdown.tdeeKcal, CalorieGoalCalc.getTdee(user));
      expect(breakdown.manualKcalAdjustment, 300);
    });

    test('an invalid stored value reads as no fixed goal', () {
      final breakdown = KcalGoalBreakdownEntity.compute(
        user: user,
        fixedKcalGoal: double.nan,
        totalKcalActivities: 0,
      );

      expect(breakdown.usesFixedGoal, isFalse);
      expect(breakdown.fixedKcalGoal, isNull);
      expect(breakdown.totalKcalGoal, calculated());
    });
  });

  group('stored per profile', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileBox;
    late ConfigDataSource config;
    late GetKcalGoalUsecase kcalGoal;
    late GetKcalGoalBreakdownUsecase breakdown;

    setUp(() async {
      Hive.init('.');
      registerHiveAdaptersOnce();
      final tag = DateTime.now().microsecondsSinceEpoch;
      appBox = await Hive.openBox<ConfigDBO>('fixed_goal_app_$tag');
      profileBox = await Hive.openBox<ConfigDBO>('fixed_goal_profile_$tag');
      final userBox = await Hive.openBox<UserDBO>('fixed_goal_user_$tag');
      final activityBox = await Hive.openBox<UserActivityDBO>(
        'fixed_goal_activity_$tag',
      );
      final provider = FakeHiveDBProvider(
        appConfigBox: appBox,
        configBox: profileBox,
        userBox: userBox,
        userActivityBox: activityBox,
      );
      config = ConfigDataSource(provider);
      await config.initializeConfig();
      await UserDataSource(provider).saveUserData(
        UserDBO(
          birthday: DateTime(1990, 6, 15),
          heightCM: 175,
          weightKG: 62,
          gender: UserGenderDBO.male,
          goal: UserWeightGoalDBO.loseWeight,
          pal: UserPALDBO.active,
        ),
      );
      final users = UserRepository(UserDataSource(provider));
      final activities = UserActivityRepository(
        UserActivityDataSource(provider),
      );
      kcalGoal = GetKcalGoalUsecase(
        users,
        ConfigRepository(config),
        activities,
      );
      breakdown = GetKcalGoalBreakdownUsecase(
        users,
        ConfigRepository(config),
        activities,
      );
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('a fixed goal becomes the daily goal, and clearing it brings back '
        'the calculated goal with the offset kept', () async {
      await config.setConfigKcalAdjustment(-150);
      final before = await kcalGoal.getKcalGoal();

      await config.setConfigFixedKcalGoal(1660);
      expect(await kcalGoal.getKcalGoal(), 1660);
      expect((await breakdown.getBreakdown()).totalKcalGoal, 1660);
      expect(
        (await config.getConfig()).userKcalAdjustment,
        -150,
        reason: 'the offset is kept for when the user switches back',
      );

      await config.setConfigFixedKcalGoal(null);
      expect(await kcalGoal.getKcalGoal(), before);
      expect((await breakdown.getBreakdown()).usesFixedGoal, isFalse);
    });

    test('lives in the profile box, so a profile reset clears it', () async {
      await config.setConfigFixedKcalGoal(2100);
      expect(profileBox.get('ConfigKey')!.userFixedKcalGoal, 2100);

      await profileBox.clear();

      expect((await config.getConfig()).userFixedKcalGoal, isNull);
    });

    test('reaches ConfigEntity', () async {
      await config.setConfigFixedKcalGoal(1900);

      final entity = ConfigEntity.fromConfigDBO(await config.getConfig());

      expect(entity.userFixedKcalGoal, 1900);
    });
  });
}
