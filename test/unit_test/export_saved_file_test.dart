import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';

import '../helpers/fake_hive_db_provider.dart';

const _offeredName = 'opennutritracker-export.zip';

/// What the Android plugin hands back from a save: the saved document's
/// URI path, parsed the way `android_file_picker` parses it.
Uri _androidResult(String path) => Uri.tryParse(path) ?? Uri.file(path);

/// Exports a fixed one-entry archive through [saveFile], so only the save
/// and its outcome are under test. The archive contents are covered by
/// `export_archive_round_trip_test.dart`.
class _FixedArchiveExportDataUsecase extends ExportDataUsecase {
  _FixedArchiveExportDataUsecase(SaveExportFile saveFile)
    : super(
        UserActivityRepository(UserActivityDataSource(_provider)),
        IntakeRepository(IntakeDataSource(_provider)),
        TrackedDayRepository(TrackedDayDataSource(_provider)),
        RecipeRepository(RecipeDataSource(_provider)),
        CustomMealDataSource(_provider),
        WeightLogRepository(WeightLogDataSource(_provider)),
        CustomActivityTemplateRepository(
          CustomActivityTemplateDataSource(_provider),
        ),
        ConfigRepository(ConfigDataSource(_provider)),
        FavouriteMealRepository(
          FavouriteMealDataSource(_provider),
          CustomMealDataSource(_provider),
          RecipeDataSource(_provider),
        ),
        saveFile: saveFile,
      );

  @override
  Future<Archive> assembleArchive({
    required ExportFormat format,
    required String userActivityJsonFileName,
    required String userIntakeJsonFileName,
    required String trackedDayJsonFileName,
    required String recipeJsonFileName,
    required String weightLogJsonFileName,
    required String customActivityTemplateJsonFileName,
    String goalSettingsJsonFileName = 'goal_settings.json',
    String favouriteJsonFileName = 'user_favourites.json',
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final bytes = [1, 2, 3, 4];
    return Archive()..addFile(ArchiveFile('entry.json', bytes.length, bytes));
  }
}

final _provider = FakeHiveDBProvider();

Future<SavedExport?> _export(SaveExportFile saveFile) =>
    _FixedArchiveExportDataUsecase(saveFile).exportData(
      _offeredName,
      'user_activity.json',
      'user_intake.json',
      'user_tracked_day.json',
      'user_recipes.json',
      'weight_log.json',
      'custom_activity_templates.json',
    );

Matcher _failsWith(ExportImportFailureReason reason) => throwsA(
  isA<ExportImportFailure>().having((f) => f.reason, 'reason', reason),
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('export_saved_file_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExportDataUsecase.exportData save outcome (#763)', () {
    test(
      'offers the export name and the zip bytes to the save dialog',
      () async {
        String? offered;
        Uint8List? handedOver;

        await _export((fileName, bytes) async {
          offered = fileName;
          handedOver = bytes;
          return _androidResult('/document/primary:Download/$fileName');
        });

        expect(offered, _offeredName);
        expect(handedOver, isNotEmpty);
      },
    );

    test('a save under the offered name succeeds with that name', () async {
      final saved = await _export(
        (_, _) async =>
            _androidResult('/document/primary:Download/$_offeredName'),
      );

      expect(saved, isNotNull);
      expect(saved!.fileName, _offeredName);
    });

    test('an Android auto-renamed save succeeds with the new name', () async {
      // The #763 case: Downloads already holds opennutritracker-export.zip,
      // so the document provider writes the new one as "… (2).zip".
      final saved = await _export(
        (_, _) async => _androidResult(
          '/document/primary:Download/opennutritracker-export (2).zip',
        ),
      );

      expect(saved, isNotNull);
      expect(saved!.fileName, 'opennutritracker-export (2).zip');
    });

    test(
      'a renamed save behind a raw: document id succeeds with the new name',
      () async {
        final saved = await _export(
          (_, _) async => _androidResult(
            '/document/raw:/storage/emulated/0/Download/'
            'opennutritracker-export (11).zip',
          ),
        );

        expect(saved!.fileName, 'opennutritracker-export (11).zip');
      },
    );

    test(
      'a renamed save to a real file is checked at the renamed path',
      () async {
        // Desktop and iOS hand back a file: URI. A renamed file there is
        // still read back, and passes because it has the right bytes.
        final saved = await _export((_, bytes) async {
          final renamed = File(
            '${tempDir.path}/opennutritracker-export (1).zip',
          )..writeAsBytesSync(bytes);
          return renamed.uri;
        });

        expect(saved!.fileName, 'opennutritracker-export (1).zip');
      },
    );

    for (final documentPath in ['/document/2106', '/document/msf:1000012345']) {
      test('a save answered with the document id $documentPath succeeds '
          'without a name', () async {
        // What the Downloads root hands back: a document id, not a file
        // name. "/document/2106" is what a Pixel 6 on Android 17 returned
        // for a renamed "opennutritracker-export (13).zip".
        final saved = await _export(
          (_, _) async => _androidResult(documentPath),
        );

        expect(saved, isNotNull);
        expect(saved!.fileName, isNull);
      });
    }

    test(
      'a malformed escape in a parent folder still names the saved file',
      () async {
        // "%FF" is valid URI syntax but not UTF-8, so decoding the whole
        // path throws. The file is already written; that must not turn
        // into writeFailed.
        final saved = await _export(
          (_, _) async => _androidResult(
            '/document/primary:backup%FF/opennutritracker-export (3).zip',
          ),
        );

        expect(saved!.fileName, 'opennutritracker-export (3).zip');
      },
    );

    test(
      'a malformed escape in the file name succeeds without a name',
      () async {
        final saved = await _export(
          (_, _) async => _androidResult(
            '/document/primary:Download/opennutritracker-export%FF.zip',
          ),
        );

        expect(saved, isNotNull);
        expect(saved!.fileName, isNull);
      },
    );

    test('an empty answer from the platform succeeds without a name', () async {
      // The platform returned without an error, so the bytes were handed
      // over; there is just nothing to name.
      final saved = await _export((_, _) async => _androidResult(''));

      expect(saved, isNotNull);
      expect(saved!.fileName, isNull);
    });

    test(
      'a cancelled save dialog is not a success and not a failure',
      () async {
        final saved = await _export((_, _) async => null);

        expect(saved, isNull);
      },
    );

    test('a write the platform reports as failed is writeFailed', () async {
      expect(
        _export(
          (_, _) async => throw PlatformException(
            code: 'Error while saving file',
            message: 'ENOSPC (No space left on device)',
          ),
        ),
        _failsWith(ExportImportFailureReason.writeFailed),
      );
    });

    test('a file: save that landed no bytes is writeFailed', () async {
      expect(
        _export((_, _) async {
          final empty = File('${tempDir.path}/$_offeredName')
            ..writeAsBytesSync([]);
          return empty.uri;
        }),
        _failsWith(ExportImportFailureReason.writeFailed),
      );
    });

    test('a file: save that is not there at all is writeFailed', () async {
      expect(
        _export(
          (_, _) async => File('${tempDir.path}/missing/$_offeredName').uri,
        ),
        _failsWith(ExportImportFailureReason.writeFailed),
      );
    });
  });
}
