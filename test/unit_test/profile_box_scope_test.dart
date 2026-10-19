import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/utils/profile_box_scope.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('profile_scope').path);
    registerHiveAdaptersOnce();
  });

  tearDownAll(Hive.close);

  test(
    'hands out the profile\'s boxes and the device\'s shared ones',
    () async {
      final customMeals = await Hive.openBox<MealDBO>('shared_meals');
      final recipes = await Hive.openBox<RecipeDBO>('shared_recipes');
      final templates = await Hive.openBox<CustomActivityTemplateDBO>(
        'shared_templates',
      );
      final appConfig = await Hive.openBox<ConfigDBO>('shared_app_config');
      final profiles = await Hive.openBox<ProfileDBO>('shared_profiles');
      final device = FakeHiveDBProvider(
        activeProfileId: 'active',
        appConfigBox: appConfig,
        customMealBox: customMeals,
        recipeBox: recipes,
        customActivityTemplateBox: templates,
        profileBox: profiles,
      );
      final intake = await Hive.openBox<IntakeDBO>('other_intake');
      final config = await Hive.openBox<ConfigDBO>('other_config');

      final scope = ProfileBoxScope(
        shared: device,
        profileId: 'other',
        configBox: config,
        intakeBox: intake,
        userActivityBox: await Hive.openBox<UserActivityDBO>('other_activity'),
        userBox: await Hive.openBox<UserDBO>('other_user'),
        trackedDayBox: await Hive.openBox<TrackedDayDBO>('other_tracked'),
        weightLogBox: await Hive.openBox<WeightLogDBO>('other_weight'),
        waterIntakeBox: await Hive.openBox<WaterIntakeDBO>('other_water'),
        fastingBox: await Hive.openBox<FastingSessionDBO>('other_fasting'),
      );

      expect(scope.activeProfileId, 'other');
      expect(scope.intakeBox, same(intake));
      expect(scope.configBox, same(config));
      expect(scope.customMealBox, same(customMeals));
      expect(scope.recipeBox, same(recipes));
      expect(scope.customActivityTemplateBox, same(templates));
      expect(scope.appConfigBox, same(appConfig));
      expect(scope.profileBox, same(profiles));
    },
  );
}
