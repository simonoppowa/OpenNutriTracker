import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/utils/recipe_image_storage.dart';

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
  /// of json files at a user specified location.
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName,
  ) async {
    // Export user activity data to Json File Bytes
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    final fullUserActivityJson = jsonEncode(
      fullUserActivity.map((activity) => activity.toJson()).toList(),
    );
    final userActivityJsonBytes = utf8.encode(fullUserActivityJson);

    // Export intake data to Json File Bytes
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    final fullIntakeJson = jsonEncode(
      fullIntake.map((intake) => intake.toJson()).toList(),
    );
    final intakeJsonBytes = utf8.encode(fullIntakeJson);

    // Export tracked day data to Json File Bytes
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    final fullTrackedDayJson = jsonEncode(
      fullTrackedDay.map((trackedDay) => trackedDay.toJson()).toList(),
    );
    final trackedDayJsonBytes = utf8.encode(fullTrackedDayJson);

    // Export recipe data to Json File Bytes
    final fullRecipes = _recipeRepository.getAllRecipesDBO();
    final fullRecipesJson = jsonEncode(
      fullRecipes.map((recipe) => recipe.toJson()).toList(),
    );
    final recipeJsonBytes = utf8.encode(fullRecipesJson);

    // Create a zip file with the exported data
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
        userIntakeJsonFileName,
        intakeJsonBytes.length,
        intakeJsonBytes,
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
        recipeJsonFileName,
        recipeJsonBytes.length,
        recipeJsonBytes,
      ),
    );

    // Include any user-attached recipe photos under their relative slug
    // (e.g. `recipe_images/<id>.webp`). The slug matches what we persist on
    // RecipeDBO.imagePath, so import can drop the bytes back into place
    // without translating filenames.
    for (final recipe in fullRecipes) {
      final imagePath = recipe.imagePath;
      if (imagePath == null) continue;
      final sanitized = RecipeImageStorage.sanitizeRelative(imagePath);
      if (sanitized == null) continue;
      final absolute = await RecipeImageStorage.absolutePath(sanitized);
      final file = File(absolute);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(sanitized, bytes.length, bytes));
    }

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
