import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/other_profile_diaries_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

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
/// going forward, in every profile (#1421). TrackedDay calorie/macro totals
/// are reconciled from the per-intake before/after diff so charts stay
/// accurate.
///
/// Only operates on custom meals (`MealSourceDBO.custom`). Recipes and
/// OFF/FDC entries are out of scope by design.
class MergeCustomMealsUseCase {
  final CustomMealDataSource _customMealDataSource;
  final IntakeRepository _intakeRepository;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final FavouriteMealRepository _favouriteMealRepository;
  final OtherProfileDiariesUsecase _otherProfileDiaries;

  MergeCustomMealsUseCase(
    this._customMealDataSource,
    this._intakeRepository,
    this._addTrackedDayUsecase,
    this._favouriteMealRepository,
    this._otherProfileDiaries,
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
    // The entries and their rows together, so no reconciliation reads
    // the remapped entries against rows that do not have them yet (#1317).
    final rewrites = await withTrackedDayLock(() async {
      // The winner is the survivor; we snapshot its current MealDBO onto
      // every loser intake so they continue to read as the successor. The
      // library is shared, so the other profiles' entries move too (#1421).
      final rewrites = await _remapOnto(
        winner,
        loserKey,
        _intakeRepository,
        _addTrackedDayUsecase,
      );
      await _otherProfileDiaries.forEachLoggingCustomMeal(
        loserKey,
        (intakeRepository, addTrackedDayUsecase) async => rewrites.addAll(
          await _remapOnto(
            winner,
            loserKey,
            intakeRepository,
            addTrackedDayUsecase,
          ),
        ),
      );

      // A starred loser becomes a starred winner, in every profile, before
      // the loser leaves the library (#1307). Inside the lock with the
      // delete, so no profile switch lands between them.
      await _favouriteMealRepository.mergeCustomMealFavourite(loserKey, winner);
      await _customMealDataSource.deleteCustomMeal(loserKey);
      return rewrites;
    });

    return MergeCustomMealsResult(
      rewrittenIntakeCount: rewrites.length,
      winnerDisplayName: winner.name ?? winner.code ?? winnerKey,
    );
  }

  /// Remaps one profile's entries logged as [loserKey] onto [winner] and
  /// reconciles its TrackedDay totals from the macro diff per intake. If
  /// the two meals had identical nutrition this is a no-op; if they
  /// differed, the diary stays consistent with the winner going forward.
  static Future<List<(IntakeEntity, IntakeEntity)>> _remapOnto(
    MealDBO winner,
    String loserKey,
    IntakeRepository intakeRepository,
    AddTrackedDayUsecase addTrackedDayUsecase,
  ) async {
    final rewrites = await intakeRepository.remapCustomMealOnIntakes(
      fromMealKey: loserKey,
      toMeal: winner,
    );
    for (final pair in rewrites) {
      final before = pair.$1;
      final after = pair.$2;
      final kcalDelta = after.totalKcal - before.totalKcal;
      final carbsDelta = after.totalCarbsGram - before.totalCarbsGram;
      final fatDelta = after.totalFatsGram - before.totalFatsGram;
      final proteinDelta = after.totalProteinsGram - before.totalProteinsGram;
      if (kcalDelta != 0) {
        if (kcalDelta > 0) {
          await addTrackedDayUsecase.addDayCaloriesTracked(
            after.dateTime,
            kcalDelta,
          );
        } else {
          await addTrackedDayUsecase.removeDayCaloriesTracked(
            after.dateTime,
            -kcalDelta,
          );
        }
      }
      if (carbsDelta != 0 || fatDelta != 0 || proteinDelta != 0) {
        await addTrackedDayUsecase.addDayMacrosTracked(
          after.dateTime,
          carbsTracked: carbsDelta,
          fatTracked: fatDelta,
          proteinTracked: proteinDelta,
        );
      }
    }
    return rewrites;
  }
}
