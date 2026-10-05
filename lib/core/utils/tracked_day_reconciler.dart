import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

final _log = Logger('TrackedDayReconciler');

/// The goals a tracked-day row starts from before its activities raise it.
typedef TrackedDayGoals = ({
  double kcal,
  double? carbs,
  double? fat,
  double? protein,
});

/// Below this a total counts as zero: summing the same entries in another
/// order must not rewrite a row on every launch.
const _epsilon = 1e-6;

/// What the Diary lists under one day: the totals of its intakes and the
/// energy its activities burned.
class _ListedDay {
  var kcal = 0.0;
  var carbs = 0.0;
  var fat = 0.0;
  var protein = 0.0;
  var burned = 0.0;
}

/// Groups every intake and activity under the key of the row for the day
/// the Diary lists it under at [offsetMinutes] — the
/// [DayBoundaryCalc.dayLabelOf] rule the listing and
/// `TrackedDayDataSource` use, so the two cannot disagree.
Map<String, _ListedDay> _listedDays(HiveDBProvider db, int offsetMinutes) {
  double finiteOrZero(double value) => value.isFinite ? value : 0;
  String keyOf(DateTime moment) =>
      DayBoundaryCalc.dayKeyOf(moment, offsetMinutes);

  final days = <String, _ListedDay>{};
  for (final dbo in db.intakeBox.values) {
    final intake = IntakeEntity.fromIntakeDBO(dbo);
    days.putIfAbsent(keyOf(intake.dateTime), _ListedDay.new)
      ..kcal += finiteOrZero(intake.totalKcal)
      ..carbs += finiteOrZero(intake.totalCarbsGram)
      ..fat += finiteOrZero(intake.totalFatsGram)
      ..protein += finiteOrZero(intake.totalProteinsGram);
  }
  for (final activity in db.userActivityBox.values) {
    days.putIfAbsent(keyOf(activity.date), _ListedDay.new).burned +=
        finiteOrZero(activity.burnedKcal);
  }
  return days;
}

/// True unless [stored] is [value] within [_epsilon]; NaN never is.
bool _differs(double? stored, double value) =>
    !(((stored ?? 0) - value).abs() <= _epsilon);

bool _hasConsumed(TrackedDayDBO row) =>
    _differs(row.caloriesTracked, 0) ||
    _differs(row.carbsTracked, 0) ||
    _differs(row.fatTracked, 0) ||
    _differs(row.proteinTracked, 0);

/// Makes every tracked-day row agree with the entries the Diary lists on
/// its day at [offsetMinutes], and returns how many rows it wrote or
/// removed (#1317).
///
/// A row's consumed totals are derived data — the sum of the intakes
/// listed on its day — but every writer keeps them as a running total,
/// so a row keyed to another day than its entries keeps the wrong ones
/// forever: builds before the keying fix filed an entry logged at 02:00
/// under a 04:00 boundary on one day and its calories on the next, and a
/// changed boundary regroups the entries but not the rows. This rewrites
/// those totals as absolute sums:
///
///  * a row whose day lists entries gets its calorie and macro totals
///    summed from that day's intakes;
///  * a day that lists entries but has no row gets one, so the Diary
///    shows its summary instead of "Nothing added";
///  * a row whose day lists nothing is removed when it still counts
///    calories (they belong to entries listed on another day, which now
///    has them) or when [previousOffsetMinutes] listed entries on it
///    that moved away. Rows are only ever created by logging an entry, so
///    that row exists for entries it no longer has, and would otherwise
///    keep a calendar marker and a rating on a day with nothing logged. A
///    row with nothing listed and nothing counted is left alone: it is a
///    day whose entries were all deleted, and it keeps its goal.
///
/// Goals stay as they are, except for what activities add to them. A
/// row's goal is its base goal plus the energy burned by the activities
/// logged on it, and nothing stores the two apart, so only a known move
/// can be applied: when [previousOffsetMinutes] is given, each row's goal
/// changes by the burned energy listed on it now minus what was listed on
/// it then, with the macro goals following as `LogUserActivityUsecase`
/// raises them. A new row takes the base goals of the nearest row by date
/// — the goal of that period, where the current goal reflects today's
/// weight and settings — plus its own activities, and its per-nutrient
/// goals. Only with no row at all does it fall back to [currentGoals],
/// and without those it is not created.
///
/// Everything from the first read to the last write runs in one
/// synchronous step; the returned future only waits for the disk. Dart
/// runs no other code in between, and Hive applies a put to the box
/// before it returns, so no writer can change an entry or a row between
/// this reading and writing them, and a writer that resumes afterwards
/// builds on the rewritten row: existing rows are updated in place, never
/// replaced, so a writer still holding one does not save a stale copy
/// over it. Keep it free of `await`.
Future<int> reconcileTrackedDays(
  HiveDBProvider db, {
  required int offsetMinutes,
  int? previousOffsetMinutes,
  TrackedDayGoals? currentGoals,
}) {
  final rows = db.trackedDayBox;
  final listed = _listedDays(db, offsetMinutes);
  final listedBefore =
      previousOffsetMinutes == null || previousOffsetMinutes == offsetMinutes
      ? null
      : _listedDays(db, previousOffsetMinutes);
  // The burned energy each row's goal includes as it stands.
  double burnedOn(String key) => (listedBefore ?? listed)[key]?.burned ?? 0;

  final written = <dynamic, TrackedDayDBO>{};
  final removed = <dynamic>[];
  final existing = rows.toMap();
  // New rows first: they read the goals of the existing rows, which the
  // loop below changes in place.
  for (final MapEntry(:key, value: day) in listed.entries) {
    if (existing.containsKey(key)) continue;
    final row = _newRow(
      DateTime.parse(key),
      day,
      existing,
      burnedOn,
      currentGoals,
    );
    if (row == null) {
      _log.warning('No goal to create the tracked day of $key from');
      continue;
    }
    written[key] = row;
  }

  for (final MapEntry(:key, value: row) in existing.entries) {
    final day = listed[key];
    if (day == null) {
      if (_hasConsumed(row) || listedBefore?[key] != null) removed.add(key);
      continue;
    }
    var changed = false;
    if (_differs(row.caloriesTracked, day.kcal) ||
        _differs(row.carbsTracked, day.carbs) ||
        _differs(row.fatTracked, day.fat) ||
        _differs(row.proteinTracked, day.protein)) {
      row
        ..caloriesTracked = day.kcal
        ..carbsTracked = day.carbs
        ..fatTracked = day.fat
        ..proteinTracked = day.protein;
      changed = true;
    }
    final burnedMoved = day.burned - burnedOn(key);
    if (listedBefore != null && burnedMoved.abs() > _epsilon) {
      row
        ..calorieGoal += burnedMoved
        ..carbsGoal =
            (row.carbsGoal ?? 0) + MacroCalc.getTotalCarbsGoal(burnedMoved)
        ..fatGoal = (row.fatGoal ?? 0) + MacroCalc.getTotalFatsGoal(burnedMoved)
        ..proteinGoal =
            (row.proteinGoal ?? 0) +
            MacroCalc.getTotalProteinsGoal(burnedMoved);
      changed = true;
    }
    if (changed) written[key] = row;
  }

  final writes = [
    if (written.isNotEmpty) rows.putAll(written),
    if (removed.isNotEmpty) rows.deleteAll(removed),
  ];
  return Future.wait(writes).then((_) => written.length + removed.length);
}

/// The row of [date], which lists [day] but has none: base goals from the
/// nearest row (or [currentGoals] when there is none), raised by its own
/// activities, and totals summed from its intakes.
TrackedDayDBO? _newRow(
  DateTime date,
  _ListedDay day,
  Map<dynamic, TrackedDayDBO> rows,
  double Function(String key) burnedOn,
  TrackedDayGoals? currentGoals,
) {
  String? nearestKey;
  int? nearestDistance;
  for (final key in rows.keys) {
    final rowDate = key is String ? DateTime.tryParse(key) : null;
    if (rowDate == null) continue;
    final distance = rowDate.difference(date).inHours.abs();
    // Ties go to the earlier day.
    if (nearestDistance == null ||
        distance < nearestDistance ||
        (distance == nearestDistance && rowDate.isBefore(date))) {
      nearestKey = key as String;
      nearestDistance = distance;
    }
  }

  final nearest = nearestKey == null ? null : rows[nearestKey];
  TrackedDayGoals? base = currentGoals;
  if (nearest != null) {
    final burned = burnedOn(nearestKey!);
    double? less(double? goal, double amount) =>
        goal == null ? null : goal - amount;
    base = (
      kcal: nearest.calorieGoal - burned,
      carbs: less(nearest.carbsGoal, MacroCalc.getTotalCarbsGoal(burned)),
      fat: less(nearest.fatGoal, MacroCalc.getTotalFatsGoal(burned)),
      protein: less(
        nearest.proteinGoal,
        MacroCalc.getTotalProteinsGoal(burned),
      ),
    );
  }
  if (base == null) return null;

  double? more(double? goal, double amount) =>
      goal == null ? null : goal + amount;
  return TrackedDayDBO(
    day: date,
    calorieGoal: base.kcal + day.burned,
    caloriesTracked: day.kcal,
    carbsGoal: more(base.carbs, MacroCalc.getTotalCarbsGoal(day.burned)),
    carbsTracked: day.carbs,
    fatGoal: more(base.fat, MacroCalc.getTotalFatsGoal(day.burned)),
    fatTracked: day.fat,
    proteinGoal: more(base.protein, MacroCalc.getTotalProteinsGoal(day.burned)),
    proteinTracked: day.protein,
    fibreGoal: nearest?.fibreGoal,
    satFatGoal: nearest?.satFatGoal,
    sugarsGoal: nearest?.sugarsGoal,
    sodiumGoal: nearest?.sodiumGoal,
    calciumGoal: nearest?.calciumGoal,
    ironGoal: nearest?.ironGoal,
    potassiumGoal: nearest?.potassiumGoal,
    vitaminDGoal: nearest?.vitaminDGoal,
    vitaminB12Goal: nearest?.vitaminB12Goal,
    magnesiumGoal: nearest?.magnesiumGoal,
  );
}

int _offsetMinutesNow(ConfigDataSource configDataSource) {
  final config = ConfigEntity.fromConfigDBO(configDataSource.getConfigNow());
  return DayBoundaryCalc.totalMinutesOf(
    config.dayStartOffsetHours,
    config.dayStartOffsetMinutes,
  );
}

/// Runs [reconcileTrackedDays] at the configured boundary (#1317).
///
/// Called on every profile activation — startup and a profile switch —
/// before anything reads the rows, like `ensureTrackedDayTotalsFinite`.
/// That covers the rows older builds keyed to another day than the
/// Diary lists their entries under, days they left without a row, and,
/// because the boundary is app-wide, a profile that was not active when
/// the boundary moved. Idempotent: on rows that already agree it is one
/// in-memory scan of the entries and no write.
///
/// [currentGoals] is only asked for when the profile lists entries but
/// has no row at all, so there is no nearer goal to start one from. It is
/// awaited before the reconciliation reads anything.
Future<int> ensureTrackedDaysMatchEntries(
  HiveDBProvider db,
  ConfigDataSource configDataSource, {
  Future<TrackedDayGoals> Function()? currentGoals,
}) async {
  TrackedDayGoals? goals;
  if (currentGoals != null &&
      db.trackedDayBox.isEmpty &&
      (db.intakeBox.isNotEmpty || db.userActivityBox.isNotEmpty)) {
    try {
      goals = await currentGoals();
    } catch (e, stack) {
      _log.warning('Could not compute the current goals', e, stack);
    }
  }
  final changed = await reconcileTrackedDays(
    db,
    offsetMinutes: _offsetMinutesNow(configDataSource),
    currentGoals: goals,
  );
  if (changed > 0) {
    _log.info(
      'Brought $changed tracked days in line with the entries the Diary '
      'lists on them (#1317)',
    );
  }
  return changed;
}

/// Moves the day boundary to [hours]:[minutes] and the active profile's
/// tracked-day rows with it (#1317).
///
/// The config write and the regrouping happen in one synchronous step, so
/// no code sees the new boundary with the rows still keyed by the old one.
/// Besides the totals, each row's goal follows the activities that move
/// on or off its day. Other profiles are regrouped by
/// [ensureTrackedDaysMatchEntries] when they are next activated, which
/// fixes their totals but cannot move activity energy, since the
/// boundary they were keyed under is not recorded.
Future<void> moveDayBoundary(
  HiveDBProvider db,
  ConfigDataSource configDataSource,
  int hours,
  int minutes,
) {
  final before = _offsetMinutesNow(configDataSource);
  final configWritten = configDataSource.setConfigDayStartOffset(
    hours,
    minutes,
  );
  final rowsWritten = reconcileTrackedDays(
    db,
    offsetMinutes: _offsetMinutesNow(configDataSource),
    previousOffsetMinutes: before,
  );
  return Future.wait([configWritten, rowsWritten]);
}
