import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/settings/domain/tracked_day_boundary_record.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';
import '../fixture/physical_activity_entity_fixtures.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

class _StubUserActivityRepository extends UserActivityRepository {
  _StubUserActivityRepository()
    : super(UserActivityDataSource(FakeHiveDBProvider()));

  @override
  Future<List<UserActivityDBO>> getAllUserActivityDBO() async => [];
}

class _StubIntakeRepository extends IntakeRepository {
  _StubIntakeRepository(this._intakes)
    : super(IntakeDataSource(FakeHiveDBProvider()));

  final List<IntakeDBO> _intakes;

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => _intakes;
}

class _StubTrackedDayRepository extends TrackedDayRepository {
  _StubTrackedDayRepository()
    : super(TrackedDayDataSource(FakeHiveDBProvider()));

  @override
  Future<List<TrackedDayDBO>> getAllTrackedDaysDBO() async => [];
}

class _GatedTrackedDayRepository extends TrackedDayRepository {
  _GatedTrackedDayRepository(FakeHiveDBProvider db)
    : super(TrackedDayDataSource(db));

  final captured = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<TrackedDayDBO>> getAllTrackedDaysDBO() async {
    final rows = await super.getAllTrackedDaysDBO();
    captured.complete();
    await release.future;
    return rows;
  }
}

class _StubRecipeRepository extends RecipeRepository {
  _StubRecipeRepository() : super(RecipeDataSource(FakeHiveDBProvider()));

  @override
  List<RecipeDBO> getAllRecipesDBO() => [];
}

class _StubCustomMealDataSource extends CustomMealDataSource {
  _StubCustomMealDataSource(this._meals) : super(FakeHiveDBProvider());

  final List<MealDBO> _meals;

  @override
  List<MealDBO> getAllCustomMeals() => _meals;
}

class _StubWeightLogRepository extends WeightLogRepository {
  _StubWeightLogRepository() : super(WeightLogDataSource(FakeHiveDBProvider()));

  @override
  Future<List<WeightLogDBO>> getAllEntriesDBO() async => [];
}

class _StubTemplateRepository extends CustomActivityTemplateRepository {
  _StubTemplateRepository()
    : super(CustomActivityTemplateDataSource(FakeHiveDBProvider()));

  @override
  Future<List<CustomActivityTemplateDBO>> allTemplateDBOs() async => [];
}

class _StubConfigRepository extends ConfigRepository {
  _StubConfigRepository() : super(ConfigDataSource(FakeHiveDBProvider()));

  @override
  Future<ConfigDBO> getConfigDBO() async => ConfigDBO.empty();
}

MealDBO _meal({required String id, String? localImagePath}) {
  return MealDBO(
    code: id,
    name: 'One-off soup',
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: 100,
    servingUnit: 'g',
    servingSize: '100 g',
    nutriments: MealNutrimentsDBO(
      energyKcal100: 40,
      carbohydrates100: 5,
      fat100: 1,
      proteins100: 2,
      sugars100: 1,
      saturatedFat100: 0,
      fiber100: 0,
    ),
    source: MealSourceDBO.custom,
    localImagePath: localImagePath,
  );
}

/// What actually lands in the export archive (#1061).
///
/// Adapted from @AzazelSensei's [#1083](https://github.com/simonoppowa/OpenNutriTracker/pull/1083),
/// which was written in parallel with the fix and carried the better test.
/// The implementation half of that PR is already on `develop`; this is the
/// half that was missing.
///
/// `export_user_image_paths_test.dart` covers which photo paths get
/// **collected** — a pure function over DBOs. It never builds an archive, so
/// a broken file read or a wrong entry name would pass every assertion in it.
/// This drives `assembleArchive` against real files under a fake documents
/// directory and asserts the bytes, which is the part a person restoring a
/// backup actually depends on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  // `PathProviderPlatform.instance` is process-global, so a test that swaps it
  // owes the next one its original back. Without the restore this file leaves
  // every later test in the run pointed at a temp directory that `tearDown`
  // has already deleted, which fails by test order rather than by cause.
  // Same shape as `share_qr_dialog_test.dart`.
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_export_photo_');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  for (final format in ExportFormat.values) {
    test('${format.name} export keeps rows and their boundary together '
        'when a boundary move queues after rows are captured', () async {
      Hive.init(tempRoot.path);
      registerHiveAdaptersOnce();
      final configBox = await Hive.openBox<ConfigDBO>('export_config');
      final intakeBox = await Hive.openBox<IntakeDBO>('export_intakes');
      final activityBox = await Hive.openBox<UserActivityDBO>(
        'export_activity',
      );
      final dayBox = await Hive.openBox<TrackedDayDBO>('export_days');
      final db = FakeHiveDBProvider(
        configBox: configBox,
        intakeBox: intakeBox,
        userActivityBox: activityBox,
        trackedDayBox: dayBox,
      );
      final configs = ConfigDataSource(db);
      await configs.initializeConfig();
      await configs.setConfigDayStartOffset(4, 0);
      await configs.setConfigTrackedDaysOffsetMinutes(240);
      await activityBox.put(
        'ride',
        UserActivityDBO.fromUserActivityEntity(
          UserActivityEntity(
            'ride',
            30,
            150,
            DateTime(2026, 10, 5, 2),
            PhysicalActivityFixtures.moderateBicycling,
          ),
        ),
      );
      await dayBox.put(
        '2026-10-04',
        TrackedDayDBO(
          day: DateTime(2026, 10, 4),
          calorieGoal: 2150,
          caloriesTracked: 0,
          carbsGoal: 250,
          carbsTracked: 0,
          fatGoal: 70,
          fatTracked: 0,
          proteinGoal: 100,
          proteinTracked: 0,
        ),
      );
      final days = _GatedTrackedDayRepository(db);
      try {
        final exporting =
            ExportDataUsecase(
              UserActivityRepository(UserActivityDataSource(db)),
              IntakeRepository(IntakeDataSource(db)),
              days,
              _StubRecipeRepository(),
              _StubCustomMealDataSource([]),
              _StubWeightLogRepository(),
              _StubTemplateRepository(),
              ConfigRepository(configs),
            ).assembleArchive(
              format: format,
              userActivityJsonFileName: 'user_activity.json',
              userIntakeJsonFileName: 'user_intake.json',
              trackedDayJsonFileName: 'user_tracked_day.json',
              recipeJsonFileName: 'user_recipes.json',
              weightLogJsonFileName: 'weight_log.json',
              customActivityTemplateJsonFileName:
                  'custom_activity_templates.json',
            );
        await days.captured.future;
        var moved = false;
        final moving = SetDayBoundaryUsecase(
          db,
          configs,
        ).setDayBoundary(0, 0).then((_) => moved = true);
        await Future<void>.delayed(Duration.zero);
        final movedDuringExport = moved;
        days.release.complete();
        final archive = await exporting;
        await moving;

        String contents(String name) =>
            utf8.decode(archive.findFile(name)!.content as List<int>);
        if (format == ExportFormat.json) {
          expect(
            TrackedDayBoundaryRecord.fromJson(
              contents(TrackedDayBoundaryRecord.jsonFileName),
            ),
            240,
          );
          final rows = jsonDecode(contents('user_tracked_day.json')) as List;
          expect(rows, hasLength(1));
          expect(DateTime.parse(rows.single['day'] as String).day, 4);
          expect(rows.single['calorieGoal'], 2150);
        } else {
          expect(
            TrackedDayBoundaryRecord.fromCsv(
              contents(TrackedDayBoundaryRecord.csvFileName),
            ),
            240,
          );
          expect(contents('user_tracked_day.csv'), contains('2026-10-04'));
          expect(
            contents('user_tracked_day.csv'),
            isNot(contains('2026-10-05')),
          );
        }
        expect(movedDuringExport, isFalse);
        expect(configs.getConfigNow().trackedDaysOffsetMinutes, 0);
        expect(dayBox.get('2026-10-05')!.calorieGoal, 2150);
        expect(dayBox.containsKey('2026-10-04'), isFalse);
      } finally {
        if (!days.release.isCompleted) days.release.complete();
        await Hive.close();
      }
    });
  }

  test(
    'JSON export includes a one-off custom meal photo and import restores it',
    () async {
      const slug = 'meal_images/one-off.webp';
      final photoBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final mealDir = Directory('${tempRoot.path}/meal_images');
      await mealDir.create(recursive: true);
      final original = File('${tempRoot.path}/$slug');
      await original.writeAsBytes(photoBytes, flush: true);

      final intake = IntakeDBO(
        id: 'intake-1',
        unit: 'g',
        amount: 150,
        type: IntakeTypeDBO.lunch,
        meal: _meal(id: 'one-off', localImagePath: slug),
        dateTime: DateTime(2026, 9, 4),
      );

      final usecase = ExportDataUsecase(
        _StubUserActivityRepository(),
        _StubIntakeRepository([intake]),
        _StubTrackedDayRepository(),
        _StubRecipeRepository(),
        _StubCustomMealDataSource([]),
        _StubWeightLogRepository(),
        _StubTemplateRepository(),
        _StubConfigRepository(),
      );

      final archive = await usecase.assembleArchive(
        format: ExportFormat.json,
        userActivityJsonFileName: 'user_activity.json',
        userIntakeJsonFileName: 'user_intake.json',
        trackedDayJsonFileName: 'user_tracked_day.json',
        recipeJsonFileName: 'user_recipes.json',
        weightLogJsonFileName: 'weight_log.json',
        customActivityTemplateJsonFileName: 'custom_activity_templates.json',
      );

      final photoEntry = archive.findFile(slug);
      expect(
        photoEntry,
        isNotNull,
        reason: 'one-off intake photo must be in the JSON zip',
      );
      expect(photoEntry!.content as List<int>, equals(photoBytes));

      // Round-trip: drop the on-disk file, then restore the way
      // ImportDataUsecase writes meal_images/ entries.
      await original.delete();
      expect(original.existsSync(), isFalse);

      final zipBytes = ZipEncoder().encode(archive);
      final restored = ZipDecoder().decodeBytes(zipBytes);
      final mealOut = await UserImageStorage.ensureDirectory(
        UserImageKind.meal,
      );
      for (final entry in restored.files) {
        if (!entry.isFile) continue;
        final sanitized = UserImageStorage.sanitizeRelative(entry.name);
        if (sanitized == null) continue;
        final parts = sanitized.split('/');
        if (parts[0] != UserImageKind.meal.subdir) continue;
        final dest = File('${mealOut.path}/${parts[1]}');
        await dest.writeAsBytes(entry.content as List<int>, flush: true);
      }

      expect(original.existsSync(), isTrue);
      expect(await original.readAsBytes(), equals(photoBytes));
    },
  );

  // `_addUserImage` skips a slug whose file is gone — the OS may have
  // cleared the cache, and losing one image is not worth failing an export
  // over. Untested until now, and it is the other way a photo leaves the
  // bundle without anything saying so.
  test('a photo whose file has vanished is skipped, not fatal', () async {
    const slug = 'meal_images/missing.webp';

    final intake = IntakeDBO(
      id: 'intake-1',
      unit: 'g',
      amount: 150,
      type: IntakeTypeDBO.lunch,
      meal: _meal(id: 'one-off', localImagePath: slug),
      dateTime: DateTime(2026, 9, 4),
    );

    final usecase = ExportDataUsecase(
      _StubUserActivityRepository(),
      _StubIntakeRepository([intake]),
      _StubTrackedDayRepository(),
      _StubRecipeRepository(),
      _StubCustomMealDataSource([]),
      _StubWeightLogRepository(),
      _StubTemplateRepository(),
      _StubConfigRepository(),
    );

    final archive = await usecase.assembleArchive(
      format: ExportFormat.json,
      userActivityJsonFileName: 'user_activity.json',
      userIntakeJsonFileName: 'user_intake.json',
      trackedDayJsonFileName: 'user_tracked_day.json',
      recipeJsonFileName: 'user_recipes.json',
      weightLogJsonFileName: 'weight_log.json',
      customActivityTemplateJsonFileName: 'custom_activity_templates.json',
    );

    expect(archive.findFile(slug), isNull);
    expect(
      archive.findFile('user_intake.json'),
      isNotNull,
      reason: 'the rest of the bundle must still be there',
    );
  });
}
