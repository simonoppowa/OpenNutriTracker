import 'package:opennutritracker/core/data/data_source/hidden_recent_data_source.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Removes a food from the add-meal Recently list (#1198).
///
/// Only the row goes: the diary entries behind it and any saved custom meal
/// or recipe stay as they are, and logging the food again brings the row
/// back. See [HiddenRecentDataSource].
class HideRecentMealUsecase {
  final IntakeRepository _intakeRepository;
  final HiddenRecentDataSource _hiddenRecent;

  HideRecentMealUsecase(this._intakeRepository, this._hiddenRecent);

  Future<void> hide(MealEntity meal) async {
    final intakeIds = await _intakeRepository.getIntakeIdsInRecentRow(meal);
    await _hiddenRecent.hide(intakeIds, DateTime.now());
  }
}
