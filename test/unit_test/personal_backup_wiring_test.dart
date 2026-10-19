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
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/water_intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';
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

/// The fork's backup files travel through upstream's real export and import:
/// what the extras write ends up in the zip, comes back on import, and a
/// broken extras file rejects the whole import before anything is written.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late Box<IntakeDBO> intakeBox;
  late Box<WaterIntakeDBO> waterBox;
  late Box<MealDBO> customMealBox;
  late ExportDataUsecase exporter;
  late ImportDataUsecase importer;
  late FakeHiveDBProvider provider;
  final openedBoxes = <Box<dynamic>>[];

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('wiring_hive').path);
    registerHiveAdaptersOnce();
  });

  Future<Box<T>> open<T>(String name) async {
    final box = await Hive.openBox<T>(
      '${name}_${DateTime.now().microsecondsSinceEpoch}',
    );
    openedBoxes.add(box);
    return box;
  }

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('backup_wiring_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    intakeBox = await open<IntakeDBO>('intake');
    waterBox = await open<WaterIntakeDBO>('water');
    customMealBox = await open<MealDBO>('custom_meal');
    provider = FakeHiveDBProvider(
      intakeBox: intakeBox,
      waterIntakeBox: waterBox,
      recipeBox: await open<RecipeDBO>('recipe'),
      userActivityBox: await open<UserActivityDBO>('activity'),
      trackedDayBox: await open<TrackedDayDBO>('tracked'),
      weightLogBox: await open<WeightLogDBO>('weight'),
      customActivityTemplateBox: await open<CustomActivityTemplateDBO>(
        'template',
      ),
      customMealBox: customMealBox,
      configBox: await open<ConfigDBO>('config'),
      userBox: await open<UserDBO>('user'),
    );
    final extras = PersonalBackupExtras(
      WaterIntakeRepository(WaterIntakeDataSource(provider)),
      CustomMealDataSource(provider),
      UserDataSource(provider),
      ConfigDataSource(provider),
    );
    final configRepository = ConfigRepository(ConfigDataSource(provider));
    exporter = ExportDataUsecase(
      UserActivityRepository(UserActivityDataSource(provider)),
      IntakeRepository(IntakeDataSource(provider)),
      TrackedDayRepository(TrackedDayDataSource(provider)),
      RecipeRepository(RecipeDataSource(provider)),
      CustomMealDataSource(provider),
      WeightLogRepository(WeightLogDataSource(provider)),
      CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(provider),
      ),
      configRepository,
      extras: extras,
    );
    importer = ImportDataUsecase(
      UserActivityRepository(UserActivityDataSource(provider)),
      IntakeRepository(IntakeDataSource(provider)),
      TrackedDayRepository(TrackedDayDataSource(provider)),
      RecipeRepository(RecipeDataSource(provider)),
      WeightLogRepository(WeightLogDataSource(provider)),
      CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(provider),
      ),
      configRepository,
      pickFile: () async =>
          _PickedFile('backup.zip', File('${tempDir.path}/backup.zip').uri),
      extras: extras,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    for (final box in openedBoxes) {
      await box.deleteFromDisk();
    }
    openedBoxes.clear();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Archive> exportJson() => exporter.assembleArchive(
    format: ExportFormat.json,
    userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
    userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
    trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
    recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
    weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
    customActivityTemplateJsonFileName:
        ExportImportBloc.customActivityTemplateJsonFileName,
  );

  void saveZip(Archive archive) => File(
    '${tempDir.path}/backup.zip',
  ).writeAsBytesSync(ZipEncoder().encode(archive));

  Future<bool> importJson({bool restoreProfileAndSettings = true}) =>
      importer.importData(
        ExportImportBloc.userActivityJsonFileName,
        ExportImportBloc.userIntakeJsonFileName,
        ExportImportBloc.trackedDayJsonFileName,
        ExportImportBloc.recipeJsonFileName,
        ExportImportBloc.weightLogJsonFileName,
        ExportImportBloc.customActivityTemplateJsonFileName,
        restoreProfileAndSettings: restoreProfileAndSettings,
      );

  test('the JSON export carries the water log', () async {
    await waterBox.put(
      'w1',
      WaterIntakeDBO(id: 'w1', dateTime: DateTime(2026, 10, 1), amountMl: 300),
    );

    final archive = await exportJson();

    expect(
      archive.findFile(PersonalBackupExtras.waterIntakeFileName),
      isNotNull,
    );
  });

  test('export, wipe, import brings the water log back', () async {
    await waterBox.put(
      'w1',
      WaterIntakeDBO(id: 'w1', dateTime: DateTime(2026, 10, 1), amountMl: 300),
    );
    saveZip(await exportJson());
    await waterBox.clear();

    expect(await importJson(), isTrue);

    expect(waterBox.values.single.amountMl, 300);
  });

  test('a custom meal comes back with its photo', () async {
    const slug = 'meal_images/studentenfutter.webp';
    final photo = File('${tempDir.path}/$slug');
    await photo.parent.create(recursive: true);
    await photo.writeAsBytes([7, 7, 7], flush: true);
    await customMealBox.add(
      MealDBO.fromJson({
        'code': '20697112',
        'name': 'Naturgut Bio Studentenfutter',
        'mealQuantity': '100',
        'mealUnit': 'g',
        'source': 'custom',
        'localImagePath': slug,
        'nutriments': {'energyKcal100': 485.0},
      }),
    );
    saveZip(await exportJson());
    await customMealBox.clear();
    await photo.delete();

    expect(await importJson(), isTrue);

    final restored = customMealBox.values.single;
    expect(restored.code, '20697112');
    expect(restored.localImagePath, slug);
    expect(await photo.readAsBytes(), [7, 7, 7]);
  });

  test('switching profile and settings off keeps the goals too', () async {
    final config = ConfigDataSource(provider);
    await config.initializeConfig();
    await config.setConfigGoalSettings(
      kcalAdjustment: -300,
      carbGoalPct: 40,
      proteinGoalPct: 30,
      fatGoalPct: 30,
      mealKcalSharesPct: null,
      dailyWaterGoalMl: 2500,
    );
    saveZip(await exportJson());
    await config.setConfigGoalSettings(
      kcalAdjustment: 100,
      carbGoalPct: 50,
      proteinGoalPct: 25,
      fatGoalPct: 25,
      mealKcalSharesPct: null,
      dailyWaterGoalMl: 3000,
    );

    expect(await importJson(restoreProfileAndSettings: false), isTrue);

    final after = await config.getConfig();
    expect(after.userKcalAdjustment, 100);
    expect(after.dailyWaterGoalMl, 3000);
  });

  List<int> oneIntake() => utf8.encode(
    jsonEncode([
      {
        'id': 'meal-1',
        'unit': 'g',
        'amount': 100.0,
        'type': 'breakfast',
        'dateTime': '2026-10-01T08:00:00.000',
        'meal': {
          'name': 'Porridge',
          'mealQuantity': '100',
          'mealUnit': 'g',
          'source': 'custom',
          'nutriments': {'energyKcal100': 120.0},
        },
      },
    ]),
  );

  /// The exported bundle with its intakes replaced by [oneIntake] and its
  /// water file replaced by [waterContent].
  Future<Archive> bundleWith(String waterContent) async {
    final exported = await exportJson();
    final archive = Archive();
    for (final file in exported.files) {
      if (file.name == PersonalBackupExtras.waterIntakeFileName ||
          file.name == ExportImportBloc.userIntakeJsonFileName) {
        continue;
      }
      archive.addFile(file);
    }
    archive
      ..addFile(
        ArchiveFile.bytes(
          PersonalBackupExtras.waterIntakeFileName,
          utf8.encode(waterContent),
        ),
      )
      ..addFile(
        ArchiveFile.bytes(ExportImportBloc.userIntakeJsonFileName, oneIntake()),
      );
    return archive;
  }

  test('the same bundle with a valid water file imports the intake', () async {
    saveZip(await bundleWith('[]'));

    expect(await importJson(), isTrue);
    expect(intakeBox.values.single.id, 'meal-1');
  });

  test('a broken extras file rejects the import before any write', () async {
    saveZip(await bundleWith('not json'));

    await expectLater(importJson(), throwsA(isA<ExportImportFailure>()));
    expect(intakeBox.isEmpty, isTrue);
  });
}
