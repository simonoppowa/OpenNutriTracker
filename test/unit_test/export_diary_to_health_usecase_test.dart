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

  @override
  Future<void> replaceExportedDay({
    required DateTime from,
    required DateTime to,
    required List<ExportedMeal> meals,
    required List<ExportedWater> water,
  }) async {
    if (refuse) throw StateError('refused');
    replaced.add(_Replaced(from, to, meals, water));
  }
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

    final provider = FakeHiveDBProvider(
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

  test("deleting a day's last entry clears it and forgets the day", () async {
    final intake = _intake(id: 'c', at: yesterdayMorning);
    await intakeRepository.addIntake(intake);
    await usecase.exportNow();
    await intakeRepository.deleteIntake(intake);

    expect(await usecase.exportNow(), 1);
    final cleared = healthService.replaced.last;
    expect(cleared.from, yesterday);
    expect(cleared.meals, isEmpty);
    expect((await configDataSource.getConfig()).healthExportedDays, isEmpty);
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

  test('a refused day is retried on the next run', () async {
    await intakeRepository.addIntake(_intake(id: 'a', at: now));
    healthService.refuse = true;

    await expectLater(usecase.exportNow(), throwsStateError);
    expect(
      (await configDataSource.getConfig()).healthExportedDays,
      anyOf(isNull, isEmpty),
    );

    healthService.refuse = false;
    expect(await usecase.exportNow(), 1);
  });
}
