import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/calories_profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/features/fasting/data/data_source/fasting_data_source.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/profiles_backup.dart';

/// The data this fork adds to the JSON backup on top of upstream's files:
/// the water log, the fasting sessions, the saved custom meals, the user
/// profile and the device-wide app settings.
///
/// Kept apart from `ExportDataUsecase` / `ImportDataUsecase` so the fork's
/// additions stay in one place and upstream merges touch as little as
/// possible: the usecases only call [addTo] and [prepareRestore].
///
/// Every file here is optional on restore, so a zip from upstream or from an
/// older build of the fork still imports.
class PersonalBackupExtras {
  static const waterIntakeFileName = 'water_intake.json';
  static const customMealsFileName = 'custom_meals.json';
  static const userProfileFileName = 'user_profile.json';
  static const appSettingsFileName = 'app_settings.json';
  static const fastingSessionsFileName = 'fasting_sessions.json';

  /// The `ConfigDBO` JSON keys that `app_settings.json` carries: the
  /// device-wide preferences. Left out on purpose are the legal and consent
  /// flags (a restore must not accept a policy on the user's behalf), the
  /// demo flag, the goals (they travel in `goal_settings.json`), the
  /// health-import state (a per-device watermark) and the day boundary,
  /// which decides how tracked days are keyed.
  static const appSettingKeys = [
    'selectedAppTheme',
    'usesImperialUnits',
    'usesImperialFoodUnits',
    'usesImperialHeightUnits',
    'bodyWeightUnitIndex',
    'usesKilojoules',
    'selectedLocale',
    'showActivityTracking',
    'showMealMacros',
    'showMicronutrients',
    'notificationsEnabled',
    'notificationHour',
    'notificationMinute',
    'customMealFormMode',
    'nutrientPanelVisibility',
    'diarySortPreferences',
    'fastingWarningAcknowledged',
    'useMaterialYou',
    'accentColor',
    'scannerPortraitLock',
    'foodSourceToggles',
    'defaultToRawFoodUnits',
    'lastBackupAt',
    'backupReminderDays',
    'confirmedStoreBarcodes',
    'waterQuickAmountMl',
  ];

  final WaterIntakeRepository _waterIntakeRepository;
  final CustomMealDataSource _customMealDataSource;
  final UserDataSource _userDataSource;
  final ConfigDataSource _configDataSource;
  final FastingDataSource _fastingDataSource;

  /// The other profiles' folders; null for the extras of a single profile's
  /// folder, which must not recurse into the profile list.
  final ProfilesBackup? _profiles;

  PersonalBackupExtras(
    this._waterIntakeRepository,
    this._customMealDataSource,
    this._userDataSource,
    this._configDataSource,
    this._fastingDataSource, {
    ProfilesBackup? profiles,
  }) : _profiles = profiles;

  /// Writes the fork's JSON files into [archive]. `app_settings.json`
  /// records this archive's creation as the last backup, so a restore from
  /// it does not report that there was never one.
  Future<void> addTo(Archive archive) async {
    final water = await _waterIntakeRepository.getAllEntriesDBO();
    _addJson(archive, waterIntakeFileName, [
      for (final entry in water) entry.toJson(),
    ]);
    _addJson(archive, fastingSessionsFileName, [
      for (final session in await _fastingDataSource.allSessions())
        session.toJson(),
    ]);
    _addJson(archive, customMealsFileName, [
      for (final meal in _customMealDataSource.getAllCustomMeals())
        meal.toJson(),
    ]);
    if (await _userDataSource.hasUserData()) {
      _addJson(
        archive,
        userProfileFileName,
        _userToJson(await _userDataSource.getUserData()),
      );
    }
    final config = (await _configDataSource.getConfig()).toJson();
    _addJson(archive, appSettingsFileName, {
      for (final key in appSettingKeys)
        if (config.containsKey(key)) key: config[key],
      'lastBackupAt': DateTime.now().toIso8601String(),
    });
    await _profiles?.addTo(archive);
  }

  /// Decodes everything the fork restores from [archive] and returns the
  /// writes, so a malformed file throws an [ExportImportFailure] here, before
  /// the caller has written anything.
  ///
  /// Water entries and fasting sessions are keyed by id and saved custom
  /// meals by barcode (or by
  /// name when they have none), so restoring the same backup twice replaces
  /// them instead of adding them again. The meals' photos travel as
  /// `meal_images/` entries, which upstream's import already writes back.
  ///
  /// With [includeProfileAndSettings] false the profile and the app settings
  /// on the device stay as they are; `ImportDataUsecase` then also skips the
  /// goal settings. With [replaceExisting] the returned
  /// [PreparedRestore.clearForReplace] empties what the backup restores (see
  /// [ProfilesBackup.prepareRestore]).
  PreparedRestore prepareRestore(
    Archive archive, {
    bool includeProfileAndSettings = true,
    bool replaceExisting = false,
  }) {
    final water = _decodeList(
      archive.findFile(waterIntakeFileName),
      WaterIntakeDBO.fromJson,
    );
    final fasting = _decodeList(
      archive.findFile(fastingSessionsFileName),
      FastingSessionDBO.fromJson,
    );
    final customMeals = _decodeList(
      archive.findFile(customMealsFileName),
      MealDBO.fromJson,
    );
    final user = includeProfileAndSettings
        ? _decodeMap(archive.findFile(userProfileFileName), _userFromJson)
        : null;
    final settings = includeProfileAndSettings
        ? _decodeMap(archive.findFile(appSettingsFileName), (json) {
            final picked = {
              for (final key in appSettingKeys)
                if (json.containsKey(key)) key: json[key],
            };
            ConfigDBO.fromJson({..._emptyConfigJson, ...picked});
            return picked;
          })
        : null;

    final profiles = _profiles?.prepareRestore(
      archive,
      includeProfileAndSettings: includeProfileAndSettings,
      replaceExisting: replaceExisting,
    );

    Future<void> write() async {
      if (water != null) {
        await _waterIntakeRepository.addAllEntries(water);
      }
      for (final session in fasting ?? const <FastingSessionDBO>[]) {
        await _fastingDataSource.updateSession(session);
      }
      for (final meal in customMeals ?? const <MealDBO>[]) {
        await _customMealDataSource.saveCustomMeal(meal);
      }
      if (user != null) {
        await _userDataSource.saveUserData(user);
      }
      if (settings != null) {
        final current = (await _configDataSource.getConfig()).toJson();
        await _configDataSource.addConfig(
          ConfigDBO.fromJson({...current, ...settings}),
        );
      }
      await profiles?.write();
    }

    return PreparedRestore(
      clearForReplace: profiles?.clearForReplace ?? () async {},
      write: write,
    );
  }

  /// Decodes a `user_profile.json` object, throwing on an unknown or missing
  /// value.
  static UserDBO decodeUserProfile(Map<String, dynamic> json) =>
      _userFromJson(json);

  static final _emptyConfigJson = ConfigDBO.empty().toJson();

  static Map<String, dynamic> _userToJson(UserDBO user) => {
    'birthday': user.birthday.toIso8601String(),
    'heightCM': user.heightCM,
    'weightKG': user.weightKG,
    'gender': user.gender.name,
    'goal': user.goal.name,
    'pal': user.pal.name,
    'weeklyWeightGoalKg': user.weeklyWeightGoalKg,
    'caloriesProfile': user.caloriesProfile?.name,
    'targetWeightKg': user.targetWeightKg,
    'caloriesTaperEnabled': user.caloriesTaperEnabled,
  };

  static UserDBO _userFromJson(Map<String, dynamic> json) {
    final caloriesProfile = json['caloriesProfile'] as String?;
    return UserDBO(
      birthday: DateTime.parse(json['birthday'] as String),
      heightCM: (json['heightCM'] as num).toDouble(),
      weightKG: (json['weightKG'] as num).toDouble(),
      gender: UserGenderDBO.values.byName(json['gender'] as String),
      goal: UserWeightGoalDBO.values.byName(json['goal'] as String),
      pal: UserPALDBO.values.byName(json['pal'] as String),
      weeklyWeightGoalKg: (json['weeklyWeightGoalKg'] as num?)?.toDouble(),
      caloriesProfile: caloriesProfile == null
          ? null
          : CaloriesProfileDBO.values.byName(caloriesProfile),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      caloriesTaperEnabled: json['caloriesTaperEnabled'] as bool? ?? false,
    );
  }

  /// [jsonDecode] of [file], but a number too large for a double (`1e400`)
  /// is a [FormatException], as in upstream's import: stored on the device it
  /// would make the next JSON export throw.
  static Object? _decodeFinite(ArchiveFile file) => jsonDecode(
    utf8.decode(file.content as List<int>),
    reviver: (key, value) {
      if (value is double && !value.isFinite) {
        throw FormatException('Not a finite number', '$key');
      }
      return value;
    },
  );

  static void _addJson(Archive archive, String name, Object json) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(jsonEncode(json))));
  }

  static List<T>? _decodeList<T>(
    ArchiveFile? file,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (file == null) return null;
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${file.name}',
      () => (_decodeFinite(file) as List)
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
    );
  }

  static T? _decodeMap<T>(
    ArchiveFile? file,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (file == null) return null;
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${file.name}',
      () => fromJson(_decodeFinite(file) as Map<String, dynamic>),
    );
  }
}
