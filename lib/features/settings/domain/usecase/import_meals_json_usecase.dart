import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';

/// Outcome of a JSON-paste import. [imported] is the number of entries
/// written to the diary; [savedAsCustomMeals] is how many of those entries
/// also landed in the saved-meals box (re-pastes of an already-saved name
/// are deduped, so this count is <= [imported]); [errorMessages] is the
/// per-entry parse errors the user should see. When [errorMessages] is
/// non-empty and [imported] is zero, nothing was written and the sheet
/// stays open so the user can fix the JSON.
class ImportMealsJsonResult {
  final int imported;
  final int savedAsCustomMeals;
  final List<String> errorMessages;

  const ImportMealsJsonResult({
    required this.imported,
    required this.savedAsCustomMeals,
    required this.errorMessages,
  });

  bool get hasErrors => errorMessages.isNotEmpty;
}

/// Parses a pasted JSON blob, writes the resulting intakes to the diary,
/// bumps the matching TrackedDay totals so the day card on the home screen
/// reflects the new entries straight away, and mirrors the CSV importer's
/// behaviour by also saving each pasted meal to the custom-meals box so
/// the user can log it again later from their saved-meals list without
/// re-typing the nutriments.
///
/// Custom-meal writes dedupe by case-insensitive name (matching the
/// existing CSV-import flow via [CustomMealDataSource.saveCustomMeal],
/// which already dedupes by name when the meal has no barcode). Re-pasting
/// the same entry creates a second intake but does not bloat the saved
/// list with a duplicate.
class ImportMealsJsonUsecase {
  final AddIntakeUsecase _addIntakeUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final CustomMealDataSource _customMealDataSource;

  ImportMealsJsonUsecase(
    this._addIntakeUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._customMealDataSource,
  );

  /// Picks a `.json` file from disk, validates the content as JSON via
  /// [JsonMealImporter.parse], and writes any successfully-parsed entries.
  /// Returns null when the user cancelled the file picker (mirroring the
  /// CSV importer contract).
  Future<ImportMealsJsonResult?> importFromPickedFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.single.path == null) {
      return null;
    }
    final file = File(picked.files.single.path!);
    final content = await file.readAsString(encoding: utf8);
    return importFromJsonString(content);
  }

  /// Parse [jsonContent] and write any successfully-parsed entries. The
  /// return value is null only when [jsonContent] is empty/whitespace.
  Future<ImportMealsJsonResult> importFromJsonString(String jsonContent) async {
    final parsed = JsonMealImporter.parse(jsonContent);

    // Pre-compute the names already in the custom-meals box (lower-cased)
    // so we can decide whether to save without hitting the box's linear
    // scan once per entry. The box is typically small (tens of entries),
    // but a paste of an array can be larger, and the local set also lets
    // us dedupe within the same paste (two "Apple" entries in one blob
    // produce two intakes but only one saved meal).
    final existingNames = <String>{
      for (final m in _customMealDataSource.getAllCustomMeals())
        if (m.name != null) m.name!.toLowerCase(),
    };

    var savedAsCustomMeals = 0;

    for (final intake in parsed.intakes) {
      await _addIntakeUsecase.addIntake(intake);
      await _ensureTrackedDay(intake.dateTime);
      await _addTrackedDayUsecase.addDayCaloriesTracked(
        intake.dateTime,
        intake.totalKcal,
      );
      await _addTrackedDayUsecase.addDayMacrosTracked(
        intake.dateTime,
        carbsTracked: intake.totalCarbsGram,
        fatTracked: intake.totalFatsGram,
        proteinTracked: intake.totalProteinsGram,
      );

      final mealName = intake.meal.name?.trim() ?? '';
      if (mealName.isEmpty) continue;
      final nameKey = mealName.toLowerCase();
      if (existingNames.contains(nameKey)) continue;

      await _customMealDataSource.saveCustomMeal(
        MealDBO.fromMealEntity(intake.meal),
      );
      existingNames.add(nameKey);
      savedAsCustomMeals++;
    }

    return ImportMealsJsonResult(
      imported: parsed.intakes.length,
      savedAsCustomMeals: savedAsCustomMeals,
      errorMessages: parsed.errors,
    );
  }

  Future<void> _ensureTrackedDay(DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (hasTrackedDay) return;
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
    final totalProteinGoal = await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);
    await _addTrackedDayUsecase.addNewTrackedDay(
      day,
      totalKcalGoal,
      totalCarbsGoal,
      totalFatGoal,
      totalProteinGoal,
    );
  }
}
