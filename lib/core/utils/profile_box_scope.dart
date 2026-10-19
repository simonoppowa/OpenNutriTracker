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
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Opens, closes and deletes the box-set of a profile that may not be the
/// active one, for operations that touch every profile (the all-profiles
/// backup).
abstract class ProfileScopes {
  /// A provider whose per-profile boxes are [profile]'s and whose shared
  /// boxes are the app's.
  Future<HiveDBProvider> open(ProfileDBO profile);

  /// Closes what [open] opened for [profile]; a no-op for the active one.
  Future<void> close(ProfileDBO profile);

  /// Removes [profile]'s box-set from disk. Never called for the active one.
  Future<void> delete(ProfileDBO profile);
}

/// [ProfileScopes] on the app's real [HiveDBProvider]. The active profile
/// is answered with the provider itself, so its open boxes are never opened
/// a second time or closed under the running app.
class HiveProfileScopes implements ProfileScopes {
  final HiveDBProvider _db;

  HiveProfileScopes(this._db);

  @override
  Future<HiveDBProvider> open(ProfileDBO profile) async {
    if (profile.id == _db.activeProfileId) return _db;
    final suffix = profile.boxSuffix;
    return ProfileBoxScope(
      shared: _db,
      profileId: profile.id,
      configBox: await _db.openScopedBox<ConfigDBO>(
        HiveDBProvider.configBoxName,
        suffix,
      ),
      intakeBox: await _db.openScopedBox<IntakeDBO>(
        HiveDBProvider.intakeBoxName,
        suffix,
      ),
      userActivityBox: await _db.openScopedBox<UserActivityDBO>(
        HiveDBProvider.userActivityBoxName,
        suffix,
      ),
      userBox: await _db.openScopedBox<UserDBO>(
        HiveDBProvider.userBoxName,
        suffix,
      ),
      trackedDayBox: await _db.openScopedBox<TrackedDayDBO>(
        HiveDBProvider.trackedDayBoxName,
        suffix,
      ),
      weightLogBox: await _db.openScopedBox<WeightLogDBO>(
        HiveDBProvider.weightLogBoxName,
        suffix,
      ),
      waterIntakeBox: await _db.openScopedBox<WaterIntakeDBO>(
        HiveDBProvider.waterIntakeBoxName,
        suffix,
      ),
      fastingBox: await _db.openScopedBox<FastingSessionDBO>(
        HiveDBProvider.fastingBoxName,
        suffix,
      ),
      favoriteBox: await _db.openScopedBox<String>(
        HiveDBProvider.favoriteBoxName,
        suffix,
      ),
      bodyMeasurementBox: await _db.openScopedBox<String>(
        HiveDBProvider.bodyMeasurementBoxName,
        suffix,
      ),
    );
  }

  @override
  Future<void> close(ProfileDBO profile) async {
    if (profile.id == _db.activeProfileId) return;
    final suffix = profile.boxSuffix;
    await Future.wait([
      _db.closeScopedBox<ConfigDBO>(HiveDBProvider.configBoxName, suffix),
      _db.closeScopedBox<IntakeDBO>(HiveDBProvider.intakeBoxName, suffix),
      _db.closeScopedBox<UserActivityDBO>(
        HiveDBProvider.userActivityBoxName,
        suffix,
      ),
      _db.closeScopedBox<UserDBO>(HiveDBProvider.userBoxName, suffix),
      _db.closeScopedBox<TrackedDayDBO>(
        HiveDBProvider.trackedDayBoxName,
        suffix,
      ),
      _db.closeScopedBox<WeightLogDBO>(HiveDBProvider.weightLogBoxName, suffix),
      _db.closeScopedBox<WaterIntakeDBO>(
        HiveDBProvider.waterIntakeBoxName,
        suffix,
      ),
      _db.closeScopedBox<FastingSessionDBO>(
        HiveDBProvider.fastingBoxName,
        suffix,
      ),
      _db.closeScopedBox<String>(HiveDBProvider.favoriteBoxName, suffix),
      _db.closeScopedBox<String>(
        HiveDBProvider.bodyMeasurementBoxName,
        suffix,
      ),
    ]);
  }

  @override
  Future<void> delete(ProfileDBO profile) async {
    await close(profile);
    await _db.deleteProfileBoxes(profile.boxSuffix);
  }
}

/// A [HiveDBProvider] that hands out one profile's per-profile boxes and the
/// app's shared boxes, so the existing data sources and usecases run
/// unchanged against a profile that is not active. Unlike
/// `ScopedHiveDBProvider` it carries every per-profile box.
class ProfileBoxScope extends HiveDBProvider {
  final HiveDBProvider _shared;
  final String _profileId;
  final Box<ConfigDBO> _config;
  final Box<IntakeDBO> _intake;
  final Box<UserActivityDBO> _userActivity;
  final Box<UserDBO> _user;
  final Box<TrackedDayDBO> _trackedDay;
  final Box<WeightLogDBO> _weightLog;
  final Box<WaterIntakeDBO> _waterIntake;
  final Box<FastingSessionDBO> _fasting;
  final Box<String> _favorite;
  final Box<String> _bodyMeasurement;

  ProfileBoxScope({
    required HiveDBProvider shared,
    required String profileId,
    required Box<ConfigDBO> configBox,
    required Box<IntakeDBO> intakeBox,
    required Box<UserActivityDBO> userActivityBox,
    required Box<UserDBO> userBox,
    required Box<TrackedDayDBO> trackedDayBox,
    required Box<WeightLogDBO> weightLogBox,
    required Box<WaterIntakeDBO> waterIntakeBox,
    required Box<FastingSessionDBO> fastingBox,
    required Box<String> favoriteBox,
    required Box<String> bodyMeasurementBox,
  }) : _shared = shared,
       _profileId = profileId,
       _config = configBox,
       _intake = intakeBox,
       _userActivity = userActivityBox,
       _user = userBox,
       _trackedDay = trackedDayBox,
       _weightLog = weightLogBox,
       _waterIntake = waterIntakeBox,
       _fasting = fastingBox,
       _favorite = favoriteBox,
       _bodyMeasurement = bodyMeasurementBox;

  @override
  String get activeProfileId => _profileId;

  @override
  Box<ConfigDBO> get configBox => _config;
  @override
  Box<IntakeDBO> get intakeBox => _intake;
  @override
  Box<UserActivityDBO> get userActivityBox => _userActivity;
  @override
  Box<UserDBO> get userBox => _user;
  @override
  Box<TrackedDayDBO> get trackedDayBox => _trackedDay;
  @override
  Box<WeightLogDBO> get weightLogBox => _weightLog;
  @override
  Box<WaterIntakeDBO> get waterIntakeBox => _waterIntake;
  @override
  Box<FastingSessionDBO> get fastingBox => _fasting;
  @override
  Box<String> get favoriteBox => _favorite;
  @override
  Box<String> get bodyMeasurementBox => _bodyMeasurement;

  @override
  Box<ConfigDBO> get appConfigBox => _shared.appConfigBox;
  @override
  Box<MealDBO> get customMealBox => _shared.customMealBox;
  @override
  Box<RecipeDBO> get recipeBox => _shared.recipeBox;
  @override
  Box<CustomActivityTemplateDBO> get customActivityTemplateBox =>
      _shared.customActivityTemplateBox;
  @override
  Box<MealDBO> get cachedOffMealBox => _shared.cachedOffMealBox;
  @override
  Box<int> get cachedOffMealTimestampsBox => _shared.cachedOffMealTimestampsBox;
  @override
  Box<ProfileDBO> get profileBox => _shared.profileBox;
}
