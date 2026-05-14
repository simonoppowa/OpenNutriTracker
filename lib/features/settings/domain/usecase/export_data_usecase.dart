import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
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

  ExportDataUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._recipeRepository,
    this._customMealDataSource,
  );

  /// Exports user activity, intake, tracked day, and recipe data to a zip
  /// at a user-specified location, in the [format] the user picked.
  ///
  /// JSON export contains JSON files only and is what the app re-imports
  /// from. CSV export contains CSV files only and is intended for opening
  /// in a spreadsheet — recipes are omitted from CSV because their
  /// nested-ingredient shape doesn't fit a flat CSV cleanly. A user who
  /// wants both can run the export twice. See `docs/export-format.md`
  /// for the schema.
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName, {
    ExportFormat format = ExportFormat.json,
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final archive = Archive();

    // Activity dataset
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    if (format == ExportFormat.json) {
      final bytes = utf8.encode(jsonEncode(
        fullUserActivity.map((a) => a.toJson()).toList(),
      ));
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
      final bytes = utf8.encode(jsonEncode(
        fullIntake.map((i) => i.toJson()).toList(),
      ));
      archive.addFile(
        ArchiveFile(userIntakeJsonFileName, bytes.length, bytes),
      );
    } else {
      final bytes = utf8.encode(CsvDataExporter.intakesToCsv(fullIntake));
      archive.addFile(
        ArchiveFile(userIntakeCsvFileName, bytes.length, bytes),
      );
    }

    // Tracked day dataset
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    if (format == ExportFormat.json) {
      final bytes = utf8.encode(jsonEncode(
        fullTrackedDay.map((d) => d.toJson()).toList(),
      ));
      archive.addFile(
        ArchiveFile(trackedDayJsonFileName, bytes.length, bytes),
      );
    } else {
      final bytes = utf8.encode(
        CsvDataExporter.trackedDaysToCsv(fullTrackedDay),
      );
      archive.addFile(
        ArchiveFile(trackedDayCsvFileName, bytes.length, bytes),
      );
    }

    // Recipes — JSON only. The nested-ingredient shape doesn't flatten to
    // CSV without lossy denormalisation, and a CSV-export user can fall
    // back to the dedicated Sample / Import recipes CSV path under Import
    // Custom Food Data if they want spreadsheet-shaped recipe data.
    if (format == ExportFormat.json) {
      final fullRecipes = _recipeRepository.getAllRecipesDBO();
      final bytes = utf8.encode(jsonEncode(
        fullRecipes.map((r) => r.toJson()).toList(),
      ));
      archive.addFile(
        ArchiveFile(recipeJsonFileName, bytes.length, bytes),
      );

      // Include any user-attached recipe photos under their relative slug
      // (e.g. `recipe_images/<id>.webp`). The slug matches what we persist
      // on RecipeDBO.imagePath, so import can drop the bytes back into
      // place without translating filenames. CSV exports skip this for
      // the same reason they skip recipes — the format doesn't carry it.
      for (final recipe in fullRecipes) {
        await _addUserImageIfPresent(archive, recipe.imagePath);
      }

      // Custom-meal photos travel through the same `meal_images/`
      // subdirectory their relative slug names. Like recipes, these
      // only travel with JSON exports — CSV is one-way and meal photos
      // are a custom-meals concept that wouldn't survive the
      // spreadsheet round-trip anyway.
      final customMeals = _customMealDataSource.getAllCustomMeals();
      for (final meal in customMeals) {
        await _addUserImageIfPresent(archive, meal.localImagePath);
      }
    }

    // Save the zip file to the user-specified location
    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }

  Future<void> _addUserImageIfPresent(
    Archive archive,
    String? relativePath,
  ) async {
    if (relativePath == null) return;
    final sanitized = UserImageStorage.sanitizeRelative(relativePath);
    if (sanitized == null) return;
    final absolute = await UserImageStorage.absolutePath(sanitized);
    final file = File(absolute);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(sanitized, bytes.length, bytes));
  }
}
