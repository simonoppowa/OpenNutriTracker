import 'package:collection/collection.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/visible_intakes.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Converts only recipe occurrences that carry their own ingredient snapshot.
/// The recipe library is deliberately never consulted during conversion.
class ExplodeRecipeIntakeUsecase {
  final HiveDBProvider _db;
  final ConfigDataSource _config;
  final _log = Logger('ExplodeRecipeIntakeUsecase');
  final _inFlight = <(Box<IntakeDBO>, String), Future<void>>{};

  ExplodeRecipeIntakeUsecase(this._db, this._config);

  static List<IntakeEntity> prepareIngredients(IntakeEntity intake) {
    final recipe = intake.recipeSnapshot;
    if (intake.meal.source != MealSourceEntity.recipe || recipe == null) {
      throw StateError('This recipe intake has no ingredient snapshot');
    }
    if (recipe.ingredients.isEmpty ||
        !recipe.totalWeightG.isFinite ||
        recipe.totalWeightG <= 0 ||
        !intake.amount.isFinite ||
        intake.amount <= 0) {
      throw StateError('Recipe ingredient quantities cannot be scaled');
    }

    final scale = intake.amount / recipe.totalWeightG;
    final children = <IntakeEntity>[];
    for (final ingredient in recipe.ingredients) {
      final amount = ingredient.convertedAmountG * scale;
      if (!amount.isFinite || amount <= 0) {
        throw StateError('Recipe ingredient quantities cannot be scaled');
      }
      final sourceUnit = ingredient.unit;
      final meal = ingredient.snapshotMeal;
      final isLiquid =
          MealEntity.liquidUnits.contains(sourceUnit) ||
          MealEntity.liquidUnits.contains(meal.mealUnit) ||
          MealEntity.liquidUnits.contains(meal.servingUnit);
      children.add(
        IntakeEntity(
          id: IdGenerator.getUniqueID(),
          unit: isLiquid ? 'ml' : 'g',
          amount: amount,
          type: intake.type,
          meal: meal,
          dateTime: intake.dateTime,
          conversionParentId: intake.id,
        ),
      );
    }
    return children;
  }

  /// Overlapping callers share one conversion, including its finalization.
  /// The box scopes intake IDs to the profile whose rows are being converted.
  Future<void> explode(String intakeId) async {
    final box = _db.intakeBox;
    final key = (box, intakeId);
    final running = _inFlight[key];
    if (running != null) return running;

    final run = _explode(box, intakeId);
    // Registered before yielding, so another caller cannot start a second run.
    _inFlight[key] = run;
    try {
      await run;
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Write the new rows first. Their parent link keeps them invisible until
  /// the original row is deleted. A crash on either side of that deletion is
  /// repaired by [recover] before Home or Diary reads the box again.
  Future<void> _explode(Box<IntakeDBO> box, String intakeId) async {
    final parent = box.values.firstWhereOrNull((i) => i.id == intakeId);
    if (parent == null) throw StateError('Recipe intake no longer exists');
    final ingredients = prepareIngredients(IntakeEntity.fromIntakeDBO(parent));
    try {
      for (final child in ingredients) {
        await box.add(IntakeDBO.fromIntakeEntity(child));
      }
      await parent.delete();
    } catch (_) {
      // If the parent still exists, nothing was committed. Remove every
      // partial child while leaving the original active and untouched.
      if (box.values.any((i) => i.id == intakeId)) {
        for (final child
            in box.values
                .where((i) => i.conversionParentId == intakeId)
                .toList()) {
          await child.delete();
        }
      }
      rethrow;
    }

    await _finishCommittedChildren(ingredients.first.dateTime, intakeId);
  }

  Future<void> _finishCommittedChildren(DateTime date, String parentId) async {
    try {
      await _reconcileDay(date);
      for (final child
          in _db.intakeBox.values
              .where((i) => i.conversionParentId == parentId)
              .toList()) {
        child.conversionParentId = null;
        await child.save();
      }
    } catch (error, stack) {
      // The children are already active because their parent is gone. Keep
      // their links so the next startup/profile switch can retry the cache
      // reconciliation; never restore the parent and double-count a day.
      _log.warning('Recipe conversion needs recovery', error, stack);
    }
  }

  Future<void> _reconcileDay(DateTime moment) async {
    final config = ConfigEntity.fromConfigDBO(await _config.getConfig());
    final offset = config.dayStartOffsetTotalMinutes;
    final wallDay = DateTime(moment.year, moment.month, moment.day);
    final day =
        DayBoundaryCalc.isMomentInLogicalDayMinutes(wallDay, moment, offset)
        ? wallDay
        : DateTime(moment.year, moment.month, moment.day - 1);
    final intakes = visibleIntakes(_db.intakeBox.values)
        .where(
          (i) => DayBoundaryCalc.isMomentInLogicalDayMinutes(
            day,
            i.dateTime,
            offset,
          ),
        )
        .map(IntakeEntity.fromIntakeDBO);
    var kcal = 0.0, carbs = 0.0, fat = 0.0, protein = 0.0;
    for (final intake in intakes) {
      kcal += intake.totalKcal;
      carbs += intake.totalCarbsGram;
      fat += intake.totalFatsGram;
      protein += intake.totalProteinsGram;
    }
    await TrackedDayDataSource(
      _db,
    ).reconcileCaloriesAndMacrosTracked(day, kcal, carbs, fat, protein);
  }

  /// Roll back incomplete conversions and finish those committed just before
  /// a crash. Idempotent; successful conversions have their links cleared.
  Future<void> recover() async {
    final box = _db.intakeBox;
    final pending = box.values
        .where((i) => i.conversionParentId != null)
        .toList();
    if (pending.isEmpty) return;
    final ids = box.values.map((i) => i.id).toSet();
    final committed = <String, DateTime>{};
    for (final child in pending) {
      final parentId = child.conversionParentId!;
      if (ids.contains(parentId)) {
        await child.delete();
      } else {
        committed[parentId] = child.dateTime;
      }
    }
    for (final entry in committed.entries) {
      await _finishCommittedChildren(entry.value, entry.key);
    }
  }
}
