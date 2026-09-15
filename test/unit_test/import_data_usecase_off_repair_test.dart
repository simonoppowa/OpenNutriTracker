import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
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

/// A meal as the 2.3.0 exporter wrote it for a product scanned from Open
/// Food Facts: `source` is `off`, the micronutrients are the raw grams the
/// API sent, and there is no `dataVersion` key because the field did not
/// exist. Sodium 0.12 g and vitamin D 0.000005 g are 120 mg and 5 µg.
const _legacyOffMealJson = '''
{
  "code": "3017620422003",
  "name": "Nutella",
  "brands": "Ferrero",
  "thumbnailImageUrl": null,
  "mainImageUrl": null,
  "url": null,
  "mealQuantity": "400",
  "mealUnit": "g",
  "servingQuantity": 15.0,
  "servingUnit": "g",
  "servingSize": "15 g",
  "source": "off",
  "nutriments": {
    "energyKcal100": 539.0,
    "carbohydrates100": 57.5,
    "fat100": 30.9,
    "proteins100": 6.3,
    "sugars100": 56.3,
    "saturatedFat100": 10.6,
    "fiber100": null,
    "sodium100": 0.12,
    "iron100": 0.002,
    "vitaminD100": 0.000005
  }
}''';

/// A `user_intake.json` entry logging 30 g of it.
const _legacyOffIntakeJson =
    '''
{
  "id": "old-off",
  "unit": "g",
  "amount": 30.0,
  "type": "breakfast",
  "dateTime": "2026-08-20T08:15:00.000",
  "meal": $_legacyOffMealJson
}''';

/// The same shape for a custom food: whatever the user typed, already in
/// app units, and never scaled.
const _legacyCustomIntakeJson = '''
{
  "id": "custom",
  "unit": "g",
  "amount": 100.0,
  "type": "lunch",
  "dateTime": "2026-08-20T12:00:00.000",
  "meal": {
    "code": null,
    "name": "Homemade soup",
    "brands": null,
    "thumbnailImageUrl": null,
    "mainImageUrl": null,
    "url": null,
    "mealQuantity": "100",
    "mealUnit": "g",
    "servingQuantity": null,
    "servingUnit": null,
    "servingSize": null,
    "source": "custom",
    "nutriments": {
      "energyKcal100": 50.0,
      "carbohydrates100": 5.0,
      "fat100": 1.0,
      "proteins100": 2.0,
      "sugars100": 1.0,
      "saturatedFat100": 0.0,
      "fiber100": 1.0,
      "sodium100": 0.4,
      "vitaminD100": 0.5
    }
  }
}''';

/// A `user_recipes.json` entry from the same build: 100 g of the Open Food
/// Facts product above as its only ingredient, so the aggregate the old
/// build computed carries the same wrong magnitudes.
const _legacyRecipeJson =
    '''
{
  "id": "recipe-1",
  "name": "Spread on its own",
  "description": null,
  "ingredients": [
    {
      "snapshotMeal": $_legacyOffMealJson,
      "amount": 100.0,
      "unit": "g",
      "convertedAmountG": 100.0
    }
  ],
  "totalWeightG": 100.0,
  "aggregatedNutrimentsPer100": {
    "energyKcal100": 539.0,
    "carbohydrates100": 57.5,
    "fat100": 30.9,
    "proteins100": 6.3,
    "sugars100": 56.3,
    "saturatedFat100": 10.6,
    "fiber100": null,
    "sodium100": 0.12,
    "iron100": 0.002,
    "vitaminD100": 0.000005
  },
  "createdAt": "2026-07-01T00:00:00.000",
  "updatedAt": "2026-07-02T00:00:00.000",
  "servingsCount": 2,
  "tags": [],
  "imagePath": null
}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late Box<IntakeDBO> intakeBox;
  late Box<RecipeDBO> recipeBox;
  late Box<UserActivityDBO> activityBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<WeightLogDBO> weightLogBox;
  late Box<CustomActivityTemplateDBO> templateBox;
  late ImportDataUsecase usecase;
  late File Function(String name, List<int> bytes) write;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('import_off_repair_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    intakeBox = await Hive.openBox<IntakeDBO>('import_repair_intake_$tag');
    recipeBox = await Hive.openBox<RecipeDBO>('import_repair_recipe_$tag');
    activityBox = await Hive.openBox<UserActivityDBO>(
      'import_repair_activity_$tag',
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'import_repair_tracked_$tag',
    );
    weightLogBox = await Hive.openBox<WeightLogDBO>(
      'import_repair_weight_$tag',
    );
    templateBox = await Hive.openBox<CustomActivityTemplateDBO>(
      'import_repair_template_$tag',
    );
    final provider = FakeHiveDBProvider(
      intakeBox: intakeBox,
      recipeBox: recipeBox,
      userActivityBox: activityBox,
      trackedDayBox: trackedDayBox,
      weightLogBox: weightLogBox,
      customActivityTemplateBox: templateBox,
    );
    write = (name, bytes) =>
        File('${tempDir.path}/$name')..writeAsBytesSync(bytes);
    usecase = ImportDataUsecase(
      UserActivityRepository(UserActivityDataSource(provider)),
      IntakeRepository(IntakeDataSource(provider)),
      TrackedDayRepository(TrackedDayDataSource(provider)),
      RecipeRepository(RecipeDataSource(provider)),
      WeightLogRepository(WeightLogDataSource(provider)),
      CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(provider),
      ),
      pickFile: () async =>
          _PickedFile('backup.zip', File('${tempDir.path}/backup.zip').uri),
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await intakeBox.deleteFromDisk();
    await recipeBox.deleteFromDisk();
    await activityBox.deleteFromDisk();
    await trackedDayBox.deleteFromDisk();
    await weightLogBox.deleteFromDisk();
    await templateBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Uint8List zipWith(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<bool> importJson() => usecase.importData(
    ExportImportBloc.userActivityJsonFileName,
    ExportImportBloc.userIntakeJsonFileName,
    ExportImportBloc.trackedDayJsonFileName,
    ExportImportBloc.recipeJsonFileName,
    ExportImportBloc.weightLogJsonFileName,
    ExportImportBloc.customActivityTemplateJsonFileName,
  );

  test('a JSON bundle from a build before #775 lands with its Open Food Facts '
      'rows in app units and everything else as written', () async {
    write(
      'backup.zip',
      zipWith({
        ExportImportBloc.userActivityJsonFileName: '[]',
        ExportImportBloc.userIntakeJsonFileName:
            '[$_legacyOffIntakeJson, $_legacyCustomIntakeJson]',
        ExportImportBloc.trackedDayJsonFileName: '[]',
        ExportImportBloc.recipeJsonFileName: '[$_legacyRecipeJson]',
      }),
    );

    expect(await importJson(), isTrue);

    final byId = {for (final i in intakeBox.values) i.id: i};
    final off = byId['old-off']!;
    expect(off.amount, 30);
    expect(off.meal.nutriments.sodium100, closeTo(120, 1e-9));
    expect(off.meal.nutriments.iron100, closeTo(2, 1e-9));
    expect(off.meal.nutriments.vitaminD100, closeTo(5, 1e-9));
    expect(off.meal.nutriments.energyKcal100, 539);
    expect(off.meal.nutriments.fiber100, isNull);
    expect(
      off.meal.dataVersion,
      MealDBO.dataVersionOffMicronutrientsInAppUnits,
    );
    final custom = byId['custom']!;
    expect(custom.meal.nutriments.sodium100, 0.4);
    expect(custom.meal.nutriments.vitaminD100, 0.5);
    expect(custom.meal.dataVersion, isNull);

    final recipe = recipeBox.values.single;
    final snapshot = recipe.ingredients.single.snapshotMeal;
    expect(snapshot.nutriments.sodium100, closeTo(120, 1e-9));
    expect(snapshot.dataVersion, 1);
    expect(recipe.aggregatedNutrimentsPer100.sodium100, closeTo(120, 1e-9));
    expect(recipe.aggregatedNutrimentsPer100.vitaminD100, closeTo(5, 1e-9));
    expect(recipe.aggregatedNutrimentsPer100.energyKcal100, closeTo(539, 1e-9));
    expect(recipe.totalWeightG, 100);
    expect(recipe.servingsCount, 2);
  });

  test(
    'a JSON bundle exported by a repaired build is imported as-is',
    () async {
      final stamped = jsonDecode(_legacyOffIntakeJson) as Map<String, dynamic>;
      final meal = stamped['meal'] as Map<String, dynamic>;
      // What the exporter writes once the row has been through the repair.
      (meal['nutriments'] as Map<String, dynamic>)
        ..['sodium100'] = 120.0
        ..['iron100'] = 2.0
        ..['vitaminD100'] = 5.0;
      meal['dataVersion'] = MealDBO.currentDataVersion;
      write(
        'backup.zip',
        zipWith({
          ExportImportBloc.userActivityJsonFileName: '[]',
          ExportImportBloc.userIntakeJsonFileName: jsonEncode([stamped]),
          ExportImportBloc.trackedDayJsonFileName: '[]',
        }),
      );

      expect(await importJson(), isTrue);

      final off = intakeBox.values.single;
      expect(off.meal.nutriments.sodium100, 120);
      expect(off.meal.nutriments.iron100, 2);
      expect(off.meal.nutriments.vitaminD100, 5);
      expect(off.meal.dataVersion, 1);
    },
  );

  test(
    'a CSV bundle without the meal_data_version column is scaled the same way',
    () async {
      final legacyHeader = CsvDataExporter.intakeColumns
          .where((c) => c != 'meal_data_version')
          .join(',');
      final row = <String, String>{
        'id': 'old-off',
        'date_time': '2026-08-20T08:15:00.000',
        'type': 'breakfast',
        'amount': '30',
        'unit': 'g',
        'meal_code': '3017620422003',
        'meal_name': 'Nutella',
        'meal_source': 'off',
        'kcal_per_100g': '539',
        'sodium_per_100g': '0.12',
        'iron_per_100g': '0.002',
        'vitamin_d_per_100g': '0.000005',
      };
      final cells = CsvDataExporter.intakeColumns
          .where((c) => c != 'meal_data_version')
          .map((c) => row[c] ?? '')
          .join(',');
      write(
        'backup.zip',
        zipWith({
          'user_activity.csv':
              '${CsvDataExporter.userActivityColumns.join(',')}\n',
          'user_intake.csv': '$legacyHeader\n$cells\n',
          'user_tracked_day.csv':
              '${CsvDataExporter.trackedDayColumns.join(',')}\n',
        }),
      );

      expect(await usecase.importDataCsv(), isTrue);

      final off = intakeBox.values.single;
      expect(off.meal.source, MealSourceDBO.off);
      expect(off.meal.nutriments.sodium100, closeTo(120, 1e-9));
      expect(off.meal.nutriments.iron100, closeTo(2, 1e-9));
      expect(off.meal.nutriments.vitaminD100, closeTo(5, 1e-9));
      expect(off.meal.nutriments.energyKcal100, 539);
      expect(off.meal.dataVersion, 1);
    },
  );
}
