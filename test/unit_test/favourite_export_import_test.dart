import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
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
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
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
  Future<void> addAllUserActivityDBOs(List<UserActivityDBO> dbos) async {}
}

class _EmptyIntakeRepository extends IntakeRepository {
  _EmptyIntakeRepository() : super(IntakeDataSource(_boxless));

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => [];

  @override
  Future<void> addAllIntakeDBOs(List<IntakeDBO> intakeDBOs) async {}
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
  Future<void> addAllTemplateDBOs(
    List<CustomActivityTemplateDBO> templates,
  ) async {}
}

MealEntity _meal(String code, String name, MealSourceEntity source) =>
    MealEntity(
      code: code,
      name: name,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: source,
    );

/// #1307: favourites ride along in the JSON bundle and come back on import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late PathProviderPlatform originalPathProvider;
  late Box<FavouriteMealDBO> sourceBox;
  late Box<FavouriteMealDBO> targetBox;

  FavouriteMealRepository repositoryOver(Box<FavouriteMealDBO> box) {
    final provider = FakeHiveDBProvider(favouriteMealBox: box);
    return FavouriteMealRepository(
      FavouriteMealDataSource(provider),
      _EmptyCustomMealDataSource(),
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
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await sourceBox.deleteFromDisk();
    await targetBox.deleteFromDisk();
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
}
