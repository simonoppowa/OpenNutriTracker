import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
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
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/off_micronutrient_repair.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_backup.dart';
import 'package:opennutritracker/features/settings/domain/tracked_day_boundary_record.dart';

/// Opens the system file picker for a single file of any type and resolves
/// to the pick, or to null when the user dismissed the picker.
typedef PickImportFile = Future<PlatformFile?> Function();

Future<PlatformFile?> _pickAnyFile() => FilePicker.pickFile(type: FileType.any);

/// Runs an import's [write] of entries and rows, then moves the rows it
/// wrote, keyed [importedDayKeys], from the boundary the archive recorded
/// (null: none recorded) onto the configured one, with the credit of the
/// archive's [importedActivities] — `restoreTrackedDays` (#1317).
typedef RestoreTrackedDays =
    Future<void> Function(
      Future<void> Function() write, {
      required Set<String> importedDayKeys,
      required List<UserActivityDBO> importedActivities,
      required int? keyedByOffsetMinutes,
    });

class ImportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final RecipeRepository _recipeRepository;
  final WeightLogRepository _weightLogRepository;
  final CustomActivityTemplateRepository _customActivityTemplateRepository;
  final ConfigRepository _configRepository;

  /// Seam for tests: `FilePicker.pickFile` is static and needs a platform
  /// channel, so the picker outcomes (#1103: cancel, a pick without a
  /// path, a pick of the wrong file) can only be driven from here.
  final PickImportFile _pickFile;

  /// Null only in tests that do not look at the rows' keys.
  final RestoreTrackedDays? _restoreTrackedDays;

  ImportDataUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._recipeRepository,
    this._weightLogRepository,
    this._customActivityTemplateRepository,
    this._configRepository, {
    PickImportFile pickFile = _pickAnyFile,
    RestoreTrackedDays? restoreTrackedDays,
  }) : _pickFile = pickFile,
       _restoreTrackedDays = restoreTrackedDays;

  /// Imports user activity, intake, tracked day, and (optionally) recipe,
  /// weight log, Custom activity template and goal settings data from a
  /// zip file containing JSON files. Recipe, weight log, template and goal
  /// settings files are treated as optional so zips exported by older
  /// versions still import.
  ///
  /// Returns true when the import completed. Throws an
  /// [ExportImportFailure] whose reason says what went wrong — including
  /// [ExportImportFailureReason.cancelled] when the user dismissed the
  /// picker, which callers should treat as "nothing happened" rather than
  /// as an error.
  Future<bool> importData(
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName,
    String weightLogJsonFileName,
    String customActivityTemplateJsonFileName, {
    String goalSettingsJsonFileName = 'goal_settings.json',
  }) async {
    final startedOn = ProfileStamp.now();
    final archive = await _pickAndDecodeArchive();

    // Decode every entry before writing anything (#1357): the upserts
    // below replace and delete rows on the device, so an archive with a
    // missing or malformed entry must be rejected while it has touched
    // nothing.
    final userActivityDBOs = _decodeJsonList(
      _requireEntry(archive, userActivityJsonFileName),
      UserActivityDBO.fromJson,
    );

    // A bundle written by a build before #775 carries its Open Food Facts
    // micronutrients in raw grams and no `dataVersion` on the meal; scale
    // those rows on the way in, the same way the startup pass does for rows
    // already on disk (#1152). A bundle from a repaired build carries the
    // stamp and passes through unchanged.
    final intakeDBOs = _decodeJsonList(
      _requireEntry(archive, userIntakeJsonFileName),
      IntakeDBO.fromJson,
    ).map(OffMicronutrientRepair.repairIntake).toList();

    final trackedDayDBOs = _decodeJsonList(
      _requireEntry(archive, trackedDayJsonFileName),
      TrackedDayDBO.fromJson,
    );

    // Recipes, the weight log and Custom activity templates (#70
    // follow-up) are optional so zips from older versions still import.
    // Ingredient snapshots get the same Open Food Facts repair as intakes.
    final recipeFile = archive.findFile(recipeJsonFileName);
    final recipeDBOs = recipeFile == null
        ? null
        : _decodeJsonList(
            recipeFile,
            RecipeDBO.fromJson,
          ).map(OffMicronutrientRepair.repairRecipe).toList();

    final weightLogFile = archive.findFile(weightLogJsonFileName);
    final weightLogDBOs = weightLogFile == null
        ? null
        : _decodeJsonList(weightLogFile, WeightLogDBO.fromJson);

    final templateFile = archive.findFile(customActivityTemplateJsonFileName);
    final templateDBOs = templateFile == null
        ? null
        : _decodeJsonList(templateFile, CustomActivityTemplateDBO.fromJson);

    // The profile's goal settings (#1363), absent from zips written before
    // they were exported. Checked here with everything else, so a bad
    // value rejects the zip before any of the writes below.
    final goalSettingsFile = archive.findFile(goalSettingsJsonFileName);
    final goalSettings = goalSettingsFile == null
        ? null
        : ExportImportFailure.guardSync(
            ExportImportFailureReason.unreadableOrWrongFormat,
            'Could not parse ${goalSettingsFile.name}',
            () => GoalSettingsBackup.fromJson(
              _decodeFinite(utf8.decode(goalSettingsFile.content as List<int>)),
            ),
          );

    final keyedBy = _decodeBoundary(
      archive.findFile(TrackedDayBoundaryRecord.jsonFileName),
      TrackedDayBoundaryRecord.fromJson,
    );

    final imported = await withTrackedDayLockOnProfile(() async {
      await _writeEntriesAndRows(
        userActivityDBOs,
        intakeDBOs,
        trackedDayDBOs,
        keyedBy,
      );
      if (recipeDBOs != null) {
        await _recipeRepository.addAllRecipeDBOs(recipeDBOs);
      }
      if (weightLogDBOs != null) {
        await _weightLogRepository.addAllEntries(weightLogDBOs);
      }
      if (templateDBOs != null) {
        await _customActivityTemplateRepository.upsertAllTemplateDBOs(
          templateDBOs,
        );
      }
      if (goalSettings != null) {
        await _configRepository.setConfigGoalSettings(
          kcalAdjustment: goalSettings.kcalAdjustment,
          carbGoalPct: goalSettings.carbGoalPct,
          proteinGoalPct: goalSettings.proteinGoalPct,
          fatGoalPct: goalSettings.fatGoalPct,
          mealKcalSharesPct: goalSettings.mealKcalSharesPct,
          dailyWaterGoalMl: goalSettings.dailyWaterGoalMl,
        );
      }

      final recipeDir = await UserImageStorage.ensureDirectory(
        UserImageKind.recipe,
      );
      final mealDir = await UserImageStorage.ensureDirectory(
        UserImageKind.meal,
      );
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final sanitized = UserImageStorage.sanitizeRelative(entry.name);
        if (sanitized == null) continue;
        final parts = sanitized.split('/');
        final targetDir = parts[0] == UserImageKind.recipe.subdir
            ? recipeDir
            : mealDir;
        final destPath = '${targetDir.path}/${parts[1]}';
        final destFile = File(destPath);
        await destFile.writeAsBytes(entry.content as List<int>, flush: true);
      }

      return true;
    }, startedOn: startedOn);
    return imported ?? false;
  }

  /// Symmetric CSV counterpart to [importData]. Reads a zip produced by
  /// `ExportDataUsecase.exportData(format: ExportFormat.csv)` and feeds
  /// each CSV through the matching `parse...FromCsv` helper on
  /// [CsvDataExporter]. Recipes, photos, the weight log and Custom
  /// activity templates are intentionally not handled here — CSV export
  /// omits them by design (nested or binary shapes don't flatten
  /// cleanly), so a CSV-only round trip does not restore them. A user
  /// who needs them in their backup should choose the JSON format
  /// instead.
  Future<bool> importDataCsv({
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final startedOn = ProfileStamp.now();
    final archive = await _pickAndDecodeArchive();

    // Decode all three before writing any, as in [importData] (#1357).
    final activityDBOs = _decodeCsv(
      _requireEntry(archive, userActivityCsvFileName),
      CsvDataExporter.parseUserActivitiesFromCsv,
    );
    // Same pre-#775 scaling as the JSON leg: a CSV without the
    // `meal_data_version` column came from a build that wrote raw grams.
    final intakeDBOs = _decodeCsv(
      _requireEntry(archive, userIntakeCsvFileName),
      CsvDataExporter.parseIntakesFromCsv,
    ).map(OffMicronutrientRepair.repairIntake).toList();
    final trackedDayDBOs = _decodeCsv(
      _requireEntry(archive, trackedDayCsvFileName),
      CsvDataExporter.parseTrackedDaysFromCsv,
    );

    final keyedBy = _decodeBoundary(
      archive.findFile(TrackedDayBoundaryRecord.csvFileName),
      TrackedDayBoundaryRecord.fromCsv,
    );

    final imported = await withTrackedDayLockOnProfile(
      () => _writeEntriesAndRows(
        activityDBOs,
        intakeDBOs,
        trackedDayDBOs,
        keyedBy,
      ).then((_) => true),
      startedOn: startedOn,
    );
    return imported ?? false;
  }

  /// Writes the entries and the rows, then moves the rows from the
  /// boundary the archive recorded, [keyedBy], onto the configured one
  /// (#1317). Under the tracked-day lock, so no writer adds an entry to a
  /// row between the import writing it and the move.
  Future<void> _writeEntriesAndRows(
    List<UserActivityDBO> activities,
    List<IntakeDBO> intakes,
    List<TrackedDayDBO> trackedDays,
    int? keyedBy,
  ) => withTrackedDayLock(() async {
    Future<void> write() async {
      await _userActivityRepository.upsertAllUserActivityDBOs(activities);
      await _intakeRepository.upsertAllIntakeDBOs(intakes);
      await _trackedDayRepository.addAllTrackedDays(trackedDays);
    }

    final restore = _restoreTrackedDays;
    if (restore == null) return write();
    await restore(
      write,
      importedDayKeys: {for (final day in trackedDays) day.day.toParsedDay()},
      importedActivities: activities,
      keyedByOffsetMinutes: keyedBy,
    );
  });

  /// The boundary the archive's rows are keyed by, from [entry], or null
  /// when the archive records none (#1317). A record that is not a
  /// boundary rejects the archive, like any other unreadable entry.
  int? _decodeBoundary(ArchiveFile? entry, int? Function(String) parse) {
    if (entry == null) return null;
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${entry.name}',
      () => parse(utf8.decode(entry.content as List<int>)),
    );
  }

  /// Lets the user pick a file and decodes it as a zip.
  ///
  /// The ways this can fall short are kept apart (#1103): a dismissed
  /// picker is [ExportImportFailureReason.cancelled], which is not an
  /// error. A pick the plugin could not hand back as a path, a file that
  /// cannot be read, and bytes the zip decoder rejects are all
  /// [ExportImportFailureReason.unreadableOrWrongFormat]. Note that the
  /// decoder accepts a plain `.csv` as an *empty* archive rather than
  /// rejecting it — that case is caught by [_missingEntry] instead.
  Future<Archive> _pickAndDecodeArchive() async {
    final result = await _pickFile();
    if (result == null) {
      throw const ExportImportFailure(
        ExportImportFailureReason.cancelled,
        'The user dismissed the file picker',
      );
    }
    final path = result.path;
    if (path == null) {
      throw ExportImportFailure(
        ExportImportFailureReason.unreadableOrWrongFormat,
        'The file picker returned "${result.name}" without a readable path',
      );
    }

    final zipBytes = await ExportImportFailure.guard(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not read the picked file $path',
      () => File(path).readAsBytes(),
    );
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'The picked file $path is not a zip archive',
      () => ZipDecoder().decodeBytes(zipBytes),
    );
  }

  /// The archive's [entryName] entry, or [_missingEntry] when it has none.
  ArchiveFile _requireEntry(Archive archive, String entryName) =>
      archive.findFile(entryName) ?? (throw _missingEntry(entryName));

  /// A zip that decodes but lacks a required entry is some other zip, not
  /// an OpenNutriTracker backup.
  ExportImportFailure _missingEntry(String entryName) => ExportImportFailure(
    ExportImportFailureReason.unreadableOrWrongFormat,
    'Required entry $entryName not found in the archive',
  );

  /// Decodes one archive entry holding a JSON array of [T] objects. A
  /// decode or `fromJson` failure is reported as wrong format rather than
  /// escaping as a bare `FormatException` / `TypeError`.
  List<T> _decodeJsonList<T>(
    ArchiveFile entry,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${entry.name}',
      () {
        final jsonString = utf8.decode(entry.content as List<int>);
        return (_decodeFinite(jsonString) as List)
            .cast<Map<String, dynamic>>()
            .map(fromJson)
            .toList();
      },
    );
  }

  /// [jsonDecode], but a number too large for a double (`1e400`), which
  /// decodes to an infinity, is a [FormatException]: stored on the device
  /// it would make the next JSON export throw. The CSV reader refuses
  /// `Infinity` the same way.
  static Object? _decodeFinite(String source) => jsonDecode(
    source,
    reviver: (key, value) {
      if (value is double && !value.isFinite) {
        throw FormatException('Not a finite number', '$key');
      }
      return value;
    },
  );

  /// CSV counterpart of [_decodeJsonList].
  List<T> _decodeCsv<T>(ArchiveFile entry, List<T> Function(String) parse) {
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${entry.name}',
      () => parse(utf8.decode(entry.content as List<int>)),
    );
  }
}
