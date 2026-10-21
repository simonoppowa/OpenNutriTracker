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
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/tracked_day_boundary_record.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
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

/// #1317 review: a restore moves the archive's rows from the boundary they
/// were exported under onto the device's, activity credit included.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;
  late List<Box<dynamic>> boxes;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<UserActivityDBO> activityBox;
  late ConfigDataSource config;
  late UserActivityRepository activities;
  late IntakeRepository intakes;
  late ExportDataUsecase exporter;
  late ImportDataUsecase importer;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('import_boundary_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('import_boundary_${name}_$tag');
    final appConfigBox = await open<ConfigDBO>('app_config');
    final profileConfigBox = await open<ConfigDBO>('profile_config');
    final intakeBox = await open<IntakeDBO>('intake');
    trackedDayBox = await open<TrackedDayDBO>('tracked');
    activityBox = await open<UserActivityDBO>('activity');
    final recipeBox = await open<RecipeDBO>('recipe');
    final customMealBox = await open<MealDBO>('custom_meal');
    final weightLogBox = await open<WeightLogDBO>('weight');
    final templateBox = await open<CustomActivityTemplateDBO>('template');
    boxes = [
      appConfigBox,
      profileConfigBox,
      intakeBox,
      trackedDayBox,
      activityBox,
      recipeBox,
      customMealBox,
      weightLogBox,
      templateBox,
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
    );
    config = ConfigDataSource(provider);
    await config.initializeConfig();

    activities = UserActivityRepository(UserActivityDataSource(provider));
    intakes = IntakeRepository(IntakeDataSource(provider));
    final trackedDays = TrackedDayRepository(TrackedDayDataSource(provider));
    final recipes = RecipeRepository(RecipeDataSource(provider));
    final weightLog = WeightLogRepository(WeightLogDataSource(provider));
    final templates = CustomActivityTemplateRepository(
      CustomActivityTemplateDataSource(provider),
    );
    final configRepository = ConfigRepository(config);
    exporter = ExportDataUsecase(
      activities,
      intakes,
      trackedDays,
      recipes,
      CustomMealDataSource(provider),
      weightLog,
      templates,
      configRepository,
    );
    importer = ImportDataUsecase(
      activities,
      intakes,
      trackedDays,
      recipes,
      weightLog,
      templates,
      configRepository,
      pickFile: () async =>
          _PickedFile('backup.zip', File('${tempDir.path}/backup.zip').uri),
      restoreTrackedDays:
          (
            write, {
            required importedDayKeys,
            required importedActivities,
            required keyedByOffsetMinutes,
          }) => restoreTrackedDays(
            provider,
            config,
            write: write,
            importedDayKeys: importedDayKeys,
            importedActivities: importedActivities,
            keyedByOffsetMinutes: keyedByOffsetMinutes,
          ),
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    for (final box in boxes) {
      await box.deleteFromDisk();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Sets the shared boundary and records it as the one this profile's
  /// rows are keyed by, as activation leaves a profile.
  Future<void> boundary(int hours) async {
    await config.setConfigDayStartOffset(hours, 0);
    await config.setConfigTrackedDaysOffsetMinutes(hours * 60);
  }

  UserActivityEntity rideAt(DateTime at) => UserActivityEntity(
    'ride-${at.toIso8601String()}',
    30,
    150,
    at,
    PhysicalActivityFixtures.moderateBicycling,
  );

  /// A row holding only a 150 kcal ride's credit on a 2000 kcal goal.
  TrackedDayDBO rideRow(DateTime day) => TrackedDayDBO(
    day: day,
    calorieGoal: 2150,
    caloriesTracked: 0,
    carbsGoal: 250,
    carbsTracked: 0,
    fatGoal: 70,
    fatTracked: 0,
    proteinGoal: 100,
    proteinTracked: 0,
  );

  /// 100 g of a 200 kcal-per-100 g toast.
  IntakeEntity toastAt(DateTime at) => IntakeEntity(
    id: 'toast-${at.toIso8601String()}',
    unit: 'g',
    amount: 100,
    type: IntakeTypeEntity.breakfast,
    meal: MealEntity(
      code: null,
      name: 'Toast',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: 100,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 40,
        fat100: 2,
        proteins100: 6,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
    dateTime: at,
  );

  /// A row holding the toast on a 2000 kcal goal, no activity credited.
  TrackedDayDBO toastRow(DateTime day) => TrackedDayDBO(
    day: day,
    calorieGoal: 2000,
    caloriesTracked: 200,
    carbsGoal: 250,
    carbsTracked: 40,
    fatGoal: 70,
    fatTracked: 2,
    proteinGoal: 100,
    proteinTracked: 6,
  );

  void writeArchive(Archive archive) => File(
    '${tempDir.path}/backup.zip',
  ).writeAsBytesSync(ZipEncoder().encode(archive));

  Future<Archive> export(ExportFormat format) => exporter.assembleArchive(
    format: format,
    userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
    userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
    trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
    recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
    weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
    customActivityTemplateJsonFileName:
        ExportImportBloc.customActivityTemplateJsonFileName,
  );

  Future<bool> import(ExportFormat format) => format == ExportFormat.json
      ? importer.importData(
          ExportImportBloc.userActivityJsonFileName,
          ExportImportBloc.userIntakeJsonFileName,
          ExportImportBloc.trackedDayJsonFileName,
          ExportImportBloc.recipeJsonFileName,
          ExportImportBloc.weightLogJsonFileName,
          ExportImportBloc.customActivityTemplateJsonFileName,
        )
      : importer.importDataCsv();

  for (final format in ExportFormat.values) {
    test('a ${format.name} backup made under 04:00 restored under 00:00 '
        'moves the ride\'s credit to the day it is listed on', () async {
      // At 04:00 the 02:00 ride on the 5th is listed, and credited, on
      // the 4th.
      await boundary(4);
      await activities.addUserActivity(rideAt(DateTime(2026, 10, 5, 2)));
      await trackedDayBox.put('2026-10-04', rideRow(DateTime(2026, 10, 4)));
      final archive = await export(format);
      expect(
        archive.findFile(
          format == ExportFormat.json
              ? TrackedDayBoundaryRecord.jsonFileName
              : TrackedDayBoundaryRecord.csvFileName,
        ),
        isNotNull,
      );
      writeArchive(archive);

      // A fresh install on midnight days.
      await trackedDayBox.clear();
      await activityBox.clear();
      await boundary(0);

      expect(await import(format), isTrue);

      expect(trackedDayBox.containsKey('2026-10-04'), isFalse);
      expect(trackedDayBox.get('2026-10-05')?.calorieGoal, 2150);
    });
  }

  // #1317 review: a row the archive does not replace never credited the
  // archive's activities, even when they are listed on its day now.
  for (final format in ExportFormat.values) {
    test('a ${format.name} backup made under 04:00 restored under 00:00 '
        'credits the ride on the device\'s own row for its day', () async {
      await boundary(4);
      await activities.addUserActivity(rideAt(DateTime(2026, 10, 5, 2)));
      await trackedDayBox.put('2026-10-04', rideRow(DateTime(2026, 10, 4)));
      writeArchive(await export(format));

      // The device runs on midnight days, with its own toast on the 5th.
      await trackedDayBox.clear();
      await activityBox.clear();
      await boundary(0);
      await intakes.addIntake(toastAt(DateTime(2026, 10, 5, 12)));
      await trackedDayBox.put('2026-10-05', toastRow(DateTime(2026, 10, 5)));

      expect(await import(format), isTrue);

      expect(trackedDayBox.containsKey('2026-10-04'), isFalse);
      final row = trackedDayBox.get('2026-10-05');
      expect(row?.calorieGoal, 2150);
      expect(row?.caloriesTracked, 200);
    });
  }

  test('a backup made under 00:00 restored under 04:00 credits the ride on '
      'the device\'s own row for its day', () async {
    await boundary(0);
    await activities.addUserActivity(rideAt(DateTime(2026, 10, 5, 2)));
    await trackedDayBox.put('2026-10-05', rideRow(DateTime(2026, 10, 5)));
    writeArchive(await export(ExportFormat.json));

    // At 04:00 the ride is listed on the 4th, where the device has a row.
    await trackedDayBox.clear();
    await activityBox.clear();
    await boundary(4);
    await intakes.addIntake(toastAt(DateTime(2026, 10, 4, 12)));
    await trackedDayBox.put('2026-10-04', toastRow(DateTime(2026, 10, 4)));

    expect(await import(ExportFormat.json), isTrue);

    expect(trackedDayBox.containsKey('2026-10-05'), isFalse);
    expect(trackedDayBox.get('2026-10-04')?.calorieGoal, 2150);
  });

  test('a device ride whose row the archive replaces keeps its credit, '
      'on the same boundary too', () async {
    // The backup holds the 6th with only the toast on it.
    await boundary(0);
    await intakes.addIntake(toastAt(DateTime(2026, 10, 6, 8)));
    await trackedDayBox.put('2026-10-06', toastRow(DateTime(2026, 10, 6)));
    writeArchive(await export(ExportFormat.json));

    // The device logged a ride on the 6th after the backup was made.
    await activities.addUserActivity(rideAt(DateTime(2026, 10, 6, 18)));
    await trackedDayBox.put(
      '2026-10-06',
      toastRow(DateTime(2026, 10, 6))..calorieGoal = 2150,
    );

    expect(await import(ExportFormat.json), isTrue);

    expect(trackedDayBox.get('2026-10-06')?.calorieGoal, 2150);
  });

  /// A bundle from before the boundary record, holding [rides] and [rows].
  void writeLegacyArchive(
    List<UserActivityEntity> rides,
    List<TrackedDayDBO> rows,
  ) {
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      ExportImportBloc.userActivityJsonFileName,
      jsonEncode([
        for (final ride in rides)
          UserActivityDBO.fromUserActivityEntity(ride).toJson(),
      ]),
    );
    add(ExportImportBloc.userIntakeJsonFileName, '[]');
    add(
      ExportImportBloc.trackedDayJsonFileName,
      jsonEncode([for (final row in rows) row.toJson()]),
    );
    writeArchive(archive);
  }

  // #1317 review: the import stores one activity per id, so the archive's
  // credit has to count one too.
  test('a ride repeated under one id in a backup is credited once', () async {
    await boundary(0);
    final ride = rideAt(DateTime(2026, 10, 5, 12));
    writeLegacyArchive([ride, ride], [rideRow(DateTime(2026, 10, 5))]);

    expect(await import(ExportFormat.json), isTrue);

    expect(activityBox.length, 1);
    expect(trackedDayBox.get('2026-10-05')?.calorieGoal, 2150);
  });

  test('rides with a blank id in a backup are each credited', () async {
    await boundary(0);
    UserActivityEntity blankRide() => UserActivityEntity(
      '',
      30,
      150,
      DateTime(2026, 10, 5, 12),
      PhysicalActivityFixtures.moderateBicycling,
    );
    writeLegacyArchive(
      [blankRide(), blankRide()],
      [rideRow(DateTime(2026, 10, 5))..calorieGoal = 2300],
    );

    expect(await import(ExportFormat.json), isTrue);

    expect(activityBox.length, 2);
    expect(trackedDayBox.get('2026-10-05')?.calorieGoal, 2300);
  });

  test('an archive from before the record is read as keyed by the '
      'wall-clock date, and the device\'s own rows stay put', () async {
    await boundary(4);
    // The device's own ride, at 02:00 on the 7th, credited on the 6th.
    await activities.addUserActivity(rideAt(DateTime(2026, 10, 7, 2)));
    await trackedDayBox.put('2026-10-06', rideRow(DateTime(2026, 10, 6)));

    // An older build keyed the 02:00 ride on the 5th by its date.
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      ExportImportBloc.userActivityJsonFileName,
      jsonEncode([
        UserActivityDBO.fromUserActivityEntity(
          rideAt(DateTime(2026, 10, 5, 2)),
        ).toJson(),
      ]),
    );
    add(ExportImportBloc.userIntakeJsonFileName, '[]');
    add(
      ExportImportBloc.trackedDayJsonFileName,
      jsonEncode([rideRow(DateTime(2026, 10, 5)).toJson()]),
    );
    writeArchive(archive);

    expect(await import(ExportFormat.json), isTrue);

    expect(trackedDayBox.containsKey('2026-10-05'), isFalse);
    expect(trackedDayBox.get('2026-10-04')?.calorieGoal, 2150);
    expect(
      trackedDayBox.get('2026-10-06')?.calorieGoal,
      2150,
      reason: 'the device\'s row was keyed by 04:00 already',
    );
    expect((await config.getConfig()).trackedDaysOffsetMinutes, 240);
  });

  test('a record that is not a boundary rejects the archive before it '
      'writes anything', () async {
    final archive = await export(ExportFormat.json);
    archive.addFile(
      ArchiveFile.string(
        TrackedDayBoundaryRecord.jsonFileName,
        '{"version": 1, "dayStartOffsetMinutes": 1440}',
      ),
    );
    await activities.addUserActivity(rideAt(DateTime(2026, 10, 5, 12)));
    writeArchive(archive);
    await activityBox.clear();

    await expectLater(
      import(ExportFormat.json),
      throwsA(isA<ExportImportFailure>()),
    );
    expect(activityBox.isEmpty, isTrue);
  });
}
