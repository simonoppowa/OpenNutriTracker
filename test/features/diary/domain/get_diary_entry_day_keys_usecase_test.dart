import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/domain/usecase/get_diary_entry_day_keys_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

class _Intakes extends Fake implements IntakeRepository {
  final List<IntakeDBO> entries;
  _Intakes(this.entries);

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async => entries;
}

class _Activities extends Fake implements UserActivityRepository {
  final List<UserActivityDBO> entries;
  _Activities(this.entries);

  @override
  Future<List<UserActivityDBO>> getAllUserActivityDBO() async => entries;
}

class _Config extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

class _Days extends Fake implements GetTrackedDayUsecase {
  final List<TrackedDayEntity> rows;
  _Days(this.rows);

  @override
  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
    DateTime start,
    DateTime end,
  ) async => rows;
}

IntakeDBO _food(DateTime time) => IntakeDBO(
  id: 'food',
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.lunch,
  dateTime: time,
  meal: MealDBO.fromMealEntity(
    MealEntity(
      code: 'zero',
      name: 'Zero calorie food',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom,
    ),
  ),
);

UserActivityDBO _activity(DateTime time, {String? externalId}) =>
    UserActivityDBO(
      'activity',
      30,
      0,
      time,
      PhysicalActivityDBO(
        'run',
        'Run',
        'Running',
        8,
        const [],
        PhysicalActivityTypeDBO.running,
      ),
      externalId: externalId,
    );

void main() {
  test(
    'empty day has no key while zero-calorie food and activity keep theirs',
    () async {
      final intakes = <IntakeDBO>[];
      final activities = <UserActivityDBO>[];
      final usecase = GetDiaryEntryDayKeysUsecase(
        _Intakes(intakes),
        _Activities(activities),
      );
      expect(await usecase.getEntryDayKeys(0), isEmpty);

      intakes.add(_food(DateTime(2026, 10, 28, 12)));
      activities.add(_activity(DateTime(2026, 10, 29, 13)));
      expect(await usecase.getEntryDayKeys(0), {'2026-10-28', '2026-10-29'});

      intakes.clear();
      expect(await usecase.getEntryDayKeys(0), {'2026-10-29'});
      activities.clear();
      expect(await usecase.getEntryDayKeys(0), isEmpty);
    },
  );

  test(
    'uses the configured logical day boundary for foods and workouts',
    () async {
      final usecase = GetDiaryEntryDayKeysUsecase(
        _Intakes([_food(DateTime(2026, 10, 29, 1))]),
        _Activities([
          _activity(DateTime(2026, 10, 30, 2), externalId: 'health-1'),
        ]),
      );
      expect(await usecase.getEntryDayKeys(4 * 60), {
        '2026-10-28',
        '2026-10-29',
      });
    },
  );

  test(
    'calendar markers follow entries while an empty day keeps its saved goal',
    () async {
      final date = DateTime(2026, 10, 28);
      final goal = TrackedDayEntity(
        day: date,
        calorieGoal: 2200,
        caloriesTracked: 0,
      );
      final foods = [_food(DateTime(2026, 10, 28, 12))];
      final bloc = DiaryBloc(
        _Days([goal]),
        _Config(),
        GetDiaryEntryDayKeysUsecase(_Intakes(foods), _Activities([])),
      );
      addTearDown(bloc.close);
      DayBoundaryCalc.clock = () => DateTime(2026, 10, 28, 14);
      addTearDown(() => DayBoundaryCalc.clock = DateTime.now);

      bloc.add(const LoadDiaryYearEvent());
      var loaded =
          await bloc.stream.firstWhere((state) => state is DiaryLoadedState)
              as DiaryLoadedState;
      expect(loaded.trackedDayMap['2026-10-28'], goal);

      foods.clear();
      bloc.add(const LoadDiaryYearEvent());
      loaded =
          await bloc.stream.firstWhere((state) => state is DiaryLoadedState)
              as DiaryLoadedState;
      expect(loaded.trackedDayMap, isEmpty);
      expect(goal.calorieGoal, 2200);
    },
  );
}
