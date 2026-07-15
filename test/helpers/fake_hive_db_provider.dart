import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Test double for [HiveDBProvider]. Data sources now resolve their box
/// through the provider, so unit tests inject the box(es) they need here.
/// Accessing a box that wasn't provided throws, which keeps tests honest
/// about what they actually touch.
class FakeHiveDBProvider extends HiveDBProvider {
  final Box<ConfigDBO>? _configBox;
  final Box<ConfigDBO>? _appConfigBox;
  final Box<IntakeDBO>? _intakeBox;
  final Box<UserActivityDBO>? _userActivityBox;
  final Box<UserDBO>? _userBox;
  final Box<TrackedDayDBO>? _trackedDayBox;
  final Box<MealDBO>? _customMealBox;
  final Box<RecipeDBO>? _recipeBox;
  final Box<CustomActivityTemplateDBO>? _customActivityTemplateBox;
  final Box<WeightLogDBO>? _weightLogBox;
  final Box<WaterIntakeDBO>? _waterIntakeBox;
  final Box<FastingSessionDBO>? _fastingBox;

  FakeHiveDBProvider({
    Box<ConfigDBO>? configBox,
    Box<ConfigDBO>? appConfigBox,
    Box<IntakeDBO>? intakeBox,
    Box<UserActivityDBO>? userActivityBox,
    Box<UserDBO>? userBox,
    Box<TrackedDayDBO>? trackedDayBox,
    Box<MealDBO>? customMealBox,
    Box<RecipeDBO>? recipeBox,
    Box<CustomActivityTemplateDBO>? customActivityTemplateBox,
    Box<WeightLogDBO>? weightLogBox,
    Box<WaterIntakeDBO>? waterIntakeBox,
    Box<FastingSessionDBO>? fastingBox,
  })  : _configBox = configBox,
        _appConfigBox = appConfigBox ?? configBox,
        _intakeBox = intakeBox,
        _userActivityBox = userActivityBox,
        _userBox = userBox,
        _trackedDayBox = trackedDayBox,
        _customMealBox = customMealBox,
        _recipeBox = recipeBox,
        _customActivityTemplateBox = customActivityTemplateBox,
        _weightLogBox = weightLogBox,
        _waterIntakeBox = waterIntakeBox,
        _fastingBox = fastingBox;

  T _require<T>(T? box) {
    if (box == null) {
      throw StateError('FakeHiveDBProvider: box not provided for this test');
    }
    return box;
  }

  @override
  Box<ConfigDBO> get configBox => _require(_configBox);
  @override
  Box<ConfigDBO> get appConfigBox => _require(_appConfigBox);
  @override
  Box<IntakeDBO> get intakeBox => _require(_intakeBox);
  @override
  Box<UserActivityDBO> get userActivityBox => _require(_userActivityBox);
  @override
  Box<UserDBO> get userBox => _require(_userBox);
  @override
  Box<TrackedDayDBO> get trackedDayBox => _require(_trackedDayBox);
  @override
  Box<MealDBO> get customMealBox => _require(_customMealBox);
  @override
  Box<RecipeDBO> get recipeBox => _require(_recipeBox);
  @override
  Box<CustomActivityTemplateDBO> get customActivityTemplateBox =>
      _require(_customActivityTemplateBox);
  @override
  Box<WeightLogDBO> get weightLogBox => _require(_weightLogBox);
  @override
  Box<WaterIntakeDBO> get waterIntakeBox => _require(_waterIntakeBox);
  @override
  Box<FastingSessionDBO> get fastingBox => _require(_fastingBox);
}
