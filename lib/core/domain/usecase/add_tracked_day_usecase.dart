import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';

class AddTrackedDayUsecase {
  final TrackedDayRepository _trackedDayRepository;

  AddTrackedDayUsecase(this._trackedDayRepository);

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    await _trackedDayRepository.updateDayCalorieGoal(day, calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayRepository.increaseDayCalorieGoal(day, amount);
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayRepository.reduceDayCalorieGoal(day, amount);
  }

  Future<bool> hasTrackedDay(DateTime day) async {
    return await _trackedDayRepository.hasTrackedDay(day);
  }

  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async {
    return await _trackedDayRepository.addNewTrackedDay(
      day,
      totalKcalGoal,
      totalCarbsGoal,
      totalFatGoal,
      totalProteinGoal,
    );
  }

  Future<void> addDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async {
    _trackedDayRepository.addDayTrackedCalories(day, caloriesTracked);
  }

  Future<void> removeDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async {
    await _trackedDayRepository.removeDayTrackedCalories(day, caloriesTracked);
  }

  Future<void> updateDayMacroGoals(
    DateTime day, {
    double? carbsGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
    await _trackedDayRepository.updateDayMacroGoal(
      day,
      carbGoal: carbsGoal,
      fatGoal: fatGoal,
      proteinGoal: proteinGoal,
    );
  }

  Future<void> increaseDayMacroGoals(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
    await _trackedDayRepository.increaseDayMacroGoal(
      day,
      carbGoal: carbsAmount,
      fatGoal: fatAmount,
      proteinGoal: proteinAmount,
    );
  }

  Future<void> reduceDayMacroGoals(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
    await _trackedDayRepository.reduceDayMacroGoal(
      day,
      carbGoal: carbsAmount,
      fatGoal: fatAmount,
      proteinGoal: proteinAmount,
    );
  }

  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {
    await _trackedDayRepository.addDayMacrosTracked(
      day,
      carbsTracked: carbsTracked,
      fatTracked: fatTracked,
      proteinTracked: proteinTracked,
    );
  }

  Future<void> removeDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {
    await _trackedDayRepository.removeDayMacrosTracked(
      day,
      carbsTracked: carbsTracked,
      fatTracked: fatTracked,
      proteinTracked: proteinTracked,
    );
  }

  /// #173 (+follow-up): persist user-configured per-nutrient goals for
  /// the day. Each argument is optional; passing null leaves that
  /// nutrient's stored goal alone. Null on disk means "use the default
  /// reference". Covers the original three (fibre / sat fat / sugars)
  /// plus the seven follow-up nutrients (sodium, calcium, iron,
  /// potassium, vitamin D, vitamin B12, magnesium).
  Future<void> updateDayNutrientGoals(
    DateTime day, {
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
    double? sodiumGoal,
    double? calciumGoal,
    double? ironGoal,
    double? potassiumGoal,
    double? vitaminDGoal,
    double? vitaminB12Goal,
    double? magnesiumGoal,
  }) async {
    await _trackedDayRepository.updateDayNutrientGoals(
      day,
      fibreGoal: fibreGoal,
      satFatGoal: satFatGoal,
      sugarsGoal: sugarsGoal,
      sodiumGoal: sodiumGoal,
      calciumGoal: calciumGoal,
      ironGoal: ironGoal,
      potassiumGoal: potassiumGoal,
      vitaminDGoal: vitaminDGoal,
      vitaminB12Goal: vitaminB12Goal,
      magnesiumGoal: magnesiumGoal,
    );
  }

  /// Overwrite cached tracked values with actual sums to fix stale data (#182)
  Future<void> reconcileDayTracked(DateTime day,
      double calories, double carbs, double fat, double protein) async {
    await _trackedDayRepository.reconcileDayTracked(day, calories, carbs, fat, protein);
  }
}
