import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final RecipeRepository _recipeRepository;

  ExportDataUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._recipeRepository,
  );

  /// Exports user activity, intake, tracked day, and recipe data to a zip
  /// at a user-specified location.
  ///
  /// The zip now contains both JSON and CSV representations of each
  /// dataset (recipes are JSON-only because the nested-ingredient shape
  /// doesn't fit a flat CSV cleanly). JSON remains the canonical format
  /// the app re-imports from; the CSV companion is for users who want a
  /// plaintext, Syncthing-friendly file they can open in a spreadsheet
  /// (#40, #132). See `docs/export-format.md` for the full schema.
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName, {
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    // Export user activity data to Json File Bytes
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    final fullUserActivityJson = jsonEncode(
      fullUserActivity.map((activity) => activity.toJson()).toList(),
    );
    final userActivityJsonBytes = utf8.encode(fullUserActivityJson);
    final userActivityCsvBytes = utf8.encode(
      CsvDataExporter.userActivitiesToCsv(fullUserActivity),
    );

    // Export intake data to Json File Bytes
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    final fullIntakeJson = jsonEncode(
      fullIntake.map((intake) => intake.toJson()).toList(),
    );
    final intakeJsonBytes = utf8.encode(fullIntakeJson);
    final intakeCsvBytes = utf8.encode(
      CsvDataExporter.intakesToCsv(fullIntake),
    );

    // Export tracked day data to Json File Bytes
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    final fullTrackedDayJson = jsonEncode(
      fullTrackedDay.map((trackedDay) => trackedDay.toJson()).toList(),
    );
    final trackedDayJsonBytes = utf8.encode(fullTrackedDayJson);
    final trackedDayCsvBytes = utf8.encode(
      CsvDataExporter.trackedDaysToCsv(fullTrackedDay),
    );

    // Export recipe data to Json File Bytes
    final fullRecipes = _recipeRepository.getAllRecipesDBO();
    final fullRecipesJson = jsonEncode(
      fullRecipes.map((recipe) => recipe.toJson()).toList(),
    );
    final recipeJsonBytes = utf8.encode(fullRecipesJson);

    // Create a zip file with the exported data. Each non-recipe dataset
    // is written twice (JSON + CSV) so the round-trip is preserved for
    // re-import via this app *and* a spreadsheet can read the same data
    // without further conversion.
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        userActivityJsonFileName,
        userActivityJsonBytes.length,
        userActivityJsonBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        userActivityCsvFileName,
        userActivityCsvBytes.length,
        userActivityCsvBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        userIntakeJsonFileName,
        intakeJsonBytes.length,
        intakeJsonBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        userIntakeCsvFileName,
        intakeCsvBytes.length,
        intakeCsvBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        trackedDayJsonFileName,
        trackedDayJsonBytes.length,
        trackedDayJsonBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        trackedDayCsvFileName,
        trackedDayCsvBytes.length,
        trackedDayCsvBytes,
      ),
    );
    archive.addFile(
      ArchiveFile(
        recipeJsonFileName,
        recipeJsonBytes.length,
        recipeJsonBytes,
      ),
    );

    // Save the zip file to the user specified location
    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }
}
