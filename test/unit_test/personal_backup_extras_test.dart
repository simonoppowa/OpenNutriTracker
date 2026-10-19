import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/calories_profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/data_source/water_intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/features/fasting/data/data_source/fasting_data_source.dart';
import 'package:opennutritracker/features/favorites/data/favorite_data_source.dart';
import 'package:opennutritracker/features/favorites/domain/favorite_entry.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  late Directory hiveDir;
  late Box<WaterIntakeDBO> waterBox;
  late Box<MealDBO> customMealBox;
  late Box<UserDBO> userBox;
  late Box<ConfigDBO> configBox;
  late Box<ConfigDBO> appConfigBox;
  late Box<FastingSessionDBO> fastingBox;
  late UserDataSource userDataSource;
  late ConfigDataSource configDataSource;
  late PersonalBackupExtras extras;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDir = await Directory.systemTemp.createTemp('backup_extras_test');
    Hive.init(hiveDir.path);
    registerHiveAdaptersOnce();
    waterBox = await Hive.openBox<WaterIntakeDBO>('water_test');
    customMealBox = await Hive.openBox<MealDBO>('custom_meal_test');
    userBox = await Hive.openBox<UserDBO>('user_test');
    configBox = await Hive.openBox<ConfigDBO>('config_test');
    appConfigBox = await Hive.openBox<ConfigDBO>('app_config_test');
    fastingBox = await Hive.openBox<FastingSessionDBO>('fasting_test');
    final provider = FakeHiveDBProvider(
      waterIntakeBox: waterBox,
      customMealBox: customMealBox,
      userBox: userBox,
      configBox: configBox,
      appConfigBox: appConfigBox,
      fastingBox: fastingBox,
    );
    userDataSource = UserDataSource(provider);
    configDataSource = ConfigDataSource(provider);
    await configDataSource.initializeConfig();
    extras = PersonalBackupExtras(
      WaterIntakeRepository(WaterIntakeDataSource(provider)),
      CustomMealDataSource(provider),
      userDataSource,
      configDataSource,
      FastingDataSource(provider),
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  WaterIntakeDBO water(String id, int ml, DateTime at) =>
      WaterIntakeDBO(id: id, dateTime: at, amountMl: ml);

  Future<Archive> exportArchive() async {
    final archive = Archive();
    await extras.addTo(archive);
    return ZipDecoder().decodeBytes(ZipEncoder().encode(archive));
  }

  group('water intake', () {
    test('is written as water_intake.json', () async {
      await waterBox.putAll({
        'w1': water('w1', 250, DateTime(2026, 10, 1, 8)),
        'w2': water('w2', 500, DateTime(2026, 10, 1, 12, 30)),
      });

      final archive = await exportArchive();
      final file = archive.findFile(PersonalBackupExtras.waterIntakeFileName);

      expect(file, isNotNull);
      final rows = jsonDecode(utf8.decode(file!.content as List<int>)) as List;
      expect(rows.map((row) => row['id']), unorderedEquals(['w1', 'w2']));
    });

    test('a restore brings every entry back', () async {
      await waterBox.putAll({
        'w1': water('w1', 250, DateTime(2026, 10, 1, 8)),
        'w2': water('w2', 500, DateTime(2026, 10, 2, 9)),
      });
      final archive = await exportArchive();
      await waterBox.clear();

      await extras.prepareRestore(archive).write();

      final restored = {for (final entry in waterBox.values) entry.id: entry};
      expect(restored.keys, unorderedEquals(['w1', 'w2']));
      expect(restored['w1']!.amountMl, 250);
      expect(restored['w2']!.dateTime, DateTime(2026, 10, 2, 9));
    });

    test('restoring the same backup twice adds nothing', () async {
      await waterBox.put('w1', water('w1', 250, DateTime(2026, 10, 1, 8)));
      final archive = await exportArchive();

      await extras.prepareRestore(archive).write();
      await extras.prepareRestore(archive).write();

      expect(waterBox.length, 1);
    });

    test('a backup without the file leaves the entries alone', () async {
      await waterBox.put('w1', water('w1', 250, DateTime(2026, 10, 1, 8)));

      await extras.prepareRestore(Archive()).write();

      expect(waterBox.length, 1);
    });

    test('a malformed file is rejected before anything is written', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            PersonalBackupExtras.waterIntakeFileName,
            utf8.encode('{"not": "a list"}'),
          ),
        );

      expect(
        () => extras.prepareRestore(archive),
        throwsA(
          isA<ExportImportFailure>().having(
            (failure) => failure.reason,
            'reason',
            ExportImportFailureReason.unreadableOrWrongFormat,
          ),
        ),
      );
      expect(waterBox.isEmpty, isTrue);
    });
  });

  group('custom meals', () {
    MealDBO meal(String name, {String? code, double kcal = 100}) =>
        MealDBO.fromJson({
          'code': code,
          'name': name,
          'brands': 'Penny',
          'mealQuantity': '100',
          'mealUnit': 'g',
          'source': 'custom',
          'localImagePath': 'meal_images/$name.webp',
          'nutriments': {'energyKcal100': kcal, 'proteins100': 12.0},
        });

    test('are written as custom_meals.json', () async {
      await customMealBox.addAll([
        meal('Studentenfutter', code: '20697112'),
        meal('Granola'),
      ]);

      final archive = await exportArchive();
      final file = archive.findFile(PersonalBackupExtras.customMealsFileName);

      expect(file, isNotNull);
      final rows = jsonDecode(utf8.decode(file!.content as List<int>)) as List;
      expect(
        rows.map((row) => row['name']),
        unorderedEquals(['Studentenfutter', 'Granola']),
      );
    });

    test('a restore brings name, barcode, photo and values back', () async {
      await customMealBox.add(meal('Studentenfutter', code: '20697112'));
      final archive = await exportArchive();
      await customMealBox.clear();

      await extras.prepareRestore(archive).write();

      final restored = customMealBox.values.single;
      expect(restored.name, 'Studentenfutter');
      expect(restored.code, '20697112');
      expect(restored.brands, 'Penny');
      expect(restored.localImagePath, 'meal_images/Studentenfutter.webp');
      expect(restored.nutriments.proteins100, 12.0);
    });

    test('restoring the same backup twice adds nothing', () async {
      await customMealBox.addAll([
        meal('Studentenfutter', code: '20697112'),
        meal('Granola'),
      ]);
      final archive = await exportArchive();

      await extras.prepareRestore(archive).write();
      await extras.prepareRestore(archive).write();

      expect(customMealBox.length, 2);
    });

    test('the backup version replaces the one on the device', () async {
      await customMealBox.add(meal('Granola', kcal: 450));
      final archive = await exportArchive();
      await customMealBox.clear();
      await customMealBox.add(meal('Granola', kcal: 999));

      await extras.prepareRestore(archive).write();

      expect(customMealBox.values.single.nutriments.energyKcal100, 450);
    });
  });

  group('profile', () {
    UserDBO user() => UserDBO(
      birthday: DateTime(1994, 3, 2),
      heightCM: 183,
      weightKG: 84.5,
      gender: UserGenderDBO.male,
      goal: UserWeightGoalDBO.loseWeight,
      pal: UserPALDBO.active,
      weeklyWeightGoalKg: 0.4,
      caloriesProfile: CaloriesProfileDBO.testosteroneTypical,
      targetWeightKg: 78,
      caloriesTaperEnabled: true,
    );

    test(
      'is written as user_profile.json and restored field by field',
      () async {
        await userDataSource.saveUserData(user());
        final archive = await exportArchive();
        await userBox.clear();

        await extras.prepareRestore(archive).write();

        final restored = await userDataSource.getUserData();
        expect(restored.birthday, DateTime(1994, 3, 2));
        expect(restored.heightCM, 183);
        expect(restored.weightKG, 84.5);
        expect(restored.gender, UserGenderDBO.male);
        expect(restored.goal, UserWeightGoalDBO.loseWeight);
        expect(restored.pal, UserPALDBO.active);
        expect(restored.weeklyWeightGoalKg, 0.4);
        expect(
          restored.caloriesProfile,
          CaloriesProfileDBO.testosteroneTypical,
        );
        expect(restored.targetWeightKg, 78);
        expect(restored.caloriesTaperEnabled, isTrue);
      },
    );

    test('is left out while there is no profile yet', () async {
      final archive = await exportArchive();

      expect(
        archive.findFile(PersonalBackupExtras.userProfileFileName),
        isNull,
      );
    });

    test('an unknown value is rejected before anything is written', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            PersonalBackupExtras.userProfileFileName,
            utf8.encode(
              jsonEncode({
                'birthday': '1994-03-02T00:00:00.000',
                'heightCM': 183,
                'weightKG': 84.5,
                'gender': 'robot',
                'goal': 'loseWeight',
                'pal': 'active',
              }),
            ),
          ),
        );

      expect(
        () => extras.prepareRestore(archive),
        throwsA(isA<ExportImportFailure>()),
      );
      expect(userBox.isEmpty, isTrue);
    });
  });

  test('a number too large for a double is rejected', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          PersonalBackupExtras.userProfileFileName,
          utf8.encode(
            '{"birthday": "1994-03-02T00:00:00.000", "heightCM": 183, '
            '"weightKG": 1e400, "gender": "male", "goal": "loseWeight", '
            '"pal": "active"}',
          ),
        ),
      );

    expect(
      () => extras.prepareRestore(archive),
      throwsA(isA<ExportImportFailure>()),
    );
    expect(userBox.isEmpty, isTrue);
  });

  group('app settings', () {
    Future<void> setUpDevice() async {
      await configDataSource.setConfigAppTheme(AppThemeDBO.dark);
      await configDataSource.setConfigUsesKilojoules(true);
      await configDataSource.setSelectedLocale('de');
      await configDataSource.setConfigShowMicronutrients(true);
      await configDataSource.setNotificationsEnabled(true);
      await configDataSource.setNotificationTime(7, 45);
      await configDataSource.setConfigAcceptedPolicy(true);
      await configDataSource.setConfigGoalSettings(
        kcalAdjustment: -300,
        carbGoalPct: 40,
        proteinGoalPct: 30,
        fatGoalPct: 30,
        mealKcalSharesPct: null,
        dailyWaterGoalMl: 2500,
      );
    }

    Map<String, dynamic> writtenSettings(Archive archive) =>
        jsonDecode(
              utf8.decode(
                archive
                        .findFile(PersonalBackupExtras.appSettingsFileName)!
                        .content
                    as List<int>,
              ),
            )
            as Map<String, dynamic>;

    test('carry the device-wide preferences only', () async {
      await setUpDevice();

      final settings = writtenSettings(await exportArchive());

      expect(settings['selectedAppTheme'], 'dark');
      expect(settings['usesKilojoules'], isTrue);
      expect(settings['selectedLocale'], 'de');
      expect(settings['notificationHour'], 7);
      expect(settings['notificationMinute'], 45);
      for (final excluded in [
        'hasAcceptedPolicy',
        'hasAcceptedDisclaimer',
        'hasAcceptedSendAnonymousData',
        'policyNoticeRevisionSeen',
        'isDemoData',
        'userKcalAdjustment',
        'dailyWaterGoalMl',
        'healthImportEnabled',
        'healthLastImportAt',
        'dayStartOffsetMinutes',
      ]) {
        expect(settings.containsKey(excluded), isFalse, reason: excluded);
      }
    });

    test('record the archive as the last backup', () async {
      final settings = writtenSettings(await exportArchive());

      expect(DateTime.parse(settings['lastBackupAt'] as String), isNotNull);
    });

    test('a restore applies them and keeps consent and goals', () async {
      await setUpDevice();
      final archive = await exportArchive();
      await configDataSource.setConfigAppTheme(AppThemeDBO.light);
      await configDataSource.setConfigUsesKilojoules(false);
      await configDataSource.setNotificationTime(21, 0);
      await configDataSource.setConfigGoalSettings(
        kcalAdjustment: 100,
        carbGoalPct: 50,
        proteinGoalPct: 25,
        fatGoalPct: 25,
        mealKcalSharesPct: null,
        dailyWaterGoalMl: 3000,
      );

      await extras.prepareRestore(archive).write();

      final config = await configDataSource.getConfig();
      expect(config.selectedAppTheme, AppThemeDBO.dark);
      expect(config.usesKilojoules, isTrue);
      expect(config.notificationHour, 7);
      expect(config.notificationMinute, 45);
      expect(config.hasAcceptedPolicy, isTrue);
      expect(
        config.userKcalAdjustment,
        100,
        reason: 'goals come from goal_settings.json, not from here',
      );
      expect(config.dailyWaterGoalMl, 3000);
    });
  });

  test('profile and settings stay untouched when the user opts out', () async {
    await userDataSource.saveUserData(
      UserDBO(
        birthday: DateTime(1990),
        heightCM: 170,
        weightKG: 70,
        gender: UserGenderDBO.female,
        goal: UserWeightGoalDBO.maintainWeight,
        pal: UserPALDBO.sedentary,
      ),
    );
    await configDataSource.setConfigAppTheme(AppThemeDBO.dark);
    final archive = await exportArchive();
    await userDataSource.saveUserData(
      UserDBO(
        birthday: DateTime(1990),
        heightCM: 170,
        weightKG: 65,
        gender: UserGenderDBO.female,
        goal: UserWeightGoalDBO.maintainWeight,
        pal: UserPALDBO.sedentary,
      ),
    );
    await configDataSource.setConfigAppTheme(AppThemeDBO.light);

    await extras
        .prepareRestore(archive, includeProfileAndSettings: false)
        .write();

    expect((await userDataSource.getUserData()).weightKG, 65);
    expect(
      (await configDataSource.getConfig()).selectedAppTheme,
      AppThemeDBO.light,
    );
  });

  group('own goals', () {
    const targets = GoalTargets(
      kcalMode: KcalGoalMode.fixed,
      fixedKcal: 2100,
      macroMode: MacroGoalMode.grams,
      carbsG: 220,
      fatG: 70,
      proteinG: 160,
    );

    test('are written as goal_targets.json and restored', () async {
      await configDataSource.setGoalTargets(targets);
      final archive = await exportArchive();
      expect(
        archive.findFile(PersonalBackupExtras.goalTargetsFileName),
        isNotNull,
      );
      await configDataSource.setGoalTargets(const GoalTargets());

      await extras.prepareRestore(archive).write();

      expect(
        GoalTargets.fromConfigDBO(await configDataSource.getConfig()),
        targets,
      );
    });

    test('stay as they are when the user opts out of settings', () async {
      final archive = await exportArchive();
      await configDataSource.setGoalTargets(targets);

      await extras
          .prepareRestore(archive, includeProfileAndSettings: false)
          .write();

      expect(
        GoalTargets.fromConfigDBO(await configDataSource.getConfig()),
        targets,
      );
    });

    test('an invalid file is rejected before anything is written', () async {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            PersonalBackupExtras.goalTargetsFileName,
            utf8.encode('{"fixedKcal": 12}'),
          ),
        );

      expect(
        () => extras.prepareRestore(archive),
        throwsA(isA<ExportImportFailure>()),
      );
    });

    test(
      'training days are written as training_plan.json and restored',
      () async {
        final plan = const TrainingPlan(
          trainingTargets: targets,
          trainingWeekdays: {DateTime.monday, DateTime.thursday},
        ).withDayType(DateTime(2026, 10, 20), DayType.training);
        await configDataSource.setTrainingPlan(plan);
        final archive = await exportArchive();
        await configDataSource.setTrainingPlan(const TrainingPlan());

        await extras.prepareRestore(archive).write();

        expect(
          TrainingPlan.fromConfigDBO(await configDataSource.getConfig()),
          plan,
        );
      },
    );

    test('belong to the profile, not the device', () async {
      await configDataSource.setGoalTargets(targets);

      await configBox.clear();

      expect(
        GoalTargets.fromConfigDBO(await configDataSource.getConfig()),
        const GoalTargets(),
        reason: 'a profile without its own config box has no own goals',
      );
    });
  });

  group('favourites', () {
    late Box<String> favoriteBox;
    late PersonalBackupExtras withFavorites;
    late FavoriteDataSource favoriteDataSource;

    setUp(() async {
      favoriteBox = await Hive.openBox<String>('favorites_test');
      final provider = FakeHiveDBProvider(
        waterIntakeBox: waterBox,
        customMealBox: customMealBox,
        userBox: userBox,
        configBox: configBox,
        appConfigBox: appConfigBox,
        fastingBox: fastingBox,
        favoriteBox: favoriteBox,
      );
      favoriteDataSource = FavoriteDataSource(provider);
      withFavorites = PersonalBackupExtras(
        WaterIntakeRepository(WaterIntakeDataSource(provider)),
        CustomMealDataSource(provider),
        userDataSource,
        configDataSource,
        FastingDataSource(provider),
        favorites: favoriteDataSource,
      );
    });

    final entry = FavoriteEntry(
      id: 'recipe:r1',
      kind: FavoriteKind.recipe,
      name: 'Overnight oats',
      recipeId: 'r1',
      createdAt: DateTime(2026, 10, 19),
      sortIndex: 0,
    );

    test('are written as favorites.json and restored', () async {
      await favoriteDataSource.put(entry);
      final archive = Archive();
      await withFavorites.addTo(archive);
      final decoded = ZipDecoder().decodeBytes(ZipEncoder().encode(archive));
      await favoriteBox.clear();

      await withFavorites.prepareRestore(decoded).write();

      expect(favoriteDataSource.all(), [entry]);
    });

    test('restoring twice adds nothing', () async {
      await favoriteDataSource.put(entry);
      final archive = Archive();
      await withFavorites.addTo(archive);

      await withFavorites.prepareRestore(archive).write();
      await withFavorites.prepareRestore(archive).write();

      expect(favoriteDataSource.all(), hasLength(1));
    });

    test('a malformed file is rejected before anything is written', () {
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            PersonalBackupExtras.favoritesFileName,
            utf8.encode('[{"kind": "food"}]'),
          ),
        );

      expect(
        () => withFavorites.prepareRestore(archive),
        throwsA(isA<ExportImportFailure>()),
      );
    });
  });

  group('fasting sessions', () {
    FastingSessionDBO session(String id, {int minutes = 960}) =>
        FastingSessionDBO(
          id: id,
          startedAt: DateTime(2026, 10, 1, 20),
          targetDurationMinutes: minutes,
          completedAt: DateTime(2026, 10, 2, 12),
        );

    test('are written and restored', () async {
      await fastingBox.putAll({'f1': session('f1'), 'f2': session('f2')});
      final archive = await exportArchive();
      expect(
        archive.findFile(PersonalBackupExtras.fastingSessionsFileName),
        isNotNull,
      );
      await fastingBox.clear();

      await extras.prepareRestore(archive).write();

      expect(fastingBox.keys, unorderedEquals(['f1', 'f2']));
      expect(fastingBox.get('f1')!.completedAt, DateTime(2026, 10, 2, 12));
    });

    test('restoring the same backup twice adds nothing', () async {
      await fastingBox.put('f1', session('f1'));
      final archive = await exportArchive();

      await extras.prepareRestore(archive).write();
      await extras.prepareRestore(archive).write();

      expect(fastingBox.length, 1);
    });
  });
}
