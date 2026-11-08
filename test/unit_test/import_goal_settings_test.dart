import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
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
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_backup.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_json_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

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

class _UnusedImportMealsCsv extends Fake implements ImportMealsCsvUsecase {}

class _UnusedImportRecipesCsv extends Fake implements ImportRecipesCsvUsecase {}

class _UnusedSampleCsv extends Fake implements DownloadSampleCsvUsecase {}

class _UnusedSampleJson extends Fake implements DownloadSampleJsonUsecase {}

class _UnusedImportMealsJson extends Fake implements ImportMealsJsonUsecase {}

class _UnusedImportRecipesJson extends Fake
    implements ImportRecipesJsonUsecase {}

/// A valid `goal_settings.json`, as the exporter writes it.
Map<String, dynamic> _goalsJson() => {
  'version': 1,
  'kcalAdjustment': -300.0,
  'carbGoalPct': 0.4,
  'proteinGoalPct': 0.3,
  'fatGoalPct': 0.3,
  'mealKcalSharesPct': {
    'breakfast': 25,
    'lunch': 35,
    'dinner': 30,
    'snack': 10,
  },
  'dailyWaterGoalMl': 2600,
};

/// Restoring a backup after a reset or reinstall must bring the goal
/// settings back along with the diary (#1363).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late List<Box<dynamic>> boxes;
  late Box<ConfigDBO> appConfigBox;
  late Box<ConfigDBO> profileConfigBox;
  late Box<IntakeDBO> intakeBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<UserDBO> userBox;
  late FakeHiveDBProvider provider;
  late ConfigDataSource config;
  late ExportDataUsecase exporter;
  late ImportDataUsecase importer;
  late SettingsBloc settingsBloc;
  late ExportImportBloc exportImportBloc;
  late GetKcalGoalUsecase kcalGoal;
  late GetMacroGoalUsecase macroGoal;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('import_goal_settings_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('import_goals_${name}_$tag');
    appConfigBox = await open<ConfigDBO>('app_config');
    profileConfigBox = await open<ConfigDBO>('profile_config');
    intakeBox = await open<IntakeDBO>('intake');
    trackedDayBox = await open<TrackedDayDBO>('tracked');
    final activityBox = await open<UserActivityDBO>('activity');
    final recipeBox = await open<RecipeDBO>('recipe');
    final customMealBox = await open<MealDBO>('custom_meal');
    final weightLogBox = await open<WeightLogDBO>('weight');
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
    provider = FakeHiveDBProvider(
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

    final activities = UserActivityRepository(UserActivityDataSource(provider));
    final intakes = IntakeRepository(IntakeDataSource(provider));
    final trackedDays = TrackedDayRepository(TrackedDayDataSource(provider));
    final recipes = RecipeRepository(RecipeDataSource(provider));
    final weightLog = WeightLogRepository(WeightLogDataSource(provider));
    final templates = CustomActivityTemplateRepository(
      CustomActivityTemplateDataSource(provider),
    );
    final configRepository = ConfigRepository(config);
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
    importer = ImportDataUsecase(
      activities,
      intakes,
      trackedDays,
      recipes,
      weightLog,
      templates,
      configRepository,
      favourites,
      pickFile: () async =>
          _PickedFile('backup.zip', File('${tempDir.path}/backup.zip').uri),
    );

    await UserDataSource(provider).saveUserData(
      UserDBO(
        birthday: DateTime(1990, 6, 15),
        heightCM: 175,
        weightKG: 62,
        gender: UserGenderDBO.male,
        goal: UserWeightGoalDBO.maintainWeight,
        pal: UserPALDBO.active,
      ),
    );
    kcalGoal = GetKcalGoalUsecase(
      UserRepository(UserDataSource(provider)),
      configRepository,
      activities,
    );
    macroGoal = GetMacroGoalUsecase(configRepository);
    settingsBloc = SettingsBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      AddTrackedDayUsecase(trackedDays),
      kcalGoal,
      macroGoal,
      _UnusedSearchCache(),
      GetTrackedDayUsecase(trackedDays),
      _UnusedSetDayBoundary(),
    );
    exportImportBloc = ExportImportBloc(
      exporter,
      importer,
      _UnusedImportMealsCsv(),
      _UnusedImportRecipesCsv(),
      _UnusedSampleCsv(),
      _UnusedSampleJson(),
      _UnusedImportMealsJson(),
      _UnusedImportRecipesJson(),
      settingsBloc,
    );
  });

  tearDown(() async {
    await exportImportBloc.close();
    await settingsBloc.close();
    PathProviderPlatform.instance = originalPathProvider;
    for (final box in boxes) {
      await box.deleteFromDisk();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void writeArchive(Archive archive) => File(
    '${tempDir.path}/backup.zip',
  ).writeAsBytesSync(ZipEncoder().encode(archive));

  /// A bundle with empty required entries plus [extra].
  void writeZip(Map<String, String> extra) {
    final archive = Archive();
    final entries = {
      ExportImportBloc.userActivityJsonFileName: '[]',
      ExportImportBloc.userIntakeJsonFileName: '[]',
      ExportImportBloc.trackedDayJsonFileName: '[]',
      ...extra,
    };
    entries.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    writeArchive(archive);
  }

  Future<bool> importJson() => importer.importData(
    ExportImportBloc.userActivityJsonFileName,
    ExportImportBloc.userIntakeJsonFileName,
    ExportImportBloc.trackedDayJsonFileName,
    ExportImportBloc.recipeJsonFileName,
    ExportImportBloc.weightLogJsonFileName,
    ExportImportBloc.customActivityTemplateJsonFileName,
    goalSettingsJsonFileName: ExportImportBloc.goalSettingsJsonFileName,
  );

  Future<void> setCustomGoals() async {
    await config.setConfigKcalAdjustment(250);
    await config.setConfigCarbGoalPct(0.5);
    await config.setConfigProteinGoalPct(0.25);
    await config.setConfigFatGoalPct(0.25);
    await config.setConfigMealKcalSharesPct({
      'breakfast': 20,
      'lunch': 40,
      'dinner': 30,
      'snack': 10,
    });
    await config.setConfigDailyWaterGoalMl(3100);
  }

  Future<Map<String, Object?>> goals() async {
    final c = await config.getConfig();
    return {
      'kcalAdjustment': c.userKcalAdjustment,
      'carbGoalPct': c.userCarbGoalPct,
      'proteinGoalPct': c.userProteinGoalPct,
      'fatGoalPct': c.userFatGoalPct,
      'mealKcalSharesPct': c.mealKcalSharesPct,
      'dailyWaterGoalMl': c.dailyWaterGoalMl,
    };
  }

  test('a JSON export carries the goal settings, and importing it after a '
      'profile reset restores them', () async {
    await setCustomGoals();
    final before = await goals();
    final archive = await exporter.assembleArchive(
      format: ExportFormat.json,
      userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
      userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
      trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
      recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
      weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
      customActivityTemplateJsonFileName:
          ExportImportBloc.customActivityTemplateJsonFileName,
      goalSettingsJsonFileName: ExportImportBloc.goalSettingsJsonFileName,
    );
    expect(
      archive.findFile(ExportImportBloc.goalSettingsJsonFileName),
      isNotNull,
    );
    writeArchive(archive);

    // What Settings -> Reset profile data leaves: the profile's config box
    // emptied, the device-wide one kept.
    await profileConfigBox.clear();
    await config.initializeConfig();
    await config.setConfigAppTheme(AppThemeDBO.dark);
    expect((await goals())['kcalAdjustment'], isNull);

    expect(await importJson(), isTrue);

    expect(await goals(), before);
    expect(
      (await config.getConfig()).selectedAppTheme,
      AppThemeDBO.dark,
      reason: 'device-wide preferences are not in the backup',
    );
  });

  test('a CSV export carries no goal settings', () async {
    await setCustomGoals();
    final archive = await exporter.assembleArchive(
      format: ExportFormat.csv,
      userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
      userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
      trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
      recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
      weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
      customActivityTemplateJsonFileName:
          ExportImportBloc.customActivityTemplateJsonFileName,
      goalSettingsJsonFileName: ExportImportBloc.goalSettingsJsonFileName,
    );

    expect(archive.findFile(ExportImportBloc.goalSettingsJsonFileName), isNull);
  });

  test('an archive from before #1363, without goal settings, imports as '
      'before and leaves the device goals alone', () async {
    await setCustomGoals();
    final before = await goals();
    writeZip({});

    expect(await importJson(), isTrue);

    expect(await goals(), before);
  });

  test(
    'a null goal in the archive puts that goal back to the default',
    () async {
      await setCustomGoals();
      writeZip({
        ExportImportBloc.goalSettingsJsonFileName: jsonEncode({
          ..._goalsJson(),
          'carbGoalPct': null,
          'proteinGoalPct': null,
          'fatGoalPct': null,
          'dailyWaterGoalMl': null,
        }),
      });

      await importJson();

      final restored = await goals();
      expect(restored['kcalAdjustment'], -300);
      expect(restored['carbGoalPct'], isNull);
      expect(restored['proteinGoalPct'], isNull);
      expect(restored['fatGoalPct'], isNull);
      expect(restored['dailyWaterGoalMl'], isNull);
    },
  );

  test('goal settings from a newer format are skipped and the rest of the '
      'archive still imports', () async {
    await setCustomGoals();
    final before = await goals();
    writeZip({
      ExportImportBloc.goalSettingsJsonFileName: jsonEncode({
        ..._goalsJson(),
        'version': GoalSettingsBackup.formatVersion + 1,
      }),
    });

    expect(await importJson(), isTrue);

    expect(await goals(), before);
  });

  group('invalid goal settings reject the archive before anything is '
      'written', () {
    Matcher wrongFormat() => throwsA(
      isA<ExportImportFailure>().having(
        (f) => f.reason,
        'reason',
        ExportImportFailureReason.unreadableOrWrongFormat,
      ),
    );

    String snapshot() => jsonEncode({
      'appConfig': appConfigBox.toMap().map(
        (k, v) => MapEntry('$k', v.toJson()),
      ),
      'profileConfig': profileConfigBox.toMap().map(
        (k, v) => MapEntry('$k', v.toJson()),
      ),
      'intakes': intakeBox.values.map((i) => i.toJson()).toList(),
      'trackedDays': trackedDayBox.values.map((d) => d.toJson()).toList(),
    });

    final cases = <String, String>{
      'not JSON': '{"version": 1,',
      'not an object': '[]',
      'no version': jsonEncode({..._goalsJson()}..remove('version')),
      'kcal adjustment is text': jsonEncode({
        ..._goalsJson(),
        'kcalAdjustment': '-300',
      }),
      'kcal adjustment out of range': jsonEncode({
        ..._goalsJson(),
        'kcalAdjustment': 5000,
      }),
      'macro split given in percent': jsonEncode({
        ..._goalsJson(),
        'carbGoalPct': 40,
        'proteinGoalPct': 30,
        'fatGoalPct': 30,
      }),
      'macro split not adding up': jsonEncode({
        ..._goalsJson(),
        'carbGoalPct': 0.2,
      }),
      'macro split missing one macro': jsonEncode({
        ..._goalsJson(),
        'fatGoalPct': null,
      }),
      'meal shares missing a meal': jsonEncode({
        ..._goalsJson(),
        'mealKcalSharesPct': {'breakfast': 50, 'lunch': 50},
      }),
      'meal shares not adding up': jsonEncode({
        ..._goalsJson(),
        'mealKcalSharesPct': {
          'breakfast': 10,
          'lunch': 10,
          'dinner': 10,
          'snack': 10,
        },
      }),
      'water goal out of range': jsonEncode({
        ..._goalsJson(),
        'dailyWaterGoalMl': 50,
      }),
      'water goal not a whole number': jsonEncode({
        ..._goalsJson(),
        'dailyWaterGoalMl': 2600.5,
      }),
    };
    final intake = jsonEncode([
      {
        'id': 'meal-a',
        'unit': 'g',
        'amount': 100.0,
        'type': 'breakfast',
        'dateTime': '2026-10-01T08:00:00.000',
        'meal': {
          'name': 'Porridge',
          'mealQuantity': '100',
          'mealUnit': 'g',
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
      },
    ]);

    test('the same archive with valid goal settings imports, so each case '
        'below fails on its goal settings alone', () async {
      writeZip({
        ExportImportBloc.userIntakeJsonFileName: intake,
        ExportImportBloc.goalSettingsJsonFileName: jsonEncode(_goalsJson()),
      });

      expect(await importJson(), isTrue);
      expect(intakeBox.length, 1);
      expect((await goals())['dailyWaterGoalMl'], 2600);
    });

    cases.forEach((name, content) {
      test(name, () async {
        await setCustomGoals();
        final before = snapshot();
        writeZip({
          ExportImportBloc.userIntakeJsonFileName: intake,
          ExportImportBloc.goalSettingsJsonFileName: content,
        });

        await expectLater(importJson(), wrongFormat());

        expect(snapshot(), before);
      });
    });
  });

  group('GoalSettingsBackup.fromJson', () {
    // A zip's JSON cannot spell NaN, but the parser is the gate either way.
    for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
      test('rejects a non-finite kcal adjustment ($bad)', () {
        expect(
          () => GoalSettingsBackup.fromJson({
            ..._goalsJson(),
            'kcalAdjustment': bad,
          }),
          throwsFormatException,
        );
      });

      test('rejects a non-finite macro ($bad)', () {
        expect(
          () =>
              GoalSettingsBackup.fromJson({..._goalsJson(), 'fatGoalPct': bad}),
          throwsFormatException,
        );
      });
    }
  });

  group("after an import, today's tracked day follows the restored goals, "
      'as Home does', () {
    late DateTime today;

    setUp(() {
      final now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
    });

    Future<ExportImportState> runImport() {
      final done = exportImportBloc.stream.firstWhere(
        (s) => s is ExportImportSuccess || s is ExportImportError,
      );
      exportImportBloc.add(const ImportDataEvent());
      return done;
    }

    Future<void> expectTodayMatchesHome() async {
      final row = trackedDayBox.get(today.toParsedDay())!;
      final kcal = await kcalGoal.getKcalGoal();
      expect(row.calorieGoal, kcal);
      expect(row.carbsGoal, await macroGoal.getCarbsGoal(kcal));
      expect(row.fatGoal, await macroGoal.getFatsGoal(kcal));
      expect(row.proteinGoal, await macroGoal.getProteinsGoal(kcal));
    }

    TrackedDayDBO staleToday() => TrackedDayDBO(
      day: today,
      calorieGoal: 2744,
      caloriesTracked: 640,
      carbsGoal: 343,
      fatGoal: 91,
      proteinGoal: 137,
    );

    test('a device row for today is recomputed once the goal settings are '
        'restored', () async {
      await trackedDayBox.put(today.toParsedDay(), staleToday());
      writeZip({
        ExportImportBloc.goalSettingsJsonFileName: jsonEncode(_goalsJson()),
      });

      expect(await runImport(), isA<ExportImportSuccess>());

      expect((await goals())['kcalAdjustment'], -300);
      await expectTodayMatchesHome();
      expect(trackedDayBox.get(today.toParsedDay())!.caloriesTracked, 640);
    });

    test('a row for today carried in the backup, computed for the old '
        'profile, is recomputed for this one', () async {
      writeZip({
        ExportImportBloc.trackedDayJsonFileName: jsonEncode([
          staleToday().toJson(),
        ]),
        ExportImportBloc.goalSettingsJsonFileName: jsonEncode(_goalsJson()),
      });

      expect(await runImport(), isA<ExportImportSuccess>());

      await expectTodayMatchesHome();
      expect(trackedDayBox.get(today.toParsedDay())!.caloriesTracked, 640);
    });

    test('other days keep the goals they were logged with', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      writeZip({
        ExportImportBloc.trackedDayJsonFileName: jsonEncode([
          TrackedDayDBO(
            day: yesterday,
            calorieGoal: 2744,
            caloriesTracked: 640,
          ).toJson(),
        ]),
        ExportImportBloc.goalSettingsJsonFileName: jsonEncode(_goalsJson()),
      });

      expect(await runImport(), isA<ExportImportSuccess>());

      expect(trackedDayBox.get(yesterday.toParsedDay())!.calorieGoal, 2744);
    });

    test("a rejected archive leaves today's row alone", () async {
      await trackedDayBox.put(today.toParsedDay(), staleToday());
      writeZip({ExportImportBloc.goalSettingsJsonFileName: '[]'});

      expect(await runImport(), isA<ExportImportError>());

      expect(trackedDayBox.get(today.toParsedDay())!.calorieGoal, 2744);
    });
  });

  group('GoalSettingsBackup.fromConfigDBO', () {
    test('writes a corrupt stored value as null, so its own export is never '
        'rejected on import', () {
      final stored = ConfigDBO.empty()
        ..userKcalAdjustment = 200
        ..userCarbGoalPct = 0.6
        ..userProteinGoalPct = 0.6
        ..userFatGoalPct = 0.6
        ..mealKcalSharesPct = {'breakfast': 100}
        ..dailyWaterGoalMl = 20;

      final backup = GoalSettingsBackup.fromConfigDBO(stored);
      final reread = GoalSettingsBackup.fromJson(
        jsonDecode(jsonEncode(backup.toJson())),
      );

      expect(reread!.kcalAdjustment, 200);
      expect(reread.carbGoalPct, isNull);
      expect(reread.proteinGoalPct, isNull);
      expect(reread.fatGoalPct, isNull);
      expect(reread.mealKcalSharesPct, isNull);
      expect(reread.dailyWaterGoalMl, isNull);
    });

    test('writes a non-finite stored kcal adjustment or macro as null, so '
        'the backup still encodes', () {
      for (final bad in [double.nan, double.infinity]) {
        final kcalStored = ConfigDBO.empty()..userKcalAdjustment = bad;
        final macroStored = ConfigDBO.empty()
          ..userCarbGoalPct = bad
          ..userProteinGoalPct = 0.3
          ..userFatGoalPct = 0.3;

        final kcalBackup = GoalSettingsBackup.fromConfigDBO(kcalStored);
        final macroBackup = GoalSettingsBackup.fromConfigDBO(macroStored);

        expect(kcalBackup.kcalAdjustment, isNull, reason: '$bad');
        expect(macroBackup.carbGoalPct, isNull, reason: '$bad');
        expect(macroBackup.proteinGoalPct, isNull, reason: '$bad');
        expect(macroBackup.fatGoalPct, isNull, reason: '$bad');
        expect(() => jsonEncode(kcalBackup.toJson()), returnsNormally);
        expect(() => jsonEncode(macroBackup.toJson()), returnsNormally);
      }
    });

    test('carries only the per-profile goals', () {
      final stored = ConfigDBO.empty()
        ..selectedLocale = 'de'
        ..usesKilojoules = true
        ..healthImportEnabled = true;

      expect(GoalSettingsBackup.fromConfigDBO(stored).toJson().keys, {
        'version',
        'kcalAdjustment',
        'carbGoalPct',
        'proteinGoalPct',
        'fatGoalPct',
        'mealKcalSharesPct',
        'dailyWaterGoalMl',
      });
    });
  });
}
