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
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
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

/// A `user_intake.json` row for a custom food, as the exporter writes it.
Map<String, dynamic> _intakeJson(String id, {double amount = 100}) => {
  'id': id,
  'unit': 'g',
  'amount': amount,
  'type': 'breakfast',
  'dateTime': '2026-10-01T08:00:00.000',
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

/// A `user_activity.json` row, as the exporter writes it.
Map<String, dynamic> _activityJson(String id, {double duration = 30}) => {
  'id': id,
  'duration': duration,
  'burnedKcal': 250.0,
  'date': '2026-10-01T18:00:00.000',
  'physicalActivityDBO': {
    'code': '12050',
    'specificActivity': 'running',
    'description': 'running, 6 mph',
    'mets': 9.8,
    'tags': <String>[],
    'type': 'running',
  },
};

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
  late FakeHiveDBProvider provider;
  late ImportDataUsecase usecase;

  setUpAll(() {
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('import_upsert_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final tag = DateTime.now().microsecondsSinceEpoch;
    intakeBox = await Hive.openBox<IntakeDBO>('import_upsert_intake_$tag');
    recipeBox = await Hive.openBox<RecipeDBO>('import_upsert_recipe_$tag');
    activityBox = await Hive.openBox<UserActivityDBO>(
      'import_upsert_activity_$tag',
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'import_upsert_tracked_$tag',
    );
    weightLogBox = await Hive.openBox<WeightLogDBO>(
      'import_upsert_weight_$tag',
    );
    templateBox = await Hive.openBox<CustomActivityTemplateDBO>(
      'import_upsert_template_$tag',
    );
    provider = FakeHiveDBProvider(
      intakeBox: intakeBox,
      recipeBox: recipeBox,
      userActivityBox: activityBox,
      trackedDayBox: trackedDayBox,
      weightLogBox: weightLogBox,
      customActivityTemplateBox: templateBox,
    );
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

  void writeZip(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    File(
      '${tempDir.path}/backup.zip',
    ).writeAsBytesSync(ZipEncoder().encode(archive));
  }

  void writeBundle({
    List<Map<String, dynamic>> intakes = const [],
    List<Map<String, dynamic>> activities = const [],
    List<Map<String, dynamic>>? templates,
  }) => writeZip({
    ExportImportBloc.userActivityJsonFileName: jsonEncode(activities),
    ExportImportBloc.userIntakeJsonFileName: jsonEncode(intakes),
    ExportImportBloc.trackedDayJsonFileName: '[]',
    if (templates != null)
      ExportImportBloc.customActivityTemplateJsonFileName: jsonEncode(
        templates,
      ),
  });

  Future<bool> importJson() => usecase.importData(
    ExportImportBloc.userActivityJsonFileName,
    ExportImportBloc.userIntakeJsonFileName,
    ExportImportBloc.trackedDayJsonFileName,
    ExportImportBloc.recipeJsonFileName,
    ExportImportBloc.weightLogJsonFileName,
    ExportImportBloc.customActivityTemplateJsonFileName,
  );

  List<String> intakeIds() =>
      intakeBox.values.map((i) => i.id).toList()..sort();
  List<String> activityIds() =>
      activityBox.values.map((a) => a.id).toList()..sort();

  test('importing onto entries with the same ids replaces them instead of '
      'adding a second copy (#1357)', () async {
    await intakeBox.addAll([
      IntakeDBO.fromJson(_intakeJson('meal-a', amount: 50)),
      IntakeDBO.fromJson(_intakeJson('meal-only-on-device')),
    ]);
    await activityBox.add(
      UserActivityDBO.fromJson(_activityJson('run-a', duration: 10)),
    );
    writeBundle(
      intakes: [_intakeJson('meal-a', amount: 80), _intakeJson('meal-b')],
      activities: [_activityJson('run-a', duration: 45)],
    );

    expect(await importJson(), isTrue);

    expect(intakeIds(), ['meal-a', 'meal-b', 'meal-only-on-device']);
    final mealA = intakeBox.values.singleWhere((i) => i.id == 'meal-a');
    expect(mealA.amount, 80, reason: 'the export is the source of truth');
    expect(activityIds(), ['run-a']);
    expect(activityBox.values.single.duration, 45);
  });

  test(
    'importing the same bundle twice leaves one copy of each entry',
    () async {
      writeBundle(
        intakes: [_intakeJson('meal-a'), _intakeJson('meal-b')],
        activities: [_activityJson('run-a')],
      );

      await importJson();
      await importJson();

      expect(intakeIds(), ['meal-a', 'meal-b']);
      expect(activityIds(), ['run-a']);
    },
  );

  test('a device and a bundle already doubled by the old import collapse to '
      'one copy per id', () async {
    // What an install hit by #1357 holds, and what it exports.
    await intakeBox.addAll([
      IntakeDBO.fromJson(_intakeJson('meal-a')),
      IntakeDBO.fromJson(_intakeJson('meal-a')),
    ]);
    await activityBox.addAll([
      UserActivityDBO.fromJson(_activityJson('run-a')),
      UserActivityDBO.fromJson(_activityJson('run-a')),
    ]);
    writeBundle(
      intakes: [
        _intakeJson('meal-a', amount: 70),
        _intakeJson('meal-a', amount: 90),
      ],
      activities: [_activityJson('run-a'), _activityJson('run-a')],
    );

    await importJson();

    expect(intakeIds(), ['meal-a']);
    expect(intakeBox.values.single.amount, 70, reason: 'the first row wins');
    expect(activityIds(), ['run-a']);
  });

  test('Custom activity templates are matched by name, as when saved from '
      'the form', () async {
    await templateBox.add(CustomActivityTemplateDBO('Bike commute', 200));
    writeBundle(
      templates: [
        CustomActivityTemplateDBO('Bike commute', 240).toJson(),
        CustomActivityTemplateDBO('Climbing gym', 480).toJson(),
      ],
    );

    await importJson();
    await importJson();

    final byName = {for (final t in templateBox.values) t.name: t};
    expect(templateBox.length, 2);
    expect(byName['Bike commute']!.typicalKcal, 240);
    expect(byName['Climbing gym']!.typicalKcal, 480);
  });

  test('re-importing an export from a doubled install keeps the copy the '
      'user edited, not the stale one after it', () async {
    // An install hit by #1357 holds two copies of each id. Editing one
    // updates the first copy; the export then writes the box in order, so
    // the stale copy comes last in the bundle.
    await intakeBox.addAll([
      IntakeDBO.fromJson(_intakeJson('meal-a', amount: 50)),
      IntakeDBO.fromJson(_intakeJson('meal-a', amount: 50)),
    ]);
    await activityBox.addAll([
      UserActivityDBO.fromJson(_activityJson('run-a', duration: 10)),
      UserActivityDBO.fromJson(_activityJson('run-a', duration: 10)),
    ]);
    await IntakeDataSource(provider).updateIntake('meal-a', {'amount': 80.0});
    await UserActivityDataSource(provider).updateUserActivity('run-a', 45, 400);

    final exportedIntakes = intakeBox.values.map((i) => i.toJson()).toList();
    final exportedActivities = activityBox.values
        .map((a) => a.toJson())
        .toList();
    expect(exportedIntakes.map((i) => i['amount']), [80, 50]);
    expect(exportedActivities.map((a) => a['duration']), [45, 10]);
    writeBundle(intakes: exportedIntakes, activities: exportedActivities);

    await importJson();

    expect(intakeIds(), ['meal-a']);
    expect(intakeBox.values.single.amount, 80);
    expect(activityIds(), ['run-a']);
    expect(activityBox.values.single.duration, 45);
    expect(activityBox.values.single.burnedKcal, 400);
  });

  group('a rejected archive leaves the device untouched', () {
    Matcher wrongFormat() => throwsA(
      isA<ExportImportFailure>().having(
        (f) => f.reason,
        'reason',
        ExportImportFailureReason.unreadableOrWrongFormat,
      ),
    );

    /// Every stored row, with its Hive key, so a rewrite in place or a
    /// dropped duplicate shows up as well as a changed value.
    String snapshot() => jsonEncode({
      'intakes': [
        for (final e in intakeBox.toMap().entries) [e.key, e.value.toJson()],
      ],
      'activities': [
        for (final e in activityBox.toMap().entries) [e.key, e.value.toJson()],
      ],
      'templates': [
        for (final e in templateBox.toMap().entries) [e.key, e.value.toJson()],
      ],
    });

    setUp(() async {
      // Doubled rows, so an upsert that ran would also delete one.
      await intakeBox.addAll([
        IntakeDBO.fromJson(_intakeJson('meal-a', amount: 50)),
        IntakeDBO.fromJson(_intakeJson('meal-a', amount: 50)),
      ]);
      await activityBox.addAll([
        UserActivityDBO.fromJson(_activityJson('run-a', duration: 10)),
        UserActivityDBO.fromJson(_activityJson('run-a', duration: 10)),
      ]);
      await templateBox.add(CustomActivityTemplateDBO('Bike commute', 200));
    });

    final validActivities = jsonEncode([
      _activityJson('run-a', duration: 45),
      _activityJson('run-b'),
    ]);
    final validIntakes = jsonEncode([_intakeJson('meal-a', amount: 80)]);
    final jsonCases = <String, Map<String, String>>{
      'JSON, intake entry missing': {
        ExportImportBloc.userActivityJsonFileName: validActivities,
        ExportImportBloc.trackedDayJsonFileName: '[]',
      },
      'JSON, intake entry malformed': {
        ExportImportBloc.userActivityJsonFileName: validActivities,
        ExportImportBloc.userIntakeJsonFileName: '[{"id": "meal-a"',
        ExportImportBloc.trackedDayJsonFileName: '[]',
      },
      'JSON, tracked-day entry missing': {
        ExportImportBloc.userActivityJsonFileName: validActivities,
        ExportImportBloc.userIntakeJsonFileName: validIntakes,
      },
      'JSON, optional template entry malformed': {
        ExportImportBloc.userActivityJsonFileName: validActivities,
        ExportImportBloc.userIntakeJsonFileName: validIntakes,
        ExportImportBloc.trackedDayJsonFileName: '[]',
        ExportImportBloc.customActivityTemplateJsonFileName: '{"name": 1}',
      },
    };
    jsonCases.forEach((name, entries) {
      test(name, () async {
        final before = snapshot();
        writeZip(entries);

        await expectLater(importJson(), wrongFormat());

        expect(snapshot(), before);
      });
    });

    final validActivityCsv = CsvDataExporter.userActivitiesToCsv([
      UserActivityDBO.fromJson(_activityJson('run-a', duration: 45)),
    ]);
    final csvCases = <String, Map<String, String>>{
      'CSV, intake entry missing': {
        'user_activity.csv': validActivityCsv,
        'user_tracked_day.csv': '',
      },
      'CSV, intake entry malformed': {
        'user_activity.csv': validActivityCsv,
        'user_intake.csv': 'id,date_time\nmeal-a,not-a-date\n',
        'user_tracked_day.csv': '',
      },
      'CSV, tracked-day entry missing': {
        'user_activity.csv': validActivityCsv,
        'user_intake.csv': CsvDataExporter.intakesToCsv([
          IntakeDBO.fromJson(_intakeJson('meal-a', amount: 80)),
        ]),
      },
    };
    csvCases.forEach((name, entries) {
      test(name, () async {
        final before = snapshot();
        writeZip(entries);

        await expectLater(usecase.importDataCsv(), wrongFormat());

        expect(snapshot(), before);
      });
    });
  });
}
