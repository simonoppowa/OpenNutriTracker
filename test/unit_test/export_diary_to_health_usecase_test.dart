import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/health_export_records.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/water_intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/export_diary_to_health_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _Replaced {
  final DateTime from;
  final DateTime to;
  final List<ExportedMeal> meals;
  final List<ExportedWater> water;

  _Replaced(this.from, this.to, this.meals, this.water);
}

class _FakeHealthService extends Fake implements HealthService {
  final replaced = <_Replaced>[];
  bool refuse = false;

  /// Refuses only the day whose window starts here.
  DateTime? refuseFrom;

  /// The meals the store holds, kept as the real service does: the window
  /// is cleared first and the meals are written after it.
  final held = <ExportedMeal>[];

  /// Runs between the clear and the writes, so a test can act mid-run.
  Future<void> Function()? onReplace;

  @override
  Future<void> replaceExportedDay({
    required DateTime from,
    required DateTime to,
    required List<ExportedMeal> meals,
    required List<ExportedWater> water,
  }) async {
    if (refuse || from == refuseFrom) throw StateError('refused');
    replaced.add(_Replaced(from, to, meals, water));
    held.removeWhere(
      (meal) => !meal.time.isBefore(from) && meal.time.isBefore(to),
    );
    await onReplace?.call();
    held.addAll(meals);
  }

  List<DateTime> get heldTimes => [for (final meal in held) meal.time]..sort();
}

final _oats = MealEntity(
  code: 'oats',
  name: 'Oats',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 380,
    carbohydrates100: 60,
    fat100: 7,
    proteins100: 13,
    sugars100: 1,
    saturatedFat100: 1.2,
    fiber100: 10,
    sodium100: 6,
  ),
  source: MealSourceEntity.custom,
);

IntakeEntity _intake({
  required String id,
  required DateTime at,
  IntakeTypeEntity type = IntakeTypeEntity.breakfast,
  double amount = 50,
}) => IntakeEntity(
  id: id,
  unit: 'g',
  amount: amount,
  type: type,
  meal: _oats,
  dateTime: at,
);

void main() {
  final now = DateTime(2026, 5, 23, 12, 0);
  final today = DateTime(2026, 5, 23);
  final yesterday = DateTime(2026, 5, 22);
  final yesterdayMorning = yesterday.add(const Duration(hours: 9));

  late Box<ConfigDBO> configBox;
  late Box<IntakeDBO> intakeBox;
  late Box<WaterIntakeDBO> waterBox;
  late ConfigDataSource configDataSource;
  late IntakeRepository intakeRepository;
  late WaterIntakeRepository waterRepository;
  late _FakeHealthService healthService;
  late FakeHiveDBProvider provider;
  late ExportDiaryToHealthUsecase usecase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    configBox = await Hive.openBox<ConfigDBO>('health_export_config_test');
    intakeBox = await Hive.openBox<IntakeDBO>('health_export_intake_test');
    waterBox = await Hive.openBox<WaterIntakeDBO>('health_export_water_test');
    await configBox.clear();
    await intakeBox.clear();
    await waterBox.clear();

    provider = FakeHiveDBProvider(
      configBox: configBox,
      intakeBox: intakeBox,
      waterIntakeBox: waterBox,
    );
    configDataSource = ConfigDataSource(provider);
    await configDataSource.initializeConfig();
    intakeRepository = IntakeRepository(IntakeDataSource(provider));
    waterRepository = WaterIntakeRepository(WaterIntakeDataSource(provider));
    healthService = _FakeHealthService();
    usecase = ExportDiaryToHealthUsecase(
      HealthExportRepository(healthService),
      ConfigRepository(configDataSource),
      intakeRepository,
      waterRepository,
      provider,
    );

    ExportDiaryToHealthUsecase.clock = () => now;
    await configDataSource.setConfigHealthExportEnabled(true);
  });

  tearDown(() async {
    ExportDiaryToHealthUsecase.clock = DateTime.now;
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('nothing is written until the user opts in', () async {
    await configDataSource.setConfigHealthExportEnabled(false);
    await intakeRepository.addIntake(_intake(id: 'a', at: now));

    expect(await usecase.exportNow(), 0);
    expect(healthService.replaced, isEmpty);
  });

  test(
    'the first run writes each recent day with what the diary holds',
    () async {
      await intakeRepository.addIntake(_intake(id: 'a', at: now));
      await intakeRepository.addIntake(
        _intake(id: 'b', at: now, type: IntakeTypeEntity.lunch, amount: 100),
      );
      await waterRepository.addEntry(
        WaterIntakeEntity(id: 'w', dateTime: now, amountMl: 250),
      );
      await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));

      expect(await usecase.exportNow(), 2);

      final days = healthService.replaced;
      expect(days.map((day) => day.from).toList(), [yesterday, today]);
      expect(days.map((day) => day.to).toList(), [
        today,
        DateTime(2026, 5, 24),
      ]);
      final lunch = days[1].meals.singleWhere(
        (meal) => meal.slot == ExportedMealSlot.lunch,
      );
      expect(lunch.time, now);
      expect(lunch.name, 'Oats');
      expect(lunch.energyKcal, closeTo(380, 0.001));
      expect(lunch.fiberGram, closeTo(10, 0.001));
      expect(lunch.sodiumGram, closeTo(0.006, 0.000001));
      expect(days[1].water.single.millilitres, 250);
      expect(days[0].water, isEmpty);

      final config = await configDataSource.getConfig();
      expect(config.healthExportedDays!.keys, ['2026-05-22', '2026-05-23']);
      expect(config.healthLastExportAt, now);
    },
  );

  test('an unchanged diary costs no platform call', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await usecase.exportNow();

    expect(await usecase.exportNow(), 0);
    expect(healthService.replaced, hasLength(1));
  });

  test('an edit rewrites only its day', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
    await usecase.exportNow();
    await intakeRepository.updateIntake('c', {'amount': 80.0});

    expect(await usecase.exportNow(), 1);
    final rewrite = healthService.replaced.last;
    expect(rewrite.from, yesterday);
    expect(rewrite.meals.single.energyKcal, closeTo(304, 0.001));
  });

  test("deleting a day's last entry clears it once", () async {
    final intake = _intake(id: 'c', at: yesterdayMorning);
    await intakeRepository.addIntake(intake);
    await usecase.exportNow();
    await intakeRepository.deleteIntake(intake);

    expect(await usecase.exportNow(), 1);
    final cleared = healthService.replaced.last;
    expect(cleared.from, yesterday);
    expect(cleared.meals, isEmpty);
    // Remembered as cleared, so the next run leaves it alone.
    expect(await usecase.exportNow(), 0);
    expect(healthService.replaced, hasLength(2));
  });

  test(
    "a date-only entry is placed at its meal's hour inside the day",
    () async {
      // The diary calendar stamps the cell itself, as a UTC midnight.
      await intakeRepository.addIntake(
        _intake(
          id: 'a',
          at: DateTime.utc(2026, 5, 22),
          type: IntakeTypeEntity.dinner,
        ),
      );
      await usecase.exportNow();

      final meal = healthService.replaced.single.meals.single;
      expect(meal.time, DateTime(2026, 5, 22, 19));
    },
  );

  test(
    'a day boundary moves the window and the day an entry files under',
    () async {
      await configDataSource.setConfigDayStartOffset(4, 0);
      // 01:00 today is still yesterday under a 04:00 boundary.
      await intakeRepository.addIntake(
        _intake(id: 'a', at: DateTime(2026, 5, 23, 1)),
      );
      await usecase.exportNow();

      final day = healthService.replaced.single;
      expect(day.from, DateTime(2026, 5, 22, 4));
      expect(day.to, DateTime(2026, 5, 23, 4));
      expect(day.meals.single.time, DateTime(2026, 5, 23, 1));
    },
  );

  test('days older than the backfill are left alone', () async {
    await intakeRepository.addIntake(
      _intake(id: 'old', at: now.subtract(const Duration(days: 40))),
    );

    expect(await usecase.exportNow(), 0);
    expect(healthService.replaced, isEmpty);
  });

  test('an entry still in the future waits for its time', () async {
    final later = now.add(const Duration(hours: 1));
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await intakeRepository.addIntake(_intake(id: 'b', at: later));
    await waterRepository.addEntry(
      WaterIntakeEntity(id: 'w', dateTime: later, amountMl: 250),
    );
    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced.single.meals.map((m) => m.time), [now]);
    expect(healthService.replaced.single.water, isEmpty);

    // The first run after it is due brings the day back with it.
    ExportDiaryToHealthUsecase.clock = () => later;
    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced.last.meals.map((m) => m.time), [now, later]);
    expect(healthService.replaced.last.water.single.millilitres, 250);
  });

  test('a day another profile wrote is rewritten for this one', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await usecase.exportNow();
    // Same diary box and opt-in, as the fake shares them; only the owner
    // differs, and that is enough to replace the day.
    provider.activeProfileId = 'profile-b';

    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced, hasLength(2));
  });

  test('a boundary change clears the old windows before rewriting', () async {
    await intakeRepository.addIntake(
      _intake(id: 'a', at: DateTime.utc(2026, 5, 22)),
    );
    await usecase.exportNow();
    await configDataSource.setConfigDayStartOffset(9, 0);

    expect(await usecase.exportNow(), 1);
    final cleared = healthService.replaced[1];
    expect(cleared.from, DateTime(2026, 5, 22));
    expect(cleared.to, DateTime(2026, 5, 23));
    expect(cleared.meals, isEmpty);
    final rewritten = healthService.replaced[2];
    expect(rewritten.from, DateTime(2026, 5, 22, 9));
    expect(rewritten.meals.single.time, DateTime(2026, 5, 22, 9));
  });

  test(
    'a boundary change rewrites a day a failed pass had already moved',
    () async {
      final early = DateTime(2026, 5, 23, 1);
      await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
      await intakeRepository.addIntake(_intake(id: 'early', at: early));
      await intakeRepository.addIntake(_intake(id: 'a', at: now));
      await usecase.exportNow();

      // 01:00 moves to yesterday; yesterday is rewritten, today is refused.
      await configDataSource.setConfigDayStartOffset(4, 0);
      healthService.refuseFrom = DateTime(2026, 5, 23, 4);
      await expectLater(usecase.exportNow(), throwsStateError);

      // The retry clears today's old window again, taking 01:00 from the
      // yesterday already written, so yesterday has to be written again.
      healthService.refuseFrom = null;
      await usecase.exportNow();
      expect(healthService.heldTimes, [yesterdayMorning, early, now]);
    },
  );

  test(
    'a boundary change writes an entry it moves to a day past the backfill',
    () async {
      final aged = DateTime(2026, 4, 1, 1);
      await intakeRepository.addIntake(_intake(id: 'aged', at: aged));
      ExportDiaryToHealthUsecase.clock = () => DateTime(2026, 4, 2, 12);
      await usecase.exportNow();

      // Weeks later 01:00 on 1 April files under 31 March, a day the
      // backfill no longer reaches.
      ExportDiaryToHealthUsecase.clock = () => now;
      await configDataSource.setConfigDayStartOffset(4, 0);
      await usecase.exportNow();

      expect(healthService.heldTimes, [aged]);
      // Both days are on record, so the next run writes nothing.
      expect(await usecase.exportNow(), 0);
    },
  );

  test('a profile switch mid-write waits for the day to settle', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    late Future<int> incoming;
    healthService.onReplace = () async {
      healthService.onReplace = null;
      provider.activeProfileId = 'profile-b';
      incoming = usecase.exportNow();
      // Room for an overlapping pass to clear and write the same day.
      await pumpEventQueue();
    };

    await usecase.exportNow();
    expect(await incoming, 1);
    expect(healthService.held, hasLength(1));
  });

  test('an edit during a pass gets a fresh pass of its own', () async {
    await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    late Future<int> second;
    healthService.onReplace = () async {
      healthService.onReplace = null;
      // While yesterday is written, today changes and the app is paused.
      await intakeRepository.updateIntake('a', {'amount': 80.0});
      second = usecase.exportNow();
    };

    expect(await usecase.exportNow(), 2);
    expect(await second, 1);
    final rewrite = healthService.replaced.last;
    expect(rewrite.from, today);
    expect(rewrite.meals.single.energyKcal, closeTo(304, 0.001));
  });

  test('switching the export off mid-run stops the remaining days', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
    healthService.onReplace = () =>
        configDataSource.setConfigHealthExportEnabled(false);

    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced, hasLength(1));
    expect(healthService.replaced.single.from, yesterday);

    // The day already written is on record, so switching back on writes
    // only the one the pass never reached.
    healthService.onReplace = null;
    await configDataSource.setConfigHealthExportEnabled(true);
    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced.last.from, today);
  });

  test('a refused day is retried on the next run', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    healthService.refuse = true;

    await expectLater(usecase.exportNow(), throwsStateError);

    healthService.refuse = false;
    expect(await usecase.exportNow(), 1);
  });

  test('a refused day does not hold back the days after it', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
    // Days are written oldest first, so yesterday is refused before today
    // is reached.
    healthService.refuseFrom = yesterday;

    await expectLater(usecase.exportNow(), throwsStateError);
    expect([for (final r in healthService.replaced) r.from], [today]);
    // The pass did not finish cleanly, so it is not reported as the last
    // export.
    expect((await configDataSource.getConfig()).healthLastExportAt, isNull);

    healthService.refuseFrom = null;
    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced.last.from, yesterday);
  });

  test(
    'a rewrite that fails partway is redone after the edit is undone',
    () async {
      await intakeRepository.addIntake(_intake(id: 'a', at: now));
      await usecase.exportNow();
      await intakeRepository.updateIntake('a', {'amount': 80.0});
      // The store clears the day, then refuses the write.
      healthService.onReplace = () async {
        healthService.onReplace = null;
        throw StateError('refused');
      };
      await expectLater(usecase.exportNow(), throwsStateError);
      expect(healthService.held, isEmpty);

      // Back to what was last written in full: the day still has to be
      // written again, as the store no longer holds it.
      await intakeRepository.updateIntake('a', {'amount': 50.0});
      expect(await usecase.exportNow(), 1);
      expect(healthService.held, hasLength(1));
    },
  );

  test('a write that lands as the profile switches back is recorded', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    await usecase.exportNow();
    // Profile B takes the day; the user is back on A before B's pass ends.
    provider.activeProfileId = 'profile-b';
    healthService.onReplace = () async {
      healthService.onReplace = null;
      provider.activeProfileId = 'test-profile';
    };
    await usecase.exportNow();

    // The store holds B's write, so A has to take the day back.
    expect(await usecase.exportNow(), 1);
    expect(healthService.replaced, hasLength(3));
  });

  test('a day another profile cleared past the backfill is restored', () async {
    final aged = DateTime(2026, 4, 1, 9);
    final entry = _intake(id: 'aged', at: aged);
    await intakeRepository.addIntake(entry);
    ExportDiaryToHealthUsecase.clock = () => DateTime(2026, 4, 2, 12);
    await usecase.exportNow();

    // Weeks later profile B, which has nothing on that day, clears it.
    ExportDiaryToHealthUsecase.clock = () => now;
    provider.activeProfileId = 'profile-b';
    await intakeRepository.deleteIntake(entry);
    await usecase.exportNow();
    expect(healthService.held, isEmpty);

    // Back on A, whose diary still has the entry.
    provider.activeProfileId = 'test-profile';
    await intakeRepository.addIntake(entry);
    expect(await usecase.exportNow(), 1);
    expect(healthService.heldTimes, [aged]);
  });

  test('a boundary clear cut short is redone under the old boundary', () async {
    await intakeRepository.addIntake(_intake(id: 'c', at: yesterdayMorning));
    await usecase.exportNow();

    // The old window is cleared, then the export is switched off before
    // the day is written under the new boundary.
    await configDataSource.setConfigDayStartOffset(4, 0);
    healthService.onReplace = () async {
      healthService.onReplace = null;
      await configDataSource.setConfigHealthExportEnabled(false);
    };
    await usecase.exportNow();
    expect(healthService.held, isEmpty);

    // Back on, under the boundary the day was last written with.
    await configDataSource.setConfigHealthExportEnabled(true);
    await configDataSource.setConfigDayStartOffset(0, 0);
    await usecase.exportNow();
    expect(healthService.heldTimes, [yesterdayMorning]);
  });
}
