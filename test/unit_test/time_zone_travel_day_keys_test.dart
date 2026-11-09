import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/logged_time.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1309: after a flight from UTC−3 to UTC+2 a day's total no longer
/// matched its listed entries, and activities from two days showed on one.
///
/// How these tests travel: `TZ` cannot change inside one Dart process, so
/// an entry is built the way Hive hands it back on a phone that has since
/// changed zone — the instant it was logged at, as a local `DateTime` of
/// the zone the test runs in — together with the UTC offset of the zone
/// it was logged in. [_loggedAt] builds that instant from the logging
/// zone's wall clock. The zone the test runs in is never the logging zone
/// (UTC on CI, Europe/Berlin on `just test_dst`), so every entry below is
/// read in another zone than it was logged in, which is the bug's setup.
///
/// Before the fix every day key was taken from the local fields of that
/// instant: an entry logged at 22:30 in UTC−3 is 01:30 UTC the next day,
/// so it was listed on the next day while its calories stayed on the row
/// of the day it was logged on.
const _brazil = -180;
const _berlinSummer = 120;
const _berlinWinter = 60;
const _kiribati = 840;

/// The instant the wall clock [y]-[mo]-[d] [h]:[mi] in a zone at
/// [offsetMinutes] names, as Hive reads it back: local to the test's zone.
DateTime _loggedAt(
  int offsetMinutes,
  int y,
  int mo,
  int d, [
  int h = 0,
  int mi = 0,
  int s = 0,
  int ms = 0,
]) => DateTime.utc(
  y,
  mo,
  d,
  h,
  mi,
  s,
  ms,
).subtract(Duration(minutes: offsetMinutes)).toLocal();

String _key(DateTime stored, int? loggedOffset, [int boundaryMinutes = 0]) =>
    DayBoundaryCalc.dayKeyOf(
      LoggedTime.wallClock(stored, loggedOffset),
      boundaryMinutes,
    );

/// 200 kcal per 100 g.
final _toast = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 100,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: 200,
    carbohydrates100: 40,
    fat100: 2,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

final _running = PhysicalActivityDBO(
  '12150',
  'running',
  'running, general',
  8.0,
  const <String>[],
  PhysicalActivityTypeDBO.running,
);

IntakeDBO _intake(
  String id,
  double grams,
  DateTime at, {
  int? loggedOffset = _brazil,
  IntakeTypeDBO type = IntakeTypeDBO.dinner,
}) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: grams,
  type: type,
  meal: MealDBO.fromMealEntity(_toast),
  dateTime: at,
  loggedUtcOffsetMinutes: loggedOffset,
);

UserActivityDBO _activity(
  String id,
  double kcal,
  DateTime at, {
  int? loggedOffset = _brazil,
}) => UserActivityDBO(
  id,
  30,
  kcal,
  at,
  _running,
  loggedUtcOffsetMinutes: loggedOffset,
);

double _kcal(IntakeDBO dbo) => IntakeEntity.fromIntakeDBO(dbo).totalKcal;

void main() {
  group('LoggedTime keys an entry by the clock it was logged on', () {
    test('eastward: 22:30 in UTC−3 stays on its day in UTC+2', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      // The instant is already the next day in UTC and further east.
      expect(at.toUtc().day, 9);
      expect(_key(at, _brazil), '2026-04-08');
    });

    test('westward: 00:30 in UTC+2 stays on its day in UTC−3', () {
      final at = _loggedAt(_berlinSummer, 2026, 4, 9, 0, 30);
      expect(at.toUtc().day, 8);
      expect(_key(at, _berlinSummer), '2026-04-09');
      // From the far east, so the instant is the day before in every
      // zone a test can run in.
      final farEast = _loggedAt(_kiribati, 2026, 4, 9, 10);
      expect(_key(farEast, _kiribati), '2026-04-09');
    });

    test('entries a moment either side of midnight keep their side', () {
      expect(
        _key(_loggedAt(_brazil, 2026, 4, 8, 23, 59, 59, 999), _brazil),
        '2026-04-08',
      );
      expect(
        _key(_loggedAt(_berlinSummer, 2026, 4, 9, 0, 0, 0, 1), _berlinSummer),
        '2026-04-09',
      );
    });

    test('a moved day boundary applies to the logged clock', () {
      const fourAm = 4 * 60;
      expect(
        _key(_loggedAt(_brazil, 2026, 4, 9, 2, 30), _brazil, fourAm),
        '2026-04-08',
      );
      expect(
        _key(_loggedAt(_brazil, 2026, 4, 9, 4, 30), _brazil, fourAm),
        '2026-04-09',
      );
    });

    test('a UTC day label is never shifted', () {
      final label = DateTime.utc(2026, 4, 8);
      expect(LoggedTime.wallClock(label, _brazil), same(label));
      expect(LoggedTime.localWallClock(label, _brazil), same(label));
      expect(_key(label, _brazil, 4 * 60), '2026-04-08');
      expect(LoggedTime.offsetOf(label), isNull);
    });

    test('a local-midnight import label stays a label after travel', () {
      // JsonMealImporter dates an entry at local midnight.
      final label = _loggedAt(_berlinSummer, 2026, 4, 8);
      expect(_key(label, _berlinSummer, 4 * 60), '2026-04-08');
    });

    test('an entry with no recorded offset reads as it always did', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      expect(LoggedTime.wallClock(at, null), same(at));
      expect(LoggedTime.localWallClock(at, null), same(at));
    });

    test('the offset recorded is the zone\'s at that instant', () {
      final now = DateTime(2026, 4, 8, 12);
      expect(LoggedTime.offsetOf(now), now.timeZoneOffset.inMinutes);
      final winter = DateTime(2026, 1, 8, 12);
      expect(LoggedTime.offsetOf(winter), winter.timeZoneOffset.inMinutes);
    });

    test('the local wall clock is the logged date and time of day', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30, 15, 250);
      final local = LoggedTime.localWallClock(at, _brazil);
      expect(local.isUtc, isFalse);
      expect(
        [local.year, local.month, local.day, local.hour, local.minute],
        [2026, 4, 8, 22, 30],
      );
      expect([local.second, local.millisecond], [15, 250]);
      // Read in its own zone it is returned as stored.
      final home = DateTime(2026, 4, 8, 22, 30);
      expect(
        LoggedTime.localWallClock(home, home.timeZoneOffset.inMinutes),
        same(home),
      );
    });
  });

  group('daylight saving combined with travel', () {
    test('00:30 CEST is still that day once read in winter or abroad', () {
      final at = _loggedAt(_berlinSummer, 2026, 7, 5, 0, 30);
      expect(_key(at, _berlinSummer), '2026-07-05');
      final local = LoggedTime.localWallClock(at, _berlinSummer);
      expect([local.month, local.day, local.hour], [7, 5, 0]);
    });

    test('a 04:00 boundary on the night clocks go back (Berlin)', () {
      // 25 Oct 2026, 03:30 CET is after the fall-back at 03:00 CEST.
      // Subtracting four hours from the local time crossed the change and
      // landed on 00:30 CEST the 25th; on the logged clock it is 23:30 on
      // the 24th, before the boundary.
      const fourAm = 4 * 60;
      expect(
        _key(
          _loggedAt(_berlinWinter, 2026, 10, 25, 3, 30),
          _berlinWinter,
          fourAm,
        ),
        '2026-10-24',
      );
      expect(
        _key(
          _loggedAt(_berlinWinter, 2026, 10, 25, 4, 30),
          _berlinWinter,
          fourAm,
        ),
        '2026-10-25',
      );
    });

    test('logged in UTC−3 the evening Berlin falls back, read later', () {
      final at = _loggedAt(_brazil, 2026, 10, 24, 23, 30);
      expect(_key(at, _brazil), '2026-10-24');
      final local = LoggedTime.localWallClock(at, _brazil);
      expect(
        [local.month, local.day, local.hour, local.minute],
        [10, 24, 23, 30],
      );
    });

    test('a wall clock the reading zone skipped keeps its date '
        '(Berlin spring-forward)', () {
      // A spring-forward night in the reading zone must not move a date:
      // 02:30 on 29 Mar 2026 does not exist in Berlin.
      final at = _loggedAt(_berlinSummer + 60, 2026, 3, 29, 2, 30);
      expect(_key(at, _berlinSummer + 60), '2026-03-29');
      expect(LoggedTime.localWallClock(at, _berlinSummer + 60).day, 29);
    });
  });

  group('the Diary after a flight from UTC−3', () {
    late Box<ConfigDBO> configBox;
    late Box<IntakeDBO> intakeBox;
    late Box<TrackedDayDBO> trackedDayBox;
    late Box<UserActivityDBO> activityBox;
    late FakeHiveDBProvider db;
    late IntakeDataSource intakes;
    late UserActivityDataSource activities;
    late TrackedDayDataSource rows;

    setUpAll(() {
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      configBox = await Hive.openBox<ConfigDBO>('tz1309_config_$tag');
      intakeBox = await Hive.openBox<IntakeDBO>('tz1309_intake_$tag');
      trackedDayBox = await Hive.openBox<TrackedDayDBO>('tz1309_day_$tag');
      activityBox = await Hive.openBox<UserActivityDBO>('tz1309_act_$tag');
      db = FakeHiveDBProvider(
        configBox: configBox,
        intakeBox: intakeBox,
        trackedDayBox: trackedDayBox,
        userActivityBox: activityBox,
      );
      await ConfigDataSource(db).initializeConfig();
      intakes = IntakeDataSource(db);
      activities = UserActivityDataSource(db);
      rows = TrackedDayDataSource(db);
    });

    tearDown(() async {
      await configBox.deleteFromDisk();
      await intakeBox.deleteFromDisk();
      await trackedDayBox.deleteFromDisk();
      await activityBox.deleteFromDisk();
    });

    /// Stores [entries] and [burned] with the rows their writers kept in
    /// UTC−3: each row keyed by its logged day, counting what was logged
    /// on it, its goal raised by what was burned on it.
    Future<void> seed(
      Map<String, List<IntakeDBO>> entries,
      Map<String, List<UserActivityDBO>> burned,
    ) async {
      for (final list in entries.values) {
        await intakeBox.addAll(list);
      }
      for (final list in burned.values) {
        await activityBox.addAll(list);
      }
      for (final key in {...entries.keys, ...burned.keys}) {
        final date = DateTime.parse(key);
        final burnedKcal = (burned[key] ?? const []).fold<double>(
          0,
          (sum, a) => sum + a.burnedKcal,
        );
        final logged = (entries[key] ?? const <IntakeDBO>[]).map(
          IntakeEntity.fromIntakeDBO,
        );
        double sum(double Function(IntakeEntity) of) =>
            logged.fold<double>(0, (total, i) => total + of(i));
        await trackedDayBox.put(
          key,
          TrackedDayDBO(
            // A local midnight in UTC−3, as HomeBloc's logical day was.
            day: _loggedAt(_brazil, date.year, date.month, date.day),
            calorieGoal: 2000 + burnedKcal,
            caloriesTracked: sum((i) => i.totalKcal),
            carbsTracked: sum((i) => i.totalCarbsGram),
            fatTracked: sum((i) => i.totalFatsGram),
            proteinTracked: sum((i) => i.totalProteinsGram),
          ),
        );
      }
    }

    Future<List<IntakeDBO>> listed(DateTime label, {int hours = 0}) async => [
      for (final type in IntakeTypeDBO.values)
        ...await intakes.getAllIntakesByDate(
          type,
          label,
          dayStartOffsetHours: hours,
        ),
    ];

    test(
      'each day lists its own entries, and its total is their sum',
      () async {
        await seed(
          {
            '2026-04-08': [
              _intake(
                'a-breakfast',
                150,
                _loggedAt(_brazil, 2026, 4, 8, 8),
                type: IntakeTypeDBO.breakfast,
              ),
              _intake('a-late', 250, _loggedAt(_brazil, 2026, 4, 8, 22, 30)),
            ],
            '2026-04-09': [
              _intake(
                'b-lunch',
                200,
                _loggedAt(_brazil, 2026, 4, 9, 12),
                type: IntakeTypeDBO.lunch,
              ),
              _intake('b-late', 100, _loggedAt(_brazil, 2026, 4, 9, 23, 45)),
            ],
          },
          {
            '2026-04-08': [
              _activity('run-8', 200, _loggedAt(_brazil, 2026, 4, 8, 21)),
            ],
            '2026-04-09': [
              _activity('run-9', 150, _loggedAt(_brazil, 2026, 4, 9, 20, 30)),
            ],
          },
        );

        // App activation reconciles the rows with the listing; nothing has
        // to move, because both read the logged clock.
        expect(await reconcileTrackedDays(db, offsetMinutes: 0), 0);

        for (final (label, ids, runs) in [
          (DateTime.utc(2026, 4, 8), {'a-breakfast', 'a-late'}, {'run-8'}),
          (DateTime.utc(2026, 4, 9), {'b-lunch', 'b-late'}, {'run-9'}),
        ]) {
          final day = await listed(label);
          expect(day.map((i) => i.id).toSet(), ids, reason: '$label');
          final row = await rows.getTrackedDay(label);
          expect(
            row!.caloriesTracked,
            closeTo(day.fold<double>(0, (s, i) => s + _kcal(i)), 1e-9),
            reason: 'total of $label',
          );
          final burned = await activities.getAllUserActivitiesByDate(label);
          expect(burned.map((a) => a.id).toSet(), runs, reason: '$label');
        }

        // The Diary's calendar marks the same two days.
        final getIntake = GetIntakeUsecase(
          IntakeRepository(intakes),
          RecipeRepository(RecipeDataSource(db)),
        );
        expect(await getIntake.getDayKeysWithIntakes(0), {
          '2026-04-08',
          '2026-04-09',
        });
      },
    );

    test(
      'the summary row of a day written further east keeps its date',
      () async {
        // A row written in UTC+14 for the 8th: its local midnight is the
        // 7th in every zone west of UTC+10, UTC and Berlin among them.
        await trackedDayBox.put(
          '2026-04-08',
          TrackedDayDBO(
            day: _loggedAt(_kiribati, 2026, 4, 8),
            calorieGoal: 2000,
            caloriesTracked: 300,
          ),
        );
        final dbo = trackedDayBox.get('2026-04-08')!;
        if (DateTime(2026, 4, 8).timeZoneOffset.inHours < 10) {
          expect(dbo.day.day, 7);
        }
        final entity = TrackedDayEntity.fromTrackedDayDBO(dbo);
        expect(
          [entity.day.year, entity.day.month, entity.day.day],
          [2026, 4, 8],
        );
        final inRange = await rows.getTrackedDaysInRange(
          DateTime(2026, 4, 8),
          DateTime(2026, 4, 8, 23, 59, 59),
        );
        expect(inRange, hasLength(1));
        expect(dbo.toJson()['day'], startsWith('2026-04-08'));
        expect(
          CsvDataExporter.trackedDaysToCsv([dbo]),
          contains('2026-04-08T00:00:00.000'),
        );
      },
    );

    test('a row whose day already names its key is left as stored', () async {
      final day = DateTime.utc(2026, 4, 8);
      await trackedDayBox.put(
        '2026-04-08',
        TrackedDayDBO(day: day, calorieGoal: 2000, caloriesTracked: 0),
      );
      final dbo = trackedDayBox.get('2026-04-08')!;
      expect(dbo.calendarDay, same(dbo.day));
      expect(dbo.toJson()['day'], '2026-04-08T00:00:00.000Z');
    });

    test('deleting a travelled entry takes it off its own day', () async {
      final lateSnack = _intake(
        'a-late',
        250,
        _loggedAt(_brazil, 2026, 4, 8, 22, 30),
      );
      await seed({
        '2026-04-08': [lateSnack],
        '2026-04-09': [
          _intake('b-lunch', 200, _loggedAt(_brazil, 2026, 4, 9, 12)),
        ],
      }, const {});
      // What HomeBloc and CalendarDayBloc do on delete.
      final entity = IntakeEntity.fromIntakeDBO(lateSnack);
      await intakes.deleteIntakeFromId(entity.id);
      await rows.decreaseDayCaloriesTracked(entity.dateTime, entity.totalKcal);

      expect(trackedDayBox.get('2026-04-08')!.caloriesTracked, 0);
      expect(trackedDayBox.get('2026-04-09')!.caloriesTracked, 400);
    });

    test(
      'a moved boundary files an early entry on the logged evening',
      () async {
        await ConfigDataSource(db).setConfigDayStartOffsetHours(4);
        await seed({
          '2026-04-08': [
            _intake('a-early', 250, _loggedAt(_brazil, 2026, 4, 9, 2, 30)),
          ],
          '2026-04-09': [
            _intake('b-after', 100, _loggedAt(_brazil, 2026, 4, 9, 4, 30)),
          ],
        }, const {});

        expect(await reconcileTrackedDays(db, offsetMinutes: 4 * 60), 0);
        expect(
          (await listed(DateTime.utc(2026, 4, 8), hours: 4)).map((i) => i.id),
          ['a-early'],
        );
        expect(
          (await listed(DateTime.utc(2026, 4, 9), hours: 4)).map((i) => i.id),
          ['b-after'],
        );
      },
    );

    test('an entry stored before the offset was recorded still reads in '
        'the current zone', () async {
      // Unchanged on purpose: the zone it was logged in is not known.
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      await intakeBox.add(_intake('legacy', 100, at, loggedOffset: null));
      final label = DateTime.utc(at.year, at.month, at.day);
      expect((await listed(label)).map((i) => i.id), ['legacy']);
    });

    test('the recorded offset survives the box being reopened', () async {
      final name = intakeBox.name;
      await intakeBox.put(
        'k',
        _intake('a', 100, _loggedAt(_brazil, 2026, 4, 8, 22, 30)),
      );
      await activityBox.put(
        'k',
        _activity('r', 100, _loggedAt(_brazil, 2026, 4, 8, 21)),
      );
      final activityName = activityBox.name;
      await intakeBox.close();
      await activityBox.close();
      intakeBox = await Hive.openBox<IntakeDBO>(name);
      activityBox = await Hive.openBox<UserActivityDBO>(activityName);
      expect(intakeBox.get('k')!.loggedUtcOffsetMinutes, _brazil);
      expect(activityBox.get('k')!.loggedUtcOffsetMinutes, _brazil);
    });

    test('edits and upserts keep the recorded offset', () async {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      await activityBox.add(_activity('r', 100, at));
      final edited = await activities.updateUserActivity('r', 45, 150);
      expect(edited!.loggedUtcOffsetMinutes, _brazil);

      // A blank id is given one from its content, through a copy.
      db = FakeHiveDBProvider(
        configBox: configBox,
        intakeBox: intakeBox,
        trackedDayBox: trackedDayBox,
        userActivityBox: activityBox,
      );
      await IntakeDataSource(db).upsertAllIntakes([_intake('', 100, at)]);
      expect(intakeBox.values.single.loggedUtcOffsetMinutes, _brazil);
      await activities.upsertAllUserActivities([_activity('', 100, at)]);
      expect(
        activityBox.values
            .where((a) => a.id != 'r')
            .single
            .loggedUtcOffsetMinutes,
        _brazil,
      );
    });
  });

  group('saving again, and backups', () {
    test('an entity saved again keeps the clock it was logged on', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      final again = IntakeDBO.fromIntakeEntity(
        IntakeEntity.fromIntakeDBO(_intake('a', 100, at)),
      );
      expect(_key(again.dateTime, again.loggedUtcOffsetMinutes), '2026-04-08');
      final clock = again.loggedWallClock;
      expect([clock.day, clock.hour, clock.minute], [8, 22, 30]);

      final run = UserActivityDBO.fromUserActivityEntity(
        UserActivityEntity.fromUserActivityDBO(_activity('r', 100, at)),
      );
      expect(_key(run.date, run.loggedUtcOffsetMinutes), '2026-04-08');
    });

    test('a new entry records the zone it is logged in', () {
      final now = DateTime(2026, 4, 8, 22, 30);
      final dbo = IntakeDBO.fromIntakeEntity(
        IntakeEntity.fromIntakeDBO(_intake('a', 100, now, loggedOffset: null)),
      );
      expect(dbo.loggedUtcOffsetMinutes, now.timeZoneOffset.inMinutes);
      final label = IntakeDBO.fromIntakeEntity(
        IntakeEntity.fromIntakeDBO(
          _intake('b', 100, DateTime.utc(2026, 4, 8), loggedOffset: null),
        ),
      );
      expect(label.loggedUtcOffsetMinutes, isNull);
    });

    test('a JSON export writes the logged clock, and restores to its day', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      final json = _intake('a', 100, at).toJson();
      expect(json['dateTime'], '2026-04-08T22:30:00.000');
      expect(json.containsKey('loggedUtcOffsetMinutes'), isFalse);
      final restored = IntakeDBO.fromJson(jsonDecode(jsonEncode(json)));
      expect(restored.loggedUtcOffsetMinutes, isNull);
      expect(_key(restored.dateTime, null), '2026-04-08');

      final run = _activity('r', 100, at).toJson();
      expect(run['date'], '2026-04-08T22:30:00.000');
      expect(
        _key(UserActivityDBO.fromJson(jsonDecode(jsonEncode(run))).date, null),
        '2026-04-08',
      );
    });

    test('JSON of a day label or an unpinned entry is unchanged', () {
      final label = DateTime.utc(2026, 4, 8);
      expect(
        _intake('a', 100, label).toJson()['dateTime'],
        label.toIso8601String(),
      );
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      expect(
        _intake('b', 100, at, loggedOffset: null).toJson()['dateTime'],
        at.toIso8601String(),
      );
    });

    test('a CSV export writes the logged clock', () {
      final at = _loggedAt(_brazil, 2026, 4, 8, 22, 30);
      expect(
        CsvDataExporter.intakesToCsv([_intake('a', 100, at)]),
        contains('2026-04-08T22:30:00.000'),
      );
      expect(
        CsvDataExporter.userActivitiesToCsv([_activity('r', 100, at)]),
        contains('2026-04-08T22:30:00.000'),
      );
    });
  });
}
