import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/onboarding/domain/usecase/restore_backup_usecase.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../../helpers/fake_hive_db_provider.dart';
import '../../../helpers/hive_test_setup.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// Same shape as `import_data_usecase_upsert_test.dart`.
final class _PickedFile extends PlatformFile {
  _PickedFile(this.name, this.uri);

  @override
  final String name;

  @override
  final Uri uri;

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() => File(path!).length();

  @override
  Future<Uint8List> readAsBytes() => File(path!).readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => File(path!).openRead().cast();
}

class _UnusedSearchCache extends Fake implements RemoteSearchCacheDataSource {}

class _UnusedSetDayBoundary extends Fake implements SetDayBoundaryUsecase {}

class _UnusedImportData extends Fake implements ImportDataUsecase {}

/// The reminder stays off in these tests, which cancels it.
class _NoNotifications extends NotificationService {
  @override
  Future<void> cancelDailyReminder() async {}
}

/// A `user_intake.json` row for a custom food, as the exporter writes it.
///
/// It carries no `dataVersion` on the meal, like every backup written
/// before #775.
Map<String, dynamic> _intakeJson(String id, DateTime at) => {
  'id': id,
  'unit': 'g',
  'amount': 100.0,
  'type': 'breakfast',
  'dateTime': at.toIso8601String(),
  'meal': {
    'code': null,
    'name': 'Porridge $id',
    'brands': null,
    'thumbnailImageUrl': null,
    'mainImageUrl': null,
    'url': null,
    'mealQuantity': '100',
    'mealUnit': 'g',
    'servingQuantity': null,
    'servingUnit': null,
    'servingSize': null,
    'source': 'custom',
    'nutriments': {
      'energyKcal100': 120.0,
      'carbohydrates100': 20.0,
      'fat100': 2.0,
      'proteins100': 4.0,
      'sugars100': 1.0,
      'saturatedFat100': 0.5,
      'fiber100': 3.0,
    },
  },
};

/// The body profile someone enters on the new phone. A backup has none.
UserEntity _newPhoneUser() => UserEntity(
  birthday: DateTime(1990, 6, 15),
  heightCM: 180,
  weightKG: 78,
  gender: UserGenderEntity.male,
  goal: UserWeightGoalEntity.loseWeight,
  pal: UserPALEntity.active,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late List<Box<dynamic>> boxes;
  late Box<ConfigDBO> profileConfigBox;
  late Box<IntakeDBO> intakeBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<WeightLogDBO> weightLogBox;
  late Box<UserDBO> userBox;
  late ConfigDataSource config;
  late ConfigRepository configRepository;
  late UserRepository userRepository;
  late IntakeRepository intakes;
  late TrackedDayRepository trackedDays;
  late RecipeRepository recipes;
  late WeightLogRepository weightLog;
  late UserActivityRepository activities;
  late ExportDataUsecase exporter;
  late SettingsBloc settingsBloc;
  late OnboardingBloc onboardingBloc;
  late GetKcalGoalUsecase kcalGoal;

  /// What the picker hands back. A test swaps it before restoring.
  late Future<PlatformFile?> Function() pick;
  late int pickCount;
  late List<DateTime> goalDays;
  late RestoreBackupUsecase restore;

  String backupPath() => '${tempDir.path}/backup.zip';

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('restore_backup_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('restore_backup_${name}_$tag');
    final appConfigBox = await open<ConfigDBO>('app_config');
    profileConfigBox = await open<ConfigDBO>('profile_config');
    intakeBox = await open<IntakeDBO>('intake');
    trackedDayBox = await open<TrackedDayDBO>('tracked');
    final activityBox = await open<UserActivityDBO>('activity');
    final recipeBox = await open<RecipeDBO>('recipe');
    final customMealBox = await open<MealDBO>('custom_meal');
    weightLogBox = await open<WeightLogDBO>('weight');
    final templateBox = await open<CustomActivityTemplateDBO>('template');
    final favouriteBox = await open<FavouriteMealDBO>('favourite');
    userBox = await open<UserDBO>('user');
    boxes = [
      userBox,
      appConfigBox,
      profileConfigBox,
      intakeBox,
      trackedDayBox,
      activityBox,
      recipeBox,
      customMealBox,
      weightLogBox,
      templateBox,
      favouriteBox,
    ];
    final provider = FakeHiveDBProvider(
      appConfigBox: appConfigBox,
      configBox: profileConfigBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      userActivityBox: activityBox,
      recipeBox: recipeBox,
      customMealBox: customMealBox,
      weightLogBox: weightLogBox,
      customActivityTemplateBox: templateBox,
      favouriteMealBox: favouriteBox,
      userBox: userBox,
    );
    config = ConfigDataSource(provider);
    await config.initializeConfig();
    configRepository = ConfigRepository(config);

    final userDataSource = UserDataSource(provider);
    userRepository = UserRepository(userDataSource);
    activities = UserActivityRepository(UserActivityDataSource(provider));
    intakes = IntakeRepository(IntakeDataSource(provider));
    trackedDays = TrackedDayRepository(TrackedDayDataSource(provider));
    recipes = RecipeRepository(RecipeDataSource(provider));
    weightLog = WeightLogRepository(WeightLogDataSource(provider));
    final templates = CustomActivityTemplateRepository(
      CustomActivityTemplateDataSource(provider),
    );
    final favourites = FavouriteMealRepository(
      FavouriteMealDataSource(provider),
      CustomMealDataSource(provider),
      RecipeDataSource(provider),
    );
    exporter = ExportDataUsecase(
      activities,
      intakes,
      trackedDays,
      recipes,
      CustomMealDataSource(provider),
      weightLog,
      templates,
      configRepository,
      favourites,
    );
    pickCount = 0;
    pick = () async => _PickedFile('backup.zip', File(backupPath()).uri);
    final importer = ImportDataUsecase(
      activities,
      intakes,
      trackedDays,
      recipes,
      weightLog,
      templates,
      configRepository,
      favourites,
      pickFile: () {
        pickCount++;
        return pick();
      },
    );

    kcalGoal = GetKcalGoalUsecase(userRepository, configRepository, activities);
    settingsBloc = SettingsBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      AddTrackedDayUsecase(trackedDays),
      kcalGoal,
      GetMacroGoalUsecase(configRepository),
      _UnusedSearchCache(),
      GetTrackedDayUsecase(trackedDays),
      _UnusedSetDayBoundary(),
    );
    onboardingBloc = OnboardingBloc(
      AddUserUsecase(userRepository),
      AddConfigUsecase(configRepository),
      GetConfigUsecase(configRepository),
      AddWeightLogUsecase(weightLog, userRepository),
      DailyReminderScheduler(configRepository, _NoNotifications()),
    );

    goalDays = [];
    restore = RestoreBackupUsecase(
      importer,
      hasUserData: userDataSource.hasUserData,
      updateDayGoals: (day) {
        goalDays.add(day);
        return settingsBloc.updateTrackedDay(day);
      },
    );
  });

  tearDown(() async {
    await onboardingBloc.close();
    await settingsBloc.close();
    PathProviderPlatform.instance = originalPathProvider;
    for (final box in boxes) {
      await box.deleteFromDisk();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void writeArchive(Archive archive) =>
      File(backupPath()).writeAsBytesSync(ZipEncoder().encode(archive));

  /// A zip holding exactly [entries].
  void writeZip(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    writeArchive(archive);
  }

  Future<void> expectNothingWritten() async {
    expect(intakeBox.isEmpty, isTrue, reason: 'no intake was written');
    expect(trackedDayBox.isEmpty, isTrue, reason: 'no tracked day');
    expect(weightLogBox.isEmpty, isTrue, reason: 'no weight-log point');
    expect(
      (await config.getConfig()).userKcalAdjustment,
      isNull,
      reason: 'the goal settings are untouched',
    );
  }

  /// The old phone: a body profile, today's breakfast and its tracked day,
  /// a month-old weigh-in and a kcal adjustment, exported as JSON. Then
  /// every box is emptied, as on a fresh install.
  Future<void> exportFromOldPhoneThenReinstall() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await userRepository.updateUserData(
      UserEntity(
        birthday: DateTime(1990, 6, 15),
        heightCM: 180,
        weightKG: 82,
        gender: UserGenderEntity.male,
        goal: UserWeightGoalEntity.loseWeight,
        pal: UserPALEntity.active,
      ),
    );
    await intakes.upsertAllIntakeDBOs([
      IntakeDBO.fromJson(_intakeJson('breakfast-1', today)),
    ]);
    // The goal the old phone stored for today, before the kcal adjustment
    // below: the restore has to replace it.
    await trackedDays.addAllTrackedDays([
      TrackedDayDBO(day: today, calorieGoal: 2900, caloriesTracked: 120),
    ]);
    await weightLog.addAllEntries([
      WeightLogDBO(
        date: today.subtract(const Duration(days: 30)),
        weightKg: 82,
      ),
    ]);
    await config.setConfigKcalAdjustment(-300);

    writeArchive(
      await exporter.assembleArchive(
        format: ExportFormat.json,
        userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
        userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
        trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
        recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
        weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
        customActivityTemplateJsonFileName:
            ExportImportBloc.customActivityTemplateJsonFileName,
        goalSettingsJsonFileName: ExportImportBloc.goalSettingsJsonFileName,
        favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
      ),
    );

    for (final box in boxes) {
      await box.clear();
    }
    await config.initializeConfig();
  }

  /// What the screen does when the last body-profile page's Start is
  /// tapped after a restore.
  Future<void> finishOnboarding() async {
    await onboardingBloc.saveOnboardingData(
      _newPhoneUser(),
      false,
      false,
      BodyWeightUnit.kg,
      false,
      appTheme: AppThemeEntity.system,
      foodSourceToggles: const {},
      dailyReminderEnabled: false,
      reminderLocale: const Locale('en'),
      useMaterialYou: false,
      accentColor: null,
    );
    await restore.syncTodayGoals();
  }

  test('a backup from the old phone restores during onboarding, and once '
      'the body profile is entered Home reads the restored diary and '
      'goals', () async {
    await exportFromOldPhoneThenReinstall();
    expect(await userRepository.hasUserData(), isFalse);

    final result = await restore.restore();

    expect(result.outcome, RestoreBackupOutcome.restored);
    expect(intakeBox.length, 1);
    expect(
      await userRepository.hasUserData(),
      isFalse,
      reason: 'the backup has no body profile; onboarding still asks',
    );

    await finishOnboarding();

    // What Home loads: today's meals and today's goal.
    final breakfast = await GetIntakeUsecase(
      intakes,
      recipes,
    ).getTodayBreakfastIntake();
    expect(breakfast.map((i) => i.meal.name), ['Porridge breakfast-1']);

    final goal = await kcalGoal.getKcalGoal();
    expect(
      (await config.getConfig()).userKcalAdjustment,
      -300,
      reason: 'the goal settings came back with the diary',
    );
    final now = DateTime.now();
    final todayRow = await GetTrackedDayUsecase(
      trackedDays,
    ).getTrackedDay(DateTime(now.year, now.month, now.day));
    expect(todayRow, isNotNull);
    expect(
      todayRow!.calorieGoal,
      goal,
      reason:
          "today's stored goal is recomputed for the new body profile "
          'and the restored adjustment, not the old phone\'s',
    );
    expect(todayRow.caloriesTracked, 120);

    // The weight history keeps the old phone's point and gains today's.
    final weights = await GetWeightLogUsecase(weightLog).getAllEntries();
    expect(weights.map((w) => w.weightKg).toList()..sort(), [78, 82]);
  });

  test('a dismissed picker is not an error and writes nothing', () async {
    pick = () async => null;

    final result = await restore.restore();

    expect(result.outcome, RestoreBackupOutcome.cancelled);
    await expectNothingWritten();
  });

  test(
    'a file that is not a zip fails as unreadable and writes nothing',
    () async {
      File(backupPath()).writeAsStringSync('this is not a zip');

      final result = await restore.restore();

      expect(result.outcome, RestoreBackupOutcome.failed);
      expect(
        result.failureReason,
        ExportImportFailureReason.unreadableOrWrongFormat,
      );
      await expectNothingWritten();
    },
  );

  test('a backup with one corrupt entry is rejected before any entry is '
      'written', () async {
    final now = DateTime.now();
    writeZip({
      ExportImportBloc.userActivityJsonFileName: '[]',
      ExportImportBloc.userIntakeJsonFileName: jsonEncode([
        _intakeJson('a', now),
      ]),
      ExportImportBloc.trackedDayJsonFileName: '[{"day": "not a date"',
      ExportImportBloc.weightLogJsonFileName: jsonEncode([
        WeightLogDBO(date: DateTime(2026, 1, 1), weightKg: 80).toJson(),
      ]),
      ExportImportBloc.goalSettingsJsonFileName: jsonEncode({
        'version': 1,
        'kcalAdjustment': -300.0,
      }),
    });

    final result = await restore.restore();

    expect(result.outcome, RestoreBackupOutcome.failed);
    expect(
      result.failureReason,
      ExportImportFailureReason.unreadableOrWrongFormat,
    );
    await expectNothingWritten();
  });

  test(
    'a zip that is not an OpenNutriTracker backup fails as unreadable',
    () async {
      writeZip({'notes.txt': 'hello'});

      final result = await restore.restore();

      expect(result.outcome, RestoreBackupOutcome.failed);
      expect(
        result.failureReason,
        ExportImportFailureReason.unreadableOrWrongFormat,
      );
      await expectNothingWritten();
    },
  );

  test('a backup from an older version, with only the diary files and '
      'meals without a dataVersion, still restores', () async {
    final now = DateTime.now();
    writeZip({
      ExportImportBloc.userActivityJsonFileName: '[]',
      ExportImportBloc.userIntakeJsonFileName: jsonEncode([
        _intakeJson('old', now),
      ]),
      ExportImportBloc.trackedDayJsonFileName: '[]',
    });

    final result = await restore.restore();

    expect(result.outcome, RestoreBackupOutcome.restored);
    expect(intakeBox.length, 1);
    expect(weightLogBox.isEmpty, isTrue);
    expect(
      (await config.getConfig()).userKcalAdjustment,
      isNull,
      reason: 'a backup without goal_settings.json leaves the defaults',
    );
  });

  test('a profile that already has a body profile is refused before the '
      'picker opens, and nothing is written', () async {
    await userRepository.updateUserData(_newPhoneUser());
    writeZip({
      ExportImportBloc.userActivityJsonFileName: '[]',
      ExportImportBloc.userIntakeJsonFileName: jsonEncode([
        _intakeJson('a', DateTime.now()),
      ]),
      ExportImportBloc.trackedDayJsonFileName: '[]',
    });

    final result = await restore.restore();

    expect(result.outcome, RestoreBackupOutcome.profileHasData);
    expect(pickCount, 0);
    expect(intakeBox.isEmpty, isTrue);
  });

  test('syncTodayGoals recomputes today and swallows a failure', () async {
    final failing = RestoreBackupUsecase(
      _UnusedImportData(),
      hasUserData: () async => false,
      updateDayGoals: (day) async {
        goalDays.add(day);
        throw StateError('no body profile');
      },
    );

    await failing.syncTodayGoals();

    expect(goalDays, hasLength(1));
    final now = DateTime.now();
    expect(goalDays.single.day, now.day);
  });
}
