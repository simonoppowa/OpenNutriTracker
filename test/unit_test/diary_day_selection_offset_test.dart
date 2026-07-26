import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

import '../fixture/meal_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #586: a configured day-start offset must shift only the entries, never
/// the calendar day the user selected. `table_calendar` hands out
/// `DateTime.utc(y, m, d)` cells, so the day reaching these queries is a
/// label; subtracting the offset from it moved the whole selection back a
/// day and the diary listed the previous day's food.
void main() {
  // The 20th as the diary's calendar would deliver it.
  final selectedDay = DateTime.utc(2026, 7, 20);
  const sixAmOffset = 6;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init(".");
    registerHiveAdaptersOnce();
  });

  tearDown(() {
    Hive.deleteFromDisk();
  });

  group('intakes under a 06:00 day start', () {
    late IntakeDataSource dataSource;

    setUp(() async {
      final box = await Hive.openBox<IntakeDBO>('intake_offset_test');
      dataSource = IntakeDataSource(FakeHiveDBProvider(intakeBox: box));
      final repo = IntakeRepository(dataSource);

      Future<void> addLunch(String id, DateTime when) => repo.addIntake(
            IntakeEntity(
              id: id,
              unit: 'g',
              amount: 1,
              type: IntakeTypeEntity.lunch,
              meal: MealEntityFixtures.mealOne,
              dateTime: when,
            ),
          );

      await addLunch('19th-evening', DateTime(2026, 7, 19, 20, 0));
      await addLunch('20th-midday', DateTime(2026, 7, 20, 12, 0));
      await addLunch('21st-small-hours', DateTime(2026, 7, 21, 2, 0));
      // Added from the diary itself, which stamps the calendar cell.
      await addLunch('20th-diary-added', selectedDay);
    });

    Future<Set<String>> idsFor(DateTime day, {int offsetHours = 0}) async {
      final result = await dataSource.getAllIntakesByDate(
        IntakeTypeDBO.lunch,
        day,
        dayStartOffsetHours: offsetHours,
      );
      return result.map((dbo) => dbo.id).toSet();
    }

    test('selecting the 20th lists the 20th, not the 19th', () async {
      expect(
        await idsFor(selectedDay, offsetHours: sixAmOffset),
        {'20th-midday', '20th-diary-added', '21st-small-hours'},
      );
    });

    test('the small hours of the 21st still belong to the 20th', () async {
      expect(
        await idsFor(DateTime.utc(2026, 7, 21), offsetHours: sixAmOffset),
        isNot(contains('21st-small-hours')),
      );
    });

    test('the 19th keeps its own evening entry', () async {
      expect(
        await idsFor(DateTime.utc(2026, 7, 19), offsetHours: sixAmOffset),
        {'19th-evening'},
      );
    });

    test('no offset falls back to plain calendar days', () async {
      expect(
        await idsFor(selectedDay),
        {'20th-midday', '20th-diary-added'},
      );
    });
  });

  // The Home page asks for "today" rather than a selected day, so it has
  // to resolve the boundary into a label *before* filtering: passing a
  // raw `DateTime.now()` to a label-taking query asks for the wall-clock
  // date, which is a different day for exactly the hours the offset
  // exists to handle. The clock is pinned inside that window, because
  // outside it the two spellings of "today" coincide and the test would
  // pass either way.
  group('a "today" read resolves the boundary before filtering', () {
    late IntakeRepository repo;
    late GetIntakeUsecase intakeUsecase;
    late GetUserActivityUsecase activityUsecase;

    const offsetHours = 6;
    // 02:00 — after midnight, before the 06:00 boundary, so the logical
    // day is still the 19th while the wall-clock date is the 20th.
    final beforeBoundary = DateTime(2026, 7, 20, 2, 0);

    setUp(() async {
      DayBoundaryCalc.clock = () => beforeBoundary;
      addTearDown(() => DayBoundaryCalc.clock = DateTime.now);

      final intakeBox = await Hive.openBox<IntakeDBO>('intake_today_test');
      repo = IntakeRepository(
        IntakeDataSource(FakeHiveDBProvider(intakeBox: intakeBox)),
      );
      intakeUsecase = GetIntakeUsecase(repo);

      final activityBox =
          await Hive.openBox<UserActivityDBO>('activity_today_test');
      activityUsecase = GetUserActivityUsecase(
        UserActivityRepository(
          UserActivityDataSource(
            FakeHiveDBProvider(userActivityBox: activityBox),
          ),
        ),
      );
    });

    Future<void> addLunchAt(String id, DateTime when) => repo.addIntake(
          IntakeEntity(
            id: id,
            unit: 'g',
            amount: 1,
            type: IntakeTypeEntity.lunch,
            meal: MealEntityFixtures.mealOne,
            dateTime: when,
          ),
        );

    test('at 02:00 on a 06:00 boundary, "today" is still the 19th', () async {
      await addLunchAt('19th-evening', DateTime(2026, 7, 19, 20, 0));
      await addLunchAt('20th-small-hours', DateTime(2026, 7, 20, 1, 0));
      // Already past the next boundary, so it belongs to the 20th.
      await addLunchAt('20th-after-boundary', DateTime(2026, 7, 20, 9, 0));

      final today = await intakeUsecase.getTodayLunchIntake(
        dayStartOffsetHours: offsetHours,
      );
      expect(
        today.map((e) => e.id).toSet(),
        {'19th-evening', '20th-small-hours'},
      );
    });

    test('with no offset configured, "today" is the wall-clock day',
        () async {
      await addLunchAt('19th-evening', DateTime(2026, 7, 19, 20, 0));
      await addLunchAt('20th-small-hours', DateTime(2026, 7, 20, 1, 0));

      final today = await intakeUsecase.getTodayLunchIntake();
      expect(today.map((e) => e.id), ['20th-small-hours']);
    });

    test('every meal slot agrees on which day "today" is', () async {
      // A slot reading the wall-clock date while its neighbours read the
      // logical one would split a single evening across two days.
      for (final type in IntakeTypeEntity.values) {
        await repo.addIntake(
          IntakeEntity(
            id: 'small-hours-${type.name}',
            unit: 'g',
            amount: 1,
            type: type,
            meal: MealEntityFixtures.mealOne,
            dateTime: DateTime(2026, 7, 20, 1, 0),
          ),
        );
        await repo.addIntake(
          IntakeEntity(
            id: 'after-boundary-${type.name}',
            unit: 'g',
            amount: 1,
            type: type,
            meal: MealEntityFixtures.mealOne,
            dateTime: DateTime(2026, 7, 20, 9, 0),
          ),
        );
      }

      final reads = {
        IntakeTypeEntity.breakfast: intakeUsecase.getTodayBreakfastIntake,
        IntakeTypeEntity.lunch: intakeUsecase.getTodayLunchIntake,
        IntakeTypeEntity.dinner: intakeUsecase.getTodayDinnerIntake,
        IntakeTypeEntity.snack: intakeUsecase.getTodaySnackIntake,
      };
      for (final entry in reads.entries) {
        final result = await entry.value(dayStartOffsetHours: offsetHours);
        expect(
          result.map((e) => e.id),
          ['small-hours-${entry.key.name}'],
          reason: '${entry.key.name} disagreed about "today"',
        );
      }
    });

    test('activities resolve "today" the same way', () async {
      final walking = PhysicalActivityDBO(
        '02020',
        'Walking',
        'Walking, leisure',
        3.5,
        const [],
        PhysicalActivityTypeDBO.sport,
      );
      await Hive.box<UserActivityDBO>('activity_today_test').addAll([
        UserActivityDBO(
            'small-hours', 30, 100, DateTime(2026, 7, 20, 1, 0), walking),
        UserActivityDBO(
            'after-boundary', 30, 100, DateTime(2026, 7, 20, 9, 0), walking),
      ]);

      final today = await activityUsecase.getTodayUserActivity(
        dayStartOffsetHours: offsetHours,
      );
      expect(today.map((e) => e.id), ['small-hours']);
    });
  });

  test('activities follow the same rule', () async {
    final box = await Hive.openBox<UserActivityDBO>('activity_offset_test');
    final dataSource =
        UserActivityDataSource(FakeHiveDBProvider(userActivityBox: box));

    final walking = PhysicalActivityDBO(
      '02020',
      'Walking',
      'Walking, leisure',
      3.5,
      const [],
      PhysicalActivityTypeDBO.sport,
    );
    await box.addAll([
      UserActivityDBO('19th-evening', 30, 100,
          DateTime(2026, 7, 19, 20, 0), walking),
      UserActivityDBO('20th-midday', 30, 100,
          DateTime(2026, 7, 20, 12, 0), walking),
    ]);

    final result = await dataSource.getAllUserActivitiesByDate(
      selectedDay,
      dayStartOffsetHours: sixAmOffset,
    );
    expect(result.map((dbo) => dbo.id), ['20th-midday']);
  });
}
