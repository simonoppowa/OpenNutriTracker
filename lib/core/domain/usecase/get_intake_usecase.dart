import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class GetIntakeUsecase {
  final IntakeRepository _intakeRepository;
  final RecipeRepository _recipeRepository;

  GetIntakeUsecase(this._intakeRepository, this._recipeRepository);

  /// The day label the `getToday…` reads below filter on. The queries
  /// take a label, so the boundary has to be resolved here rather than
  /// handed a raw `DateTime.now()` — otherwise a 02:00 reading on a
  /// 06:00 boundary would ask for the wrong day (#586).
  DateTime _logicalToday(int offsetHours, int offsetMinutes) =>
      DayBoundaryCalc.currentLogicalDayLabel(offsetHours, offsetMinutes);

  Future<List<IntakeEntity>> _getIntakeByDay(
    IntakeTypeEntity type,
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    return await _intakeRepository.getIntakeByDateAndType(
      type,
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );
  }

  // #139: callers pass [dayStartOffsetHours] (and, since the follow-up,
  // [dayStartOffsetMinutes]) when they have the user's configured boundary.
  // Both default to 0 so every existing caller keeps wall-clock-midnight
  // behaviour exactly the same.
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await _getIntakeByDay(IntakeTypeEntity.breakfast, day,
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getTodayBreakfastIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      getBreakfastIntakeByDay(
          _logicalToday(dayStartOffsetHours, dayStartOffsetMinutes),
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getLunchIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await _getIntakeByDay(IntakeTypeEntity.lunch, day,
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getTodayLunchIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await getLunchIntakeByDay(
          _logicalToday(dayStartOffsetHours, dayStartOffsetMinutes),
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getDinnerIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await _getIntakeByDay(IntakeTypeEntity.dinner, day,
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getTodayDinnerIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await getDinnerIntakeByDay(
          _logicalToday(dayStartOffsetHours, dayStartOffsetMinutes),
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getSnackIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await _getIntakeByDay(IntakeTypeEntity.snack, day,
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  Future<List<IntakeEntity>> getTodaySnackIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async =>
      await getSnackIntakeByDay(
          _logicalToday(dayStartOffsetHours, dayStartOffsetMinutes),
          dayStartOffsetHours: dayStartOffsetHours,
          dayStartOffsetMinutes: dayStartOffsetMinutes);

  /// Recents are built from the meal snapshot each intake stored, which is
  /// right for the diary and wrong for re-logging: after a recipe is edited,
  /// its old name, nutrition and servings kept being offered (#1276). A
  /// recipe that still exists is offered as it is now; a deleted one keeps
  /// its last snapshot, and the intakes themselves are never rewritten.
  Future<List<IntakeEntity>> getRecentIntake() async {
    final recent = await _intakeRepository.getRecentIntake();
    return recent.map((intake) {
      final meal = intake.meal;
      if (meal.source != MealSourceEntity.recipe || meal.code == null) {
        return intake;
      }
      final recipe = _recipeRepository.getRecipeById(meal.code!);
      if (recipe == null) return intake;
      return IntakeEntity(
        id: intake.id,
        unit: intake.unit,
        amount: intake.amount,
        type: intake.type,
        meal: recipe.toMealEntity(),
        dateTime: intake.dateTime,
      );
    }).toList();
  }

  Future<IntakeEntity?> getIntakeById(String intakeId) async {
    return _intakeRepository.getIntakeById(intakeId);
  }

  Future<List<IntakeEntity>> getCustomMealIntakes() async {
    return _intakeRepository.getCustomMealIntakes();
  }
}
