import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

class ImportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final RecipeRepository _recipeRepository;

  ImportDataUsecase(
    this._userActivityRepository,
    this._intakeRepository,
    this._trackedDayRepository,
    this._recipeRepository,
  );

  /// Imports user activity, intake, tracked day, and (optionally) recipe
  /// data from a zip file containing JSON files. Recipe file is treated as
  /// optional so zips exported by older versions still import.
  ///
  /// Returns true if import was successful, false otherwise.
  Future<bool> importData(
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName,
  ) async {
    // Allow user to pick a zip file
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('No file selected');
    }

    // Read the file bytes using the file path
    final file = File(result.files.single.path!);
    final zipBytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Extract and process user activity data
    final userActivityFile = archive.findFile(userActivityJsonFileName);
    if (userActivityFile != null) {
      final userActivityJsonString = utf8.decode(
        userActivityFile.content as List<int>,
      );
      final userActivityList = (jsonDecode(userActivityJsonString) as List)
          .cast<Map<String, dynamic>>();

      final userActivityDBOs = userActivityList
          .map((json) => UserActivityDBO.fromJson(json))
          .toList();

      await _userActivityRepository.addAllUserActivityDBOs(userActivityDBOs);
    } else {
      throw Exception('User activity file not found in the archive');
    }

    // Extract and process intake data
    final intakeFile = archive.findFile(userIntakeJsonFileName);
    if (intakeFile != null) {
      final intakeJsonString = utf8.decode(intakeFile.content as List<int>);
      final intakeList =
          (jsonDecode(intakeJsonString) as List).cast<Map<String, dynamic>>();

      final intakeDBOs =
          intakeList.map((json) => IntakeDBO.fromJson(json)).toList();

      await _intakeRepository.addAllIntakeDBOs(intakeDBOs);
    } else {
      throw Exception('Intake file not found in the archive');
    }

    // Extract and process tracked day data
    final trackedDayFile = archive.findFile(trackedDayJsonFileName);
    if (trackedDayFile != null) {
      final trackedDayJsonString = utf8.decode(
        trackedDayFile.content as List<int>,
      );
      final trackedDayList = (jsonDecode(trackedDayJsonString) as List)
          .cast<Map<String, dynamic>>();

      final trackedDayDBOs =
          trackedDayList.map((json) => TrackedDayDBO.fromJson(json)).toList();

      await _trackedDayRepository.addAllTrackedDays(trackedDayDBOs);
    } else {
      throw Exception('Tracked day file not found in the archive');
    }

    // Extract and process recipe data — optional so older zips still import.
    final recipeFile = archive.findFile(recipeJsonFileName);
    if (recipeFile != null) {
      final recipeJsonString = utf8.decode(recipeFile.content as List<int>);
      final recipeList =
          (jsonDecode(recipeJsonString) as List).cast<Map<String, dynamic>>();
      final recipeDBOs =
          recipeList.map((json) => RecipeDBO.fromJson(json)).toList();
      await _recipeRepository.addAllRecipeDBOs(recipeDBOs);
    }

    // Restore any user-attached photos — recipes under `recipe_images/`
    // and custom meals under `meal_images/`. Each archive entry's name
    // already matches the relative slug we stored on the matching DBO,
    // so we just write the bytes back into the right private documents
    // subdirectory. Anything outside those known prefixes is skipped by
    // the sanitiser, so a hostile zip can't escape into other folders.
    final recipeDir =
        await UserImageStorage.ensureDirectory(UserImageKind.recipe);
    final mealDir =
        await UserImageStorage.ensureDirectory(UserImageKind.meal);
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final sanitized = UserImageStorage.sanitizeRelative(entry.name);
      if (sanitized == null) continue;
      final parts = sanitized.split('/');
      final targetDir =
          parts[0] == UserImageKind.recipe.subdir ? recipeDir : mealDir;
      final destPath = '${targetDir.path}/${parts[1]}';
      final destFile = File(destPath);
      await destFile.writeAsBytes(entry.content as List<int>, flush: true);
    }

    return true;
  }

  /// Symmetric CSV counterpart to [importData]. Reads a zip produced by
  /// `ExportDataUsecase.exportData(format: ExportFormat.csv)` and feeds
  /// each CSV through the matching `parse...FromCsv` helper on
  /// [CsvDataExporter]. Recipes are intentionally not handled here — CSV
  /// export omits them by design (the nested-ingredient shape doesn't
  /// flatten cleanly), so a CSV-only round trip does not restore
  /// recipes. A user who needs recipes in their backup should choose
  /// the JSON format instead.
  Future<bool> importDataCsv({
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) {
      throw Exception('No file selected');
    }

    final file = File(result.files.single.path!);
    final zipBytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final activityFile = archive.findFile(userActivityCsvFileName);
    if (activityFile != null) {
      final csv = utf8.decode(activityFile.content as List<int>);
      final dbos = CsvDataExporter.parseUserActivitiesFromCsv(csv);
      await _userActivityRepository.addAllUserActivityDBOs(dbos);
    } else {
      throw Exception('User activity CSV not found in the archive');
    }

    final intakeFile = archive.findFile(userIntakeCsvFileName);
    if (intakeFile != null) {
      final csv = utf8.decode(intakeFile.content as List<int>);
      final dbos = CsvDataExporter.parseIntakesFromCsv(csv);
      await _intakeRepository.addAllIntakeDBOs(dbos);
    } else {
      throw Exception('Intake CSV not found in the archive');
    }

    final trackedDayFile = archive.findFile(trackedDayCsvFileName);
    if (trackedDayFile != null) {
      final csv = utf8.decode(trackedDayFile.content as List<int>);
      final dbos = CsvDataExporter.parseTrackedDaysFromCsv(csv);
      await _trackedDayRepository.addAllTrackedDays(dbos);
    } else {
      throw Exception('Tracked day CSV not found in the archive');
    }

    return true;
  }
}
