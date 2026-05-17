import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';

/// Result of a merge: how many past diary entries were rewritten so the
/// caller can show a friendly confirmation to the person who triggered it.
class MergeCustomMealsResult {
  final int rewrittenIntakeCount;
  final String winnerDisplayName;

  const MergeCustomMealsResult({
    required this.rewrittenIntakeCount,
    required this.winnerDisplayName,
  });
}

/// Folds two duplicate custom meals into one. The non-successor ("loser")
/// is removed from the saved-meals list, and every diary entry that was
/// logged from the loser is rewritten so that it reads as the successor
/// going forward. TrackedDay calorie/macro totals are reconciled from the
/// per-intake before/after diff so charts stay accurate.
///
/// Only operates on custom meals (`MealSourceDBO.custom`). Recipes and
/// OFF/FDC entries are out of scope by design.
class MergeCustomMealsUseCase {
  final CustomMealDataSource _customMealDataSource;
  final IntakeRepository _intakeRepository;
  final AddTrackedDayUsecase _addTrackedDayUsecase;

  MergeCustomMealsUseCase(
    this._customMealDataSource,
    this._intakeRepository,
    this._addTrackedDayUsecase,
  );

  /// [loserKey] / [winnerKey] are the dedup keys used everywhere else in
  /// the custom-meal layer (`meal.code ?? meal.name`).
  Future<MergeCustomMealsResult> merge({
    required String loserKey,
    required String winnerKey,
  }) async {
    if (loserKey == winnerKey) {
      return const MergeCustomMealsResult(
        rewrittenIntakeCount: 0,
        winnerDisplayName: '',
      );
    }

    final all = _customMealDataSource.getAllCustomMeals();
    final winner = all.firstWhere(
      (m) => (m.code ?? m.name) == winnerKey,
      orElse: () => throw StateError('Winner custom meal not found'),
    );
    // The winner is the survivor; we snapshot its current MealDBO onto
    // every loser intake so they continue to read as the successor.
    final rewrites = await _intakeRepository.remapCustomMealOnIntakes(
      fromMealKey: loserKey,
      toMeal: winner,
    );

    // Reconcile TrackedDay totals from the macro diff per intake. If the two
    // meals had identical nutrition this is a no-op; if they differed, the
    // diary stays consistent with the winner going forward.
    for (final pair in rewrites) {
      final before = pair.$1;
      final after = pair.$2;
      final kcalDelta = after.totalKcal - before.totalKcal;
      final carbsDelta = after.totalCarbsGram - before.totalCarbsGram;
      final fatDelta = after.totalFatsGram - before.totalFatsGram;
      final proteinDelta = after.totalProteinsGram - before.totalProteinsGram;
      if (kcalDelta != 0) {
        if (kcalDelta > 0) {
          await _addTrackedDayUsecase.addDayCaloriesTracked(
            after.dateTime,
            kcalDelta,
          );
        } else {
          await _addTrackedDayUsecase.removeDayCaloriesTracked(
            after.dateTime,
            -kcalDelta,
          );
        }
      }
      if (carbsDelta != 0 || fatDelta != 0 || proteinDelta != 0) {
        await _addTrackedDayUsecase.addDayMacrosTracked(
          after.dateTime,
          carbsTracked: carbsDelta,
          fatTracked: fatDelta,
          proteinTracked: proteinDelta,
        );
      }
    }

    await _customMealDataSource.deleteCustomMeal(loserKey);

    return MergeCustomMealsResult(
      rewrittenIntakeCount: rewrites.length,
      winnerDisplayName: winner.name ?? winner.code ?? winnerKey,
    );
  }
}
