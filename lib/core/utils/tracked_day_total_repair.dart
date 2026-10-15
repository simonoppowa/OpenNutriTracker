import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

final _log = Logger('TrackedDayTotalRepair');

/// True when any tracked calorie or macro total of [day] is NaN or infinite.
bool hasNonFiniteTrackedTotal(TrackedDayDBO day) =>
    !day.caloriesTracked.isFinite ||
    !(day.carbsTracked?.isFinite ?? true) ||
    !(day.fatTracked?.isFinite ?? true) ||
    !(day.proteinTracked?.isFinite ?? true);

/// Rebuilds the tracked calorie and macro totals of every day that holds a
/// NaN or infinite one, from the intakes logged on that day (#1254).
///
/// A custom meal saved with a base quantity of 0 stored NaN nutriments, and
/// the day it was logged on added that NaN to its running totals. Every
/// later add or remove on that day kept it NaN, so the total cannot be
/// patched in place — only summed again from the intake log. The intakes
/// themselves read back finite (`MealNutrimentsEntity.fromMealNutrimentsDBO`
/// turns a stored NaN into null), so the broken entry contributes nothing
/// and every other entry that day counts again.
///
/// Intakes are matched to a day the same way the diary lists them: by the
/// configured day-start boundary. All four totals of a broken day are
/// rewritten together, like `reconcileCaloriesAndMacrosTracked` (#182).
///
/// Runs per profile before anything reads the box, like
/// `ensureOffMicronutrientsRepaired`. Idempotent: with no broken day it is
/// one in-memory scan and no write. Returns how many days were rebuilt.
Future<int> ensureTrackedDayTotalsFinite(
  HiveDBProvider db,
  ConfigDataSource configDataSource,
) async {
  final broken = db.trackedDayBox.values
      .where(hasNonFiniteTrackedTotal)
      .toList();
  if (broken.isEmpty) return 0;

  final config = ConfigEntity.fromConfigDBO(await configDataSource.getConfig());
  final offsetMinutes = DayBoundaryCalc.totalMinutesOf(
    config.dayStartOffsetHours,
    config.dayStartOffsetMinutes,
  );
  final intakes = db.intakeBox.values.map(IntakeEntity.fromIntakeDBO).toList();

  double finiteOrZero(double value) => value.isFinite ? value : 0;

  for (final day in broken) {
    var kcal = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var protein = 0.0;
    for (final intake in intakes) {
      if (!DayBoundaryCalc.isMomentInLogicalDayMinutes(
        day.day,
        intake.dateTime,
        offsetMinutes,
      )) {
        continue;
      }
      kcal += finiteOrZero(intake.totalKcal);
      carbs += finiteOrZero(intake.totalCarbsGram);
      fat += finiteOrZero(intake.totalFatsGram);
      protein += finiteOrZero(intake.totalProteinsGram);
    }
    day
      ..caloriesTracked = kcal
      ..carbsTracked = carbs
      ..fatTracked = fat
      ..proteinTracked = protein;
    await day.save();
  }

  _log.info(
    'Rebuilt the tracked totals of ${broken.length} days holding NaN or '
    'infinite values from their intakes (#1254)',
  );
  return broken.length;
}
