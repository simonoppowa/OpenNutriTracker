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
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
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

/// Same shape as `import_data_usecase_failure_test.dart`.
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

// Every dataset but favourites is empty on both legs; these stand in for
// boxes the test does not need.
final _boxless = FakeHiveDBProvider();

class _EmptyUserActivityRepository extends UserActivityRepository {
  _EmptyUserActivityRepository() : super(UserActivityDataSource(_boxless));

  @override
  Future<List<UserActivityDBO>> getAllUserActivityDBO() async => [];

  @override
  Future<void> upsertAllUserActivityDBOs(List<UserActivityDBO> dbos) async {}
}

class _EmptyIntakeRepository extends IntakeRepository {
  _EmptyIntakeRepository() : super(IntakeDataSource(_boxless));

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => [];

  @override
  Future<void> upsertAllIntakeDBOs(List<IntakeDBO> intakeDBOs) async {}
}

class _EmptyTrackedDayRepository extends TrackedDayRepository {
  _EmptyTrackedDayRepository() : super(TrackedDayDataSource(_boxless));

  @override
  Future<List<TrackedDayDBO>> getAllTrackedDaysDBO() async => [];

  @override
  Future<void> addAllTrackedDays(List<TrackedDayDBO> trackedDaysDBO) async {}
}

class _EmptyRecipeRepository extends RecipeRepository {
  _EmptyRecipeRepository() : super(RecipeDataSource(_boxless));

  @override
  List<RecipeDBO> getAllRecipesDBO() => [];

  @override
  Future<void> addAllRecipeDBOs(List<RecipeDBO> recipes) async {}
}

class _EmptyCustomMealDataSource extends CustomMealDataSource {
  _EmptyCustomMealDataSource() : super(_boxless);

  @override
  List<MealDBO> getAllCustomMeals() => [];
}

class _EmptyWeightLogRepository extends WeightLogRepository {
  _EmptyWeightLogRepository() : super(WeightLogDataSource(_boxless));

  @override
  Future<List<WeightLogDBO>> getAllEntriesDBO() async => [];

  @override
  Future<void> addAllEntries(List<WeightLogDBO> entries) async {}
}

class _EmptyTemplateRepository extends CustomActivityTemplateRepository {
  _EmptyTemplateRepository()
    : super(CustomActivityTemplateDataSource(_boxless));

  @override
  Future<List<CustomActivityTemplateDBO>> allTemplateDBOs() async => [];

  @override
  Future<void> upsertAllTemplateDBOs(
    List<CustomActivityTemplateDBO> templates,
  ) async {}
}

class _EmptyConfigRepository extends ConfigRepository {
  _EmptyConfigRepository() : super(ConfigDataSource(_boxless));

  @override
  Future<ConfigDBO> getConfigDBO() async => ConfigDBO.empty();

  @override
  Future<void> setConfigGoalSettings({
    required double? kcalAdjustment,
    required double? carbGoalPct,
    required double? proteinGoalPct,
    required double? fatGoalPct,
    required Map<String, int>? mealKcalSharesPct,
    required int? dailyWaterGoalMl,
  }) async {}
}

MealEntity _meal(
  String code,
  String name,
  MealSourceEntity source, {
  double kcal = 0,
}) => MealEntity(
  code: code,
  name: name,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

/// #1307: favourites ride along in the JSON bundle and come back on import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late PathProviderPlatform originalPathProvider;
  late Box<FavouriteMealDBO> sourceBox;
  late Box<FavouriteMealDBO> targetBox;
  late Box<MealDBO> customMealBox;
  late Box<ProfileDBO> profileBox;

  FavouriteMealRepository repositoryOver(
    Box<FavouriteMealDBO> box, {
    Box<MealDBO>? customMeals,
  }) {
    final provider = FakeHiveDBProvider(
      favouriteMealBox: box,
      customMealBox: customMeals,
      profileBox: profileBox,
    );
    return FavouriteMealRepository(
      FavouriteMealDataSource(provider),
      customMeals == null
          ? _EmptyCustomMealDataSource()
          : CustomMealDataSource(provider),
      RecipeDataSource(provider),
    );
  }

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_favourites_');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    sourceBox = await Hive.openBox<FavouriteMealDBO>('fav_export_$tag');
    targetBox = await Hive.openBox<FavouriteMealDBO>('fav_import_$tag');
    customMealBox = await Hive.openBox<MealDBO>('fav_custom_$tag');
    profileBox = await Hive.openBox<ProfileDBO>('fav_profiles_$tag');
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await sourceBox.deleteFromDisk();
    await targetBox.deleteFromDisk();
    await customMealBox.deleteFromDisk();
    await profileBox.deleteFromDisk();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test(
    'a JSON export carries the favourites and an import restores them',
    () async {
      final exporting = repositoryOver(sourceBox);
      await exporting.addFavourite(
        _meal('3017620422003', 'Nutella', MealSourceEntity.off),
      );
      await exporting.addFavourite(
        _meal('c1', 'Lunchbox', MealSourceEntity.custom),
      );

      final archive =
          await ExportDataUsecase(
            _EmptyUserActivityRepository(),
            _EmptyIntakeRepository(),
            _EmptyTrackedDayRepository(),
            _EmptyRecipeRepository(),
            _EmptyCustomMealDataSource(),
            _EmptyWeightLogRepository(),
            _EmptyTemplateRepository(),
            _EmptyConfigRepository(),
            exporting,
          ).assembleArchive(
            format: ExportFormat.json,
            userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
            userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
            trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
            recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
            weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
            customActivityTemplateJsonFileName:
                ExportImportBloc.customActivityTemplateJsonFileName,
            favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
          );

      final entry = archive.findFile(ExportImportBloc.favouriteJsonFileName);
      expect(entry, isNotNull);
      final exported = jsonDecode(utf8.decode(entry!.content as List<int>));
      expect(exported, hasLength(2));

      final zip = File('${tempRoot.path}/backup.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));
      final importing = repositoryOver(targetBox);
      final imported =
          await ImportDataUsecase(
            _EmptyUserActivityRepository(),
            _EmptyIntakeRepository(),
            _EmptyTrackedDayRepository(),
            _EmptyRecipeRepository(),
            _EmptyWeightLogRepository(),
            _EmptyTemplateRepository(),
            _EmptyConfigRepository(),
            importing,
            pickFile: () async => _PickedFile('backup.zip', zip.uri),
          ).importData(
            ExportImportBloc.userActivityJsonFileName,
            ExportImportBloc.userIntakeJsonFileName,
            ExportImportBloc.trackedDayJsonFileName,
            ExportImportBloc.recipeJsonFileName,
            ExportImportBloc.weightLogJsonFileName,
            ExportImportBloc.customActivityTemplateJsonFileName,
            favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
          );

      expect(imported, isTrue);
      final restored = await importing.getAllFavourites();
      expect(restored.map((m) => m.name), ['Lunchbox', 'Nutella']);
      expect(
        targetBox.keys,
        unorderedEquals(['off:3017620422003', 'custom:c1']),
      );
    },
  );

  test('a CSV export leaves favourites out', () async {
    await repositoryOver(
      sourceBox,
    ).addFavourite(_meal('1', 'Apple', MealSourceEntity.fdc));

    final archive =
        await ExportDataUsecase(
          _EmptyUserActivityRepository(),
          _EmptyIntakeRepository(),
          _EmptyTrackedDayRepository(),
          _EmptyRecipeRepository(),
          _EmptyCustomMealDataSource(),
          _EmptyWeightLogRepository(),
          _EmptyTemplateRepository(),
          _EmptyConfigRepository(),
          repositoryOver(sourceBox),
        ).assembleArchive(
          format: ExportFormat.csv,
          userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
          userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
          trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
          recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
          weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
          customActivityTemplateJsonFileName:
              ExportImportBloc.customActivityTemplateJsonFileName,
        );

    expect(archive.findFile(ExportImportBloc.favouriteJsonFileName), isNull);
  });

  Future<Archive> exportFrom(FavouriteMealRepository favourites) =>
      ExportDataUsecase(
        _EmptyUserActivityRepository(),
        _EmptyIntakeRepository(),
        _EmptyTrackedDayRepository(),
        _EmptyRecipeRepository(),
        _EmptyCustomMealDataSource(),
        _EmptyWeightLogRepository(),
        _EmptyTemplateRepository(),
        _EmptyConfigRepository(),
        favourites,
      ).assembleArchive(
        format: ExportFormat.json,
        userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
        userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
        trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
        recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
        weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
        customActivityTemplateJsonFileName:
            ExportImportBloc.customActivityTemplateJsonFileName,
        favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
      );

  Future<bool> importInto(
    FavouriteMealRepository favourites,
    File zip, {
    UserActivityRepository? activities,
  }) =>
      ImportDataUsecase(
        activities ?? _EmptyUserActivityRepository(),
        _EmptyIntakeRepository(),
        _EmptyTrackedDayRepository(),
        _EmptyRecipeRepository(),
        _EmptyWeightLogRepository(),
        _EmptyTemplateRepository(),
        _EmptyConfigRepository(),
        favourites,
        pickFile: () async => _PickedFile('backup.zip', zip.uri),
      ).importData(
        ExportImportBloc.userActivityJsonFileName,
        ExportImportBloc.userIntakeJsonFileName,
        ExportImportBloc.trackedDayJsonFileName,
        ExportImportBloc.recipeJsonFileName,
        ExportImportBloc.weightLogJsonFileName,
        ExportImportBloc.customActivityTemplateJsonFileName,
        favouriteJsonFileName: ExportImportBloc.favouriteJsonFileName,
      );

  test(
    'a JSON restore keeps an edited custom-meal snapshot after template deletion',
    () async {
      final provider = FakeHiveDBProvider(customMealBox: customMealBox);
      final customMeals = CustomMealDataSource(provider);
      final exporting = repositoryOver(sourceBox, customMeals: customMealBox);
      final original = _meal(
        'c1',
        'Overnight oats',
        MealSourceEntity.custom,
        kcal: 150,
      );
      await customMeals.saveCustomMeal(MealDBO.fromMealEntity(original));
      await exporting.addFavourite(original);

      final edited = _meal(
        'c1',
        'Updated overnight oats',
        MealSourceEntity.custom,
        kcal: 180,
      );
      await customMeals.saveCustomMeal(MealDBO.fromMealEntity(edited));
      await exporting.moveFavourite(original, edited);
      await customMeals.deleteCustomMeal('c1');

      final zip = File('${tempRoot.path}/edited-favourite.zip')
        ..writeAsBytesSync(ZipEncoder().encode(await exportFrom(exporting)));
      final importing = repositoryOver(targetBox);
      expect(await importInto(importing, zip), isTrue);

      final restored = await importing.getAllFavourites();
      expect(restored.single.name, 'Updated overnight oats');
      expect(restored.single.nutriments.energyKcal100, 180);
      expect(
        targetBox.get('custom:c1')!.addedAt,
        sourceBox.get('custom:c1')!.addedAt,
      );
    },
  );

  test(
    'the export carries the saved meal as it is now, not as it was starred',
    () async {
      // Edited outside the edit form (a meal import), so the stored
      // snapshot is still the star-time one; a fresh install has no custom
      // meal library to read the edit from.
      final customMeals = CustomMealDataSource(
        FakeHiveDBProvider(customMealBox: customMealBox),
      );
      final exporting = repositoryOver(sourceBox, customMeals: customMealBox);
      final original = _meal(
        'c1',
        'Overnight oats',
        MealSourceEntity.custom,
        kcal: 150,
      );
      await customMeals.saveCustomMeal(MealDBO.fromMealEntity(original));
      await exporting.addFavourite(original);
      await customMeals.saveCustomMeal(
        MealDBO.fromMealEntity(
          _meal('c1', 'Overnight oats', MealSourceEntity.custom, kcal: 180),
        ),
      );
      expect(sourceBox.get('custom:c1')!.meal.nutriments.energyKcal100, 150);

      final zip = File('${tempRoot.path}/live-favourite.zip')
        ..writeAsBytesSync(ZipEncoder().encode(await exportFrom(exporting)));
      final importing = repositoryOver(targetBox);
      expect(await importInto(importing, zip), isTrue);

      final restored = await importing.getAllFavourites();
      expect(restored.single.nutriments.energyKcal100, 180);
      expect(
        targetBox.get('custom:c1')!.addedAt,
        sourceBox.get('custom:c1')!.addedAt,
      );
    },
  );

  test('importing the same bundle again keeps one entry per food', () async {
    final exporting = repositoryOver(sourceBox);
    await exporting.addFavourite(
      _meal('3017620422003', 'Nutella', MealSourceEntity.off),
    );
    await exporting.addFavourite(
      _meal('c1', 'Lunchbox', MealSourceEntity.custom),
    );
    final zip = File('${tempRoot.path}/backup.zip')
      ..writeAsBytesSync(ZipEncoder().encode(await exportFrom(exporting)));

    // Back onto the install the bundle came from, twice.
    expect(await importInto(exporting, zip), isTrue);
    expect(await importInto(exporting, zip), isTrue);
    expect(sourceBox.keys, unorderedEquals(['off:3017620422003', 'custom:c1']));

    // Onto one that already stars one of the foods, and another the bundle
    // lacks, which stays.
    final importing = repositoryOver(targetBox);
    await importing.addFavourite(
      _meal('3017620422003', 'Nutella', MealSourceEntity.off),
    );
    await importing.addFavourite(_meal('9', 'Pear', MealSourceEntity.fdc));
    expect(await importInto(importing, zip), isTrue);
    expect(await importInto(importing, zip), isTrue);
    expect(
      targetBox.keys,
      unorderedEquals(['off:3017620422003', 'custom:c1', 'fdc:9']),
    );
    expect(await importing.getAllFavourites(), hasLength(3));
  });

  test(
    'a malformed favourites file rejects the zip before anything is written',
    () async {
      final importing = repositoryOver(targetBox);
      await importing.addFavourite(_meal('9', 'Pear', MealSourceEntity.fdc));
      final archive = await exportFrom(repositoryOver(sourceBox));
      final bad = utf8.encode('[{"meal": "not a meal"}]');
      archive.addFile(
        ArchiveFile(ExportImportBloc.favouriteJsonFileName, bad.length, bad),
      );
      final zip = File('${tempRoot.path}/backup.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));
      final activities = _RecordingUserActivityRepository();

      await expectLater(
        importInto(importing, zip, activities: activities),
        throwsA(
          isA<ExportImportFailure>().having(
            (f) => f.reason,
            'reason',
            ExportImportFailureReason.unreadableOrWrongFormat,
          ),
        ),
      );
      expect(activities.writes, 0);
      expect(targetBox.keys, ['fdc:9']);
    },
  );
}

class _RecordingUserActivityRepository extends _EmptyUserActivityRepository {
  int writes = 0;

  @override
  Future<void> upsertAllUserActivityDBOs(List<UserActivityDBO> dbos) async {
    writes++;
  }
}
