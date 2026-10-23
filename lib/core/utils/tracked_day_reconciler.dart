import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/box_upsert.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/tracked_day_total_repair.dart';

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

double _finiteOrZero(double value) => value.isFinite ? value : 0;

/// The key of the row for the day the Diary lists [activity] under at
/// [offsetMinutes], or at [importOffsetMinutes] for an imported workout
/// when that is given; see [reconcileTrackedDays].
String _activityKey(
  UserActivityDBO activity,
  int offsetMinutes,
  int? importOffsetMinutes,
) => DayBoundaryCalc.dayKeyOf(
  activity.date,
  importOffsetMinutes != null && activity.externalId != null
      ? importOffsetMinutes
      : offsetMinutes,
  clockReading: activity.externalId != null,
);

/// Groups every intake and activity under the key of the row for the day
/// the Diary lists it under at [offsetMinutes] — the
/// [DayBoundaryCalc.dayLabelOf] rule the listing and
/// `TrackedDayDataSource` use, so the two cannot disagree.
///
/// Imported workouts go by [importOffsetMinutes] instead when it is
/// given; see [reconcileTrackedDays].
Map<String, _ListedDay> _listedDays(
  HiveDBProvider db,
  int offsetMinutes, {
  int? importOffsetMinutes,
}) {
  String keyOf(DateTime moment) =>
      DayBoundaryCalc.dayKeyOf(moment, offsetMinutes);

  final days = <String, _ListedDay>{};
  for (final dbo in db.intakeBox.values) {
    final intake = IntakeEntity.fromIntakeDBO(dbo);
    days.putIfAbsent(keyOf(intake.dateTime), _ListedDay.new)
      ..kcal += _finiteOrZero(intake.totalKcal)
      ..carbs += _finiteOrZero(intake.totalCarbsGram)
      ..fat += _finiteOrZero(intake.totalFatsGram)
      ..protein += _finiteOrZero(intake.totalProteinsGram);
  }
  for (final activity in db.userActivityBox.values) {
    final key = _activityKey(activity, offsetMinutes, importOffsetMinutes);
    days.putIfAbsent(key, _ListedDay.new).burned += _finiteOrZero(
      activity.burnedKcal,
    );
  }
  return days;
}

/// The energy [activities] burned, by the key of the row for the day each
/// is listed under, by the [_activityKey] rule.
Map<String, double> _burnedByDay(
  Iterable<UserActivityDBO> activities,
  int offsetMinutes, {
  int? importOffsetMinutes,
}) {
  final burned = <String, double>{};
  for (final activity in activities) {
    final key = _activityKey(activity, offsetMinutes, importOffsetMinutes);
    burned[key] = (burned[key] ?? 0) + _finiteOrZero(activity.burnedKcal);
  }
  return burned;
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
/// raises them. [previousImportOffsetMinutes], when given, is where
/// imported workouts were credited instead: builds before #1317 keyed a
/// row by the wall-clock date of whatever logged it, except the workout
/// import, which credited the workout's logical day. [previousKeys], when
/// given, limits both to those rows: every other row is keyed by
/// [offsetMinutes] already, as after a restore wrote only the rows of its
/// archive.
///
/// [creditedBurned], when given, is the burned energy each row's goal
/// includes, for when the entries on file cannot tell: after a restore an
/// archive's activities are listed on the device's rows too, which never
/// credited them. Each row's goal then changes by the burned energy
/// listed on it minus its entry there (none: nothing), whatever the
/// boundaries.
///
/// A new row takes the base goals of the nearest row by date — the goal
/// of that period, where the current goal reflects today's weight and
/// settings — plus its own activities, and its per-nutrient goals. Only
/// with no row at all does it fall back to [currentGoals], and without
/// those it is not created.
///
/// Everything from the first read to the last write runs in one
/// synchronous step; the returned future only waits for the disk. Dart
/// runs no other code in between, and Hive applies a put to the box
/// before it returns, so no writer can change an entry or a row between
/// this reading and writing them. Existing rows are updated in place,
/// never replaced, so a writer still holding one does not save a stale
/// copy over it. Keep it free of `await`.
///
/// That does not cover a writer that has stored its entry but not yet
/// added it to the row: this would count the entry and the writer would
/// add it again. Call it inside [withTrackedDayLock], which every such
/// writer holds across both steps.
Future<int> reconcileTrackedDays(
  HiveDBProvider db, {
  required int offsetMinutes,
  int? previousOffsetMinutes,
  int? previousImportOffsetMinutes,
  Set<String>? previousKeys,
  Map<String, double>? creditedBurned,
  TrackedDayGoals? currentGoals,
}) {
  final rows = db.trackedDayBox;
  final listed = _listedDays(db, offsetMinutes);
  final previousImports = previousImportOffsetMinutes ?? previousOffsetMinutes;
  final listedBefore =
      previousOffsetMinutes == null ||
          (previousOffsetMinutes == offsetMinutes &&
              previousImports == offsetMinutes)
      ? null
      : _listedDays(
          db,
          previousOffsetMinutes,
          importOffsetMinutes: previousImports,
        );
  // What each row was keyed by: the previous boundary, or for a row
  // outside [previousKeys] the current one.
  Map<String, _ListedDay>? before(Object? key) =>
      previousKeys == null || previousKeys.contains(key) ? listedBefore : null;
  // The burned energy each row's goal includes as it stands.
  double burnedOn(String key) => creditedBurned != null
      ? creditedBurned[key] ?? 0
      : (before(key) ?? listed)[key]?.burned ?? 0;
  final movesCredit = listedBefore != null || creditedBurned != null;

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
      if (_hasConsumed(row) || before(key)?[key] != null) removed.add(key);
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
    if (movesCredit && burnedMoved.abs() > _epsilon) {
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
  // Counted in calendar days, not hours: the keys parse to local
  // midnights, and across a daylight-saving change two of those are 23 or
  // 25 hours apart, which would break the tie between rows a day either
  // side.
  int dayNumber(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final target = dayNumber(date);
  String? nearestKey;
  int? nearestDistance;
  for (final key in rows.keys) {
    final rowDate = key is String ? DateTime.tryParse(key) : null;
    if (rowDate == null) continue;
    final distance = (dayNumber(rowDate) - target).abs();
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

/// Runs [reconcileTrackedDays] at the configured boundary (#1317), moving
/// the active profile's rows from the boundary they are keyed by.
///
/// Called on every profile activation — startup and a profile switch —
/// before anything reads the rows, like `ensureTrackedDayTotalsFinite`.
/// That covers the rows older builds keyed to another day than the
/// Diary lists their entries under, days they left without a row, and,
/// because the boundary is app-wide, a profile that was not active when
/// the boundary moved.
///
/// The boundary the rows are keyed by is the profile's recorded
/// [ConfigDBO.trackedDaysOffsetMinutes], or 0 for rows no build since
/// #1317 has touched: those builds keyed each row by the wall-clock date
/// of whatever logged it — except the workout import, which credited a
/// workout's logical day, taken here at the current boundary since the
/// one it ran under is not known. Passing it on lets the move take
/// activity energy along, so an activity's goal credit leaves the row it
/// was filed on instead of being credited again where it is listed now.
/// The boundary is recorded in the same step. Once it matches, this is
/// one in-memory scan of the entries and no write.
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
  final changed = await withTrackedDayLock(() async {
    final offset = _offsetMinutesNow(configDataSource);
    final recordedBy = configDataSource.getConfigNow().trackedDaysOffsetMinutes;
    final keyedBy = recordedBy ?? 0;
    final rowsWritten = reconcileTrackedDays(
      db,
      offsetMinutes: offset,
      previousOffsetMinutes: keyedBy,
      previousImportOffsetMinutes: recordedBy == null ? offset : null,
      currentGoals: goals,
    );
    final recorded = recordedBy == offset
        ? null
        : configDataSource.setConfigTrackedDaysOffsetMinutes(offset);
    final changed = await rowsWritten;
    await recorded;
    return changed;
  });
  if (changed > 0) {
    _log.info(
      'Brought $changed tracked days in line with the entries the Diary '
      'lists on them (#1317)',
    );
  }
  return changed;
}

/// Records the configured boundary as the one the active profile's rows
/// are keyed by, for a profile that has just been emptied (#1317).
///
/// [ensureTrackedDaysMatchEntries] reads a missing record as a legacy
/// history keyed at midnight. A reset profile has no such history, but
/// the boundary is app-wide and survives the reset, so rows it writes
/// next are keyed by that boundary. Left unrecorded, the next activation
/// would move them as if they were midnight-keyed and credit an activity
/// before the boundary a second time. Must run inside the tracked-day
/// lock that emptied the rows, so nothing is written between the two.
Future<void> recordTrackedDayBoundary(ConfigDataSource configDataSource) =>
    configDataSource.setConfigTrackedDaysOffsetMinutes(
      _offsetMinutesNow(configDataSource),
    );

/// The tracked-day repairs every profile activation runs — startup and a
/// profile switch — before anything reads the rows (#1317, #1254).
///
/// The reconciliation has to go first. The NaN repair sums a broken row's
/// totals from the entries listed on its day, so on a stale row — keyed
/// to a day that lists none of its entries — it writes zeros, and the
/// reconciliation would then keep that row as a day whose entries were
/// all deleted, calendar marker and all. Run first, the reconciliation
/// counts the NaN as calories and removes the stale row, and rewrites the
/// totals of a broken row whose day does list entries.
Future<void> ensureTrackedDaysRepaired(
  HiveDBProvider db,
  ConfigDataSource configDataSource, {
  Future<TrackedDayGoals> Function()? currentGoals,
}) async {
  await ensureTrackedDaysMatchEntries(
    db,
    configDataSource,
    currentGoals: currentGoals,
  );
  await ensureTrackedDayTotalsFinite(db, configDataSource);
}

/// Runs a restore's [write] of entries and rows, then brings the rows it
/// wrote, under [importedDayKeys], onto the configured boundary (#1317).
///
/// An archive's rows are keyed by the boundary of the profile that
/// exported it, [keyedByOffsetMinutes], which the bundle records. This
/// profile's own rows are keyed by the configured boundary already, so
/// only the imported ones move. A bundle that records no boundary
/// predates the record and with it #1317, so its rows are read the way
/// activation reads a profile with no record: keyed by the wall-clock
/// date, imported workouts aside.
///
/// Activity credit is tracked per row, not read off the entries: an
/// imported row credits the archive's [importedActivities] listed on it
/// at the archive's boundary, and the device's own rows credit the
/// activities that were on file before [write]. An archive's activity
/// that lands on a device row's day raises that row's goal, and a device
/// activity whose row the archive replaced gets its credit back. The
/// archive's activities count as the import stores them: one per id, the
/// last, while each with a blank id is its own.
///
/// Records the configured boundary as the one this profile's rows are
/// keyed by now. Runs under [withTrackedDayLock], so no writer changes
/// the rows between the snapshot, the write and the reconciliation.
Future<int> restoreTrackedDays(
  HiveDBProvider db,
  ConfigDataSource configDataSource, {
  required Future<void> Function() write,
  required Set<String> importedDayKeys,
  required Iterable<UserActivityDBO> importedActivities,
  required int? keyedByOffsetMinutes,
}) => withTrackedDayLock(() async {
  final offset = _offsetMinutesNow(configDataSource);
  final deviceCredit = _burnedByDay(db.userActivityBox.values, offset);
  await write();
  final keyedBy = keyedByOffsetMinutes ?? 0;
  final importKeyedBy = keyedByOffsetMinutes == null ? offset : null;
  // Keyed like the upsert: a repeated id is stored once, as its last
  // occurrence, and a blank id gets its own id from the import.
  final stored = <Object, UserActivityDBO>{
    for (final (index, activity) in importedActivities.indexed)
      isBlankId(activity.id) ? index : activity.id: activity,
  };
  final archiveCredit = _burnedByDay(
    stored.values,
    keyedBy,
    importOffsetMinutes: importKeyedBy,
  );
  final rowsWritten = reconcileTrackedDays(
    db,
    offsetMinutes: offset,
    previousOffsetMinutes: keyedBy,
    previousImportOffsetMinutes: importKeyedBy,
    previousKeys: importedDayKeys,
    creditedBurned: {
      for (final MapEntry(:key, :value) in deviceCredit.entries)
        if (!importedDayKeys.contains(key)) key: value,
      for (final key in importedDayKeys) key: archiveCredit[key] ?? 0,
    },
  );
  final recorded = configDataSource.setConfigTrackedDaysOffsetMinutes(offset);
  final changed = await rowsWritten;
  await recorded;
  return changed;
});

/// Moves the day boundary to [hours]:[minutes] and the active profile's
/// tracked-day rows with it (#1317).
///
/// The config write and the regrouping happen in one synchronous step, so
/// no code sees the new boundary with the rows still keyed by the old one,
/// and inside [withTrackedDayLock], so no writer is between storing an
/// entry and adding it to its row. Besides the totals, each row's goal
/// follows the activities that move on or off its day. Other profiles
/// keep the boundary their rows are keyed by on record, and
/// [ensureTrackedDaysMatchEntries] moves them from it when they are next
/// activated.
Future<void> moveDayBoundary(
  HiveDBProvider db,
  ConfigDataSource configDataSource,
  int hours,
  int minutes,
) => withTrackedDayLock(() {
  final before = _offsetMinutesNow(configDataSource);
  final configWritten = configDataSource.setConfigDayStartOffset(
    hours,
    minutes,
  );
  final after = _offsetMinutesNow(configDataSource);
  final rowsWritten = reconcileTrackedDays(
    db,
    offsetMinutes: after,
    previousOffsetMinutes: before,
  );
  final recorded = configDataSource.setConfigTrackedDaysOffsetMinutes(after);
  return Future.wait([configWritten, rowsWritten, recorded]);
});
