import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/copy_target.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/copy_entries_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../fixture/physical_activity_entity_fixtures.dart';

final _skyr = MealEntity(
  code: 'skyr',
  name: 'Skyr',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 60,
    carbohydrates100: 4,
    fat100: 0,
    proteins100: 11,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.off,
);

class _Config extends Fake implements GetConfigUsecase {
  final int hours;

  _Config(this.hours);

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    false,
    false,
    false,
    AppThemeEntity.system,
    dayStartOffsetHours: hours,
  );
}

class _AddIntake extends Fake implements AddIntakeUsecase {
  final added = <IntakeEntity>[];

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async =>
      added.add(intakeEntity);
}

class _TrackedDays extends Fake implements AddTrackedDayUsecase {
  final kcalGoal = <DateTime, double>{};
  final kcalTracked = <DateTime, double>{};
  final proteinByDay = <DateTime, double>{};

  @override
  Future<bool> hasTrackedDay(DateTime day) async => kcalGoal.containsKey(day);

  @override
  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async => kcalGoal[day] = totalKcalGoal;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double kcal) async =>
      kcalTracked[day] = (kcalTracked[day] ?? 0) + kcal;

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async =>
      proteinByDay[day] = (proteinByDay[day] ?? 0) + (proteinTracked ?? 0);
}

class _KcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoalForDay(DateTime day) async => 2000;
}

class _MacroGoal extends Fake implements GetMacroGoalUsecase {
  @override
  Future<MacroGoals> getMacroGoalsForDay(
    double totalCalorieGoal,
    DateTime day,
  ) async => (carbsG: 250.0, fatG: 70.0, proteinG: 100.0);
}

class _Intakes extends Fake implements GetIntakeUsecase {
  final byType = <IntakeTypeEntity, List<IntakeEntity>>{};
  DateTime? askedDay;
  int? askedHours;

  Future<List<IntakeEntity>> _get(
    IntakeTypeEntity type,
    DateTime day,
    int hours,
  ) async {
    askedDay = day;
    askedHours = hours;
    return byType[type] ?? const [];
  }

  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _get(IntakeTypeEntity.breakfast, day, dayStartOffsetHours);

  @override
  Future<List<IntakeEntity>> getLunchIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _get(IntakeTypeEntity.lunch, day, dayStartOffsetHours);

  @override
  Future<List<IntakeEntity>> getDinnerIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _get(IntakeTypeEntity.dinner, day, dayStartOffsetHours);

  @override
  Future<List<IntakeEntity>> getSnackIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _get(IntakeTypeEntity.snack, day, dayStartOffsetHours);
}

class _Activities extends Fake implements GetUserActivityUsecase {
  final List<UserActivityEntity> activities;

  _Activities(this.activities);

  @override
  Future<List<UserActivityEntity>> getUserActivityByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => activities;
}

class _LogActivity extends Fake implements LogUserActivityUsecase {
  final logged = <(UserActivityEntity, DateTime)>[];

  @override
  Future<void> logActivity(
    UserActivityEntity activity, {
    required DateTime day,
  }) async => logged.add((activity, day));
}

class _Water extends Fake implements GetWaterIntakeUsecase {
  final List<WaterIntakeEntity> entries;

  _Water(this.entries);

  @override
  Future<List<WaterIntakeEntity>> getEntriesForDay(
    DateTime logicalDayStart, {
    required int dayStartOffsetTotalMinutes,
  }) async => entries;
}

class _AddWater extends Fake implements AddWaterIntakeUsecase {
  final added = <WaterIntakeEntity>[];

  @override
  Future<void> addEntry(WaterIntakeEntity entry) async => added.add(entry);
}

void main() {
  late _AddIntake addIntake;
  late _TrackedDays trackedDays;
  late _Intakes intakes;
  late _LogActivity logActivity;
  late _AddWater addWater;
  var ids = 0;

  CopyEntriesUsecase usecase({
    int offsetHours = 0,
    List<UserActivityEntity> activities = const [],
    List<WaterIntakeEntity> water = const [],
  }) {
    addIntake = _AddIntake();
    trackedDays = _TrackedDays();
    intakes = _Intakes();
    logActivity = _LogActivity();
    addWater = _AddWater();
    ids = 0;
    return CopyEntriesUsecase(
      addIntake,
      trackedDays,
      _KcalGoal(),
      _MacroGoal(),
      _Config(offsetHours),
      intakes,
      _Activities(activities),
      logActivity,
      _Water(water),
      addWater,
      newId: () => 'copy-${++ids}',
    );
  }

  IntakeEntity intake(String id, DateTime at, {double amount = 150}) =>
      IntakeEntity(
        id: id,
        unit: 'g',
        amount: amount,
        type: IntakeTypeEntity.breakfast,
        meal: _skyr,
        dateTime: at,
      );

  test(
    'copies get new ids, the same meal and amount, the chosen meal type',
    () async {
      final copy = usecase();
      final original = intake('orig', DateTime(2026, 10, 18, 8, 15));

      await copy.copyIntakes([
        original,
      ], CopyTarget(day: DateTime(2026, 10, 20), type: IntakeTypeEntity.snack));

      final added = addIntake.added.single;
      expect(added.id, 'copy-1');
      expect(added.meal, same(_skyr));
      expect(added.amount, 150);
      expect(added.unit, 'g');
      expect(added.type, IntakeTypeEntity.snack);
      expect(added.dateTime, DateTime(2026, 10, 20, 8, 15));
    },
  );

  test('the target day is created and its totals grow', () async {
    final copy = usecase();

    await copy.copyIntakes([
      intake('a', DateTime(2026, 10, 18, 8)),
      intake('b', DateTime(2026, 10, 18, 9), amount: 100),
    ], CopyTarget(day: DateTime(2026, 10, 20)));

    final target = DateTime(2026, 10, 20);
    expect(trackedDays.kcalGoal[target], 2000);
    expect(trackedDays.kcalTracked[target], closeTo(90 + 60, 0.001));
    expect(trackedDays.proteinByDay[target], closeTo(16.5 + 11, 0.001));
    expect(addIntake.added.map((i) => i.type), [
      IntakeTypeEntity.breakfast,
      IntakeTypeEntity.breakfast,
    ]);
  });

  test('with a 04:00 day start a late snack stays on the target day', () async {
    final copy = usecase(offsetHours: 4);
    final lateSnack = intake('late', DateTime(2026, 10, 19, 1, 30));

    await copy.copyIntakes([
      lateSnack,
    ], CopyTarget(day: DateTime(2026, 10, 25)));

    expect(addIntake.added.single.dateTime, DateTime(2026, 10, 26, 1, 30));
    expect(trackedDays.kcalTracked.keys, [DateTime(2026, 10, 25)]);
  });

  test('a day is copied with its activities and water when asked', () async {
    final copy = usecase(
      offsetHours: 4,
      activities: [
        UserActivityEntity(
          'run',
          30,
          320,
          DateTime(2026, 10, 18, 18),
          PhysicalActivityFixtures.moderateBicycling,
        ),
      ],
      water: [
        WaterIntakeEntity(
          id: 'w1',
          dateTime: DateTime(2026, 10, 18, 10),
          amountMl: 500,
        ),
      ],
    );
    intakes.byType[IntakeTypeEntity.dinner] = [
      intake('d', DateTime(2026, 10, 18, 19)),
    ];
    intakes.byType[IntakeTypeEntity.breakfast] = [
      intake('b', DateTime(2026, 10, 18, 7)),
    ];

    await copy.copyDay(
      DateTime(2026, 10, 18),
      DateTime(2026, 10, 21),
      activities: true,
      water: true,
    );

    expect(intakes.askedDay, DateTime(2026, 10, 18));
    expect(intakes.askedHours, 4);
    expect(addIntake.added.map((i) => i.dateTime), [
      DateTime(2026, 10, 21, 7),
      DateTime(2026, 10, 21, 19),
    ]);
    final (activity, day) = logActivity.logged.single;
    expect(activity.id, isNot('run'));
    expect(activity.burnedKcal, 320);
    expect(activity.date, DateTime(2026, 10, 21, 18));
    expect(day, DateTime(2026, 10, 21));
    expect(addWater.added.single.amountMl, 500);
    expect(addWater.added.single.dateTime, DateTime(2026, 10, 21, 10));
    expect(addWater.added.single.id, isNot('w1'));
  });

  test(
    'a day without activities and water asked for copies only food',
    () async {
      final copy = usecase(
        activities: [
          UserActivityEntity(
            'run',
            30,
            320,
            DateTime(2026, 10, 18, 18),
            PhysicalActivityFixtures.moderateBicycling,
          ),
        ],
      );

      await copy.copyDay(DateTime(2026, 10, 18), DateTime(2026, 10, 21));

      expect(logActivity.logged, isEmpty);
      expect(addWater.added, isEmpty);
    },
  );
}
