import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';

/// Outcome of a JSON-paste import. [imported] is the number of entries
/// written to the diary; [errorMessages] is the per-entry parse errors
/// the user should see. When [errorMessages] is non-empty and [imported]
/// is zero, nothing was written and the sheet stays open so the user can
/// fix the JSON.
class ImportMealsJsonResult {
  final int imported;
  final List<String> errorMessages;

  const ImportMealsJsonResult({
    required this.imported,
    required this.errorMessages,
  });

  bool get hasErrors => errorMessages.isNotEmpty;
}

/// Parses a pasted JSON blob, writes the resulting intakes to the diary,
/// and bumps the matching TrackedDay totals so the day card on the home
/// screen reflects the new entries straight away.
class ImportMealsJsonUsecase {
  final AddIntakeUsecase _addIntakeUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  ImportMealsJsonUsecase(
    this._addIntakeUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
  );

  /// Parse [jsonContent] and write any successfully-parsed entries. The
  /// return value is null only when [jsonContent] is empty/whitespace.
  Future<ImportMealsJsonResult> importFromJsonString(String jsonContent) async {
    final parsed = JsonMealImporter.parse(jsonContent);

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
    }

    return ImportMealsJsonResult(
      imported: parsed.intakes.length,
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
