import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';

/// A pick the plugin hands back: a name plus a URI. `path` is derived from
/// the URI by [PlatformFile] itself, which is how a `content://` pick ends
/// up with a null path on a real device.
final class _PickedFile extends PlatformFile {
  _PickedFile(this.name, this.uri);

  @override
  final String name;

  @override
  final Uri uri;

  // `Never` keeps the abstract member satisfied without importing
  // `cross_file`, which is not a direct dependency of the app.
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

/// The failures under test all surface before any repository is touched,
/// so the real repositories over a box-less provider are enough — the
/// provider throws if one is reached, which would be a wrong answer here.
ImportDataUsecase _usecase(Future<PlatformFile?> Function() pickFile) {
  final provider = FakeHiveDBProvider();
  return ImportDataUsecase(
    UserActivityRepository(UserActivityDataSource(provider)),
    IntakeRepository(IntakeDataSource(provider)),
    TrackedDayRepository(TrackedDayDataSource(provider)),
    RecipeRepository(RecipeDataSource(provider)),
    WeightLogRepository(WeightLogDataSource(provider)),
    CustomActivityTemplateRepository(
      CustomActivityTemplateDataSource(provider),
    ),
    pickFile: pickFile,
  );
}

Future<bool> _importJson(ImportDataUsecase usecase) => usecase.importData(
  ExportImportBloc.userActivityJsonFileName,
  ExportImportBloc.userIntakeJsonFileName,
  ExportImportBloc.trackedDayJsonFileName,
  ExportImportBloc.recipeJsonFileName,
  ExportImportBloc.weightLogJsonFileName,
  ExportImportBloc.customActivityTemplateJsonFileName,
);

Matcher _failsWith(ExportImportFailureReason reason) => throwsA(
  isA<ExportImportFailure>().having((f) => f.reason, 'reason', reason),
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('import_data_usecase_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File write(String name, List<int> bytes) =>
      File('${tempDir.path}/$name')..writeAsBytesSync(bytes);

  Uint8List zipWith(Map<String, String> entries) {
    final archive = Archive();
    entries.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  group('ImportDataUsecase picker outcomes (#1103)', () {
    test(
      'a dismissed picker is reported as cancelled, not as an error',
      () async {
        final usecase = _usecase(() async => null);

        await expectLater(
          _importJson(usecase),
          _failsWith(ExportImportFailureReason.cancelled),
        );
        await expectLater(
          usecase.importDataCsv(),
          _failsWith(ExportImportFailureReason.cancelled),
        );
      },
    );

    test(
      'a pick without a readable path is unreadable, not cancelled',
      () async {
        // The plugin delivered *something* — a document-provider URI dart:io
        // cannot open — so the user did not cancel; we just cannot read it.
        final usecase = _usecase(
          () async => _PickedFile(
            'backup.zip',
            Uri.parse('content://com.android.providers.downloads/document/7'),
          ),
        );

        await expectLater(
          _importJson(usecase),
          _failsWith(ExportImportFailureReason.unreadableOrWrongFormat),
        );
      },
    );

    test('a .csv fed to the JSON zip importer is wrong format', () async {
      final csv = write('meals.csv', utf8.encode('name,kcal\nApple,52\n'));
      final usecase = _usecase(() async => _PickedFile('meals.csv', csv.uri));

      await expectLater(
        _importJson(usecase),
        _failsWith(ExportImportFailureReason.unreadableOrWrongFormat),
      );
    });

    test('a .csv fed to the CSV zip importer is wrong format too', () async {
      // The CSV import also expects a zip — a bare spreadsheet is not one.
      final csv = write('meals.csv', utf8.encode('name,kcal\nApple,52\n'));
      final usecase = _usecase(() async => _PickedFile('meals.csv', csv.uri));

      await expectLater(
        usecase.importDataCsv(),
        _failsWith(ExportImportFailureReason.unreadableOrWrongFormat),
      );
    });

    test('a zip without the required entries is wrong format', () async {
      final zip = write('other.zip', zipWith({'readme.txt': 'hello'}));
      final usecase = _usecase(() async => _PickedFile('other.zip', zip.uri));

      await expectLater(
        _importJson(usecase),
        _failsWith(ExportImportFailureReason.unreadableOrWrongFormat),
      );
    });

    test(
      'a required entry whose JSON does not parse is wrong format',
      () async {
        // The third row of the ticket's table: the archive decoded, but a
        // DBO's fromJson threw. Before, that TypeError escaped as-is.
        final zip = write(
          'backup.zip',
          zipWith({
            ExportImportBloc.userActivityJsonFileName:
                '[{"not": "an activity"}]',
          }),
        );
        final usecase = _usecase(
          () async => _PickedFile('backup.zip', zip.uri),
        );

        await expectLater(
          _importJson(usecase),
          _failsWith(ExportImportFailureReason.unreadableOrWrongFormat),
        );
      },
    );

    test('the file that could not be read is named in the failure', () async {
      final missing = File('${tempDir.path}/gone.zip');
      final usecase = _usecase(
        () async => _PickedFile('gone.zip', missing.uri),
      );

      await expectLater(
        _importJson(usecase),
        throwsA(
          isA<ExportImportFailure>()
              .having(
                (f) => f.reason,
                'reason',
                ExportImportFailureReason.unreadableOrWrongFormat,
              )
              .having((f) => f.message, 'message', contains('gone.zip'))
              .having((f) => f.cause, 'cause', isA<FileSystemException>()),
        ),
      );
    });
  });
}
