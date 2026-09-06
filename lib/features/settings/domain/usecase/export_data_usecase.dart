import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/export_write_verifier.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

/// The two export shapes available from Settings → Export / Import App Data.
/// JSON is the canonical backup-and-restore format the app re-imports from;
/// CSV is a one-way spreadsheet-friendly view for analysis / sharing.
enum ExportFormat { json, csv }

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final RecipeRepository _recipeRepository;
  final CustomMealDataSource _customMealDataSource;
  final WeightLogRepository _weightLogRepository;
  final CustomActivityTemplateRepository _customActivityTemplateRepository;

  ExportDataUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._recipeRepository,
    this._customMealDataSource,
    this._weightLogRepository,
    this._customActivityTemplateRepository,
  );

  /// Exports user activity, intake, tracked day, recipe, weight-log and
  /// Custom activity template data to a zip at a user-specified location,
  /// in the [format] the user picked.
  ///
  /// JSON export contains JSON files only and is what the app re-imports
  /// from. CSV export contains CSV files only and is intended for
  /// opening in a spreadsheet — recipes, photos, the weight log and
  /// Custom activity templates are omitted from CSV because their shape
  /// doesn't flatten cleanly. A user who wants both can run the export
  /// twice. See `docs/export-format.md` for the schema.
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName,
    String weightLogJsonFileName,
    String customActivityTemplateJsonFileName, {
    ExportFormat format = ExportFormat.json,
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final archive = await assembleArchive(
      format: format,
      userActivityJsonFileName: userActivityJsonFileName,
      userIntakeJsonFileName: userIntakeJsonFileName,
      trackedDayJsonFileName: trackedDayJsonFileName,
      recipeJsonFileName: recipeJsonFileName,
      weightLogJsonFileName: weightLogJsonFileName,
      customActivityTemplateJsonFileName: customActivityTemplateJsonFileName,
      userActivityCsvFileName: userActivityCsvFileName,
      userIntakeCsvFileName: userIntakeCsvFileName,
      trackedDayCsvFileName: trackedDayCsvFileName,
    );

    // Save the zip file to the user-specified location
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes.isEmpty) {
      // We built the archive ourselves a few lines up, so this should be
      // unreachable — but if it ever happens, fail loudly rather than
      // handing FilePicker.saveFile an empty payload and calling that
      // a successful export.
      throw StateError('Export archive was empty, refusing to save it');
    }

    final result = await FilePicker.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    if (result == null) {
      // User cancelled the save dialog.
      return false;
    }

    ExportWriteVerifier.verify(result, zipBytes.length);
    return true;
  }

  /// Builds the bundle in memory, without touching the file picker.
  ///
  /// Split out so a test can assert what actually lands in the archive.
  /// `exportData` cannot be driven from a test — it ends in
  /// `FilePicker.saveFile` — so before this seam existed, the only thing
  /// covered was which photo paths get *collected*. Nothing checked that
  /// the bytes reached the zip under the right name, which is the half of
  /// #1061 that matters to someone restoring a backup.
  ///
  /// Extracted from @AzazelSensei's #1083, which had the seam and the test
  /// this exists for.
  @visibleForTesting
  Future<Archive> assembleArchive({
    required ExportFormat format,
    required String userActivityJsonFileName,
    required String userIntakeJsonFileName,
    required String trackedDayJsonFileName,
    required String recipeJsonFileName,
    required String weightLogJsonFileName,
    required String customActivityTemplateJsonFileName,
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final archive = Archive();

    // Activity dataset
    final fullUserActivity = await _userActivityRepository
        .getAllUserActivityDBO();
    if (format == ExportFormat.json) {
      final bytes = utf8.encode(
        jsonEncode(fullUserActivity.map((a) => a.toJson()).toList()),
      );
      archive.addFile(
        ArchiveFile(userActivityJsonFileName, bytes.length, bytes),
      );
    } else {
      final bytes = utf8.encode(
        CsvDataExporter.userActivitiesToCsv(fullUserActivity),
      );
      archive.addFile(
        ArchiveFile(userActivityCsvFileName, bytes.length, bytes),
      );
    }

    // Intake dataset
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    if (format == ExportFormat.json) {
      final bytes = utf8.encode(
        jsonEncode(fullIntake.map((i) => i.toJson()).toList()),
      );
      archive.addFile(ArchiveFile(userIntakeJsonFileName, bytes.length, bytes));
    } else {
      final bytes = utf8.encode(CsvDataExporter.intakesToCsv(fullIntake));
      archive.addFile(ArchiveFile(userIntakeCsvFileName, bytes.length, bytes));
    }

    // Tracked day dataset
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    if (format == ExportFormat.json) {
      final bytes = utf8.encode(
        jsonEncode(fullTrackedDay.map((d) => d.toJson()).toList()),
      );
      archive.addFile(ArchiveFile(trackedDayJsonFileName, bytes.length, bytes));
    } else {
      final bytes = utf8.encode(
        CsvDataExporter.trackedDaysToCsv(fullTrackedDay),
      );
      archive.addFile(ArchiveFile(trackedDayCsvFileName, bytes.length, bytes));
    }

    // Recipes, photos, weight log and Custom activity templates — JSON
    // only. The recipe shape doesn't flatten to CSV without lossy
    // denormalisation; meal / recipe photos are binary blobs; the
    // weight log is a JSON-only dataset for now; templates are a small
    // JSON-only convenience. A user who needs spreadsheet-shaped
    // recipes can fall back to the dedicated Sample / Import recipes
    // CSV path under Import Custom Food Data.
    if (format == ExportFormat.json) {
      final fullRecipes = _recipeRepository.getAllRecipesDBO();
      final recipeBytes = utf8.encode(
        jsonEncode(fullRecipes.map((r) => r.toJson()).toList()),
      );
      archive.addFile(
        ArchiveFile(recipeJsonFileName, recipeBytes.length, recipeBytes),
      );

      // Every user-attached photo, under its relative slug (e.g.
      // `recipe_images/<id>.webp`). The slug matches what we persist on
      // the DBO, so import can drop the bytes back into place without
      // translating filenames.
      for (final path in userImagePaths(
        recipes: fullRecipes,
        customMeals: _customMealDataSource.getAllCustomMeals(),
        intakes: fullIntake,
      )) {
        await _addUserImage(archive, path);
      }

      // Weight-log dataset
      final fullWeightLog = await _weightLogRepository.getAllEntriesDBO();
      final weightLogBytes = utf8.encode(
        jsonEncode(fullWeightLog.map((entry) => entry.toJson()).toList()),
      );
      archive.addFile(
        ArchiveFile(
          weightLogJsonFileName,
          weightLogBytes.length,
          weightLogBytes,
        ),
      );

      // Custom activity templates (#70 follow-up)
      final fullTemplates = await _customActivityTemplateRepository
          .allTemplateDBOs();
      final templatesBytes = utf8.encode(
        jsonEncode(fullTemplates.map((template) => template.toJson()).toList()),
      );
      archive.addFile(
        ArchiveFile(
          customActivityTemplateJsonFileName,
          templatesBytes.length,
          templatesBytes,
        ),
      );
    }

    return archive;
  }

  /// The relative slug of every user-attached photo that belongs in a JSON
  /// bundle, in archive order and without repeats.
  ///
  /// **Intakes are a source in their own right, not a duplicate of the
  /// templates.** A custom meal logged with *Save for next time* off writes
  /// no custom-meal record ([`edit_meal_screen`], #249), but the intake keeps
  /// its `localImagePath` and the diary card renders it. Gathering only from
  /// recipes and custom meals therefore put the reference in the JSON and
  /// left the bytes out of the zip, so a restore lost the photo with nothing
  /// failing anywhere (#1061).
  ///
  /// Deduplicated because the ordinary case — a saved custom meal that has
  /// also been logged — reaches this twice, and two archive entries with one
  /// name would double the bundle for every photographed meal.
  ///
  /// Pure, and separated from the file reads for that reason: which photos
  /// belong in the bundle is the part worth testing, and it needs no
  /// filesystem to answer.
  @visibleForTesting
  static List<String> userImagePaths({
    required Iterable<RecipeDBO> recipes,
    required Iterable<MealDBO> customMeals,
    required Iterable<IntakeDBO> intakes,
  }) {
    final seen = <String>{};
    final paths = <String>[];

    void add(String? relativePath) {
      if (relativePath == null) return;
      final sanitized = UserImageStorage.sanitizeRelative(relativePath);
      if (sanitized == null || !seen.add(sanitized)) return;
      paths.add(sanitized);
    }

    for (final recipe in recipes) {
      add(recipe.imagePath);
    }
    for (final meal in customMeals) {
      add(meal.localImagePath);
    }
    for (final intake in intakes) {
      add(intake.meal.localImagePath);
    }
    return paths;
  }

  /// Adds the bytes for one already-sanitized slug, if the file is still
  /// there. A missing file is not an error: the photo may have been cleared
  /// by the OS, and losing one image is not worth failing an export over.
  Future<void> _addUserImage(Archive archive, String sanitized) async {
    final absolute = await UserImageStorage.absolutePath(sanitized);
    final file = File(absolute);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(sanitized, bytes.length, bytes));
  }
}
