import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

// A day gets its row when the first food is logged on it. The row's goal
// came from the goal use case, which adds the calories burned today, so a
// meal logged on an earlier day gave that day today's workout.

// Day labels, as the Diary hands them over.
final _today = DateUtils.dateOnly(DateTime.now());
final _lastWeek = DateTime(_today.year, _today.month, _today.day - 7);

class _FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<UserEntity> getUserData() async => UserEntity(
    birthday: DateTime(1984, 3, 2),
    heightCM: 172.0,
    weightKG: 74.5,
    gender: UserGenderEntity.female,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.lowActive,
  );
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(false, false, false, AppThemeEntity.system);
}

/// One 300 kcal ride, today.
class _FakeUserActivityRepository extends Fake
    implements UserActivityRepository {
  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [
    if (DateUtils.isSameDay(dateTime, _today))
      UserActivityEntity(
        'ride',
        45,
        300,
        _today,
        PhysicalActivityFixtures.moderateBicycling,
      ),
  ];
}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => 200;

  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => 60;

  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => 90;
}

class _NoopAddIntakeUsecase extends Fake implements AddIntakeUsecase {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}
}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

class _FakeBuildContext extends Fake implements BuildContext {}

final _meal = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 100,
    carbohydrates100: 10,
    fat100: 5,
    proteins100: 5,
    sugars100: 2,
    saturatedFat100: 1,
    fiber100: 1,
  ),
  source: MealSourceEntity.custom,
);

void main() {
  late Box<TrackedDayDBO> box;
  late TrackedDayDataSource dataSource;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<TrackedDayDBO>('tracked_day_past_day_goal_test');
    dataSource = TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box));
  });

  tearDown(() async {
    await box.clear();
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test("a meal logged on an earlier day leaves today's workout out of that "
      "day's goal", () async {
    final kcalGoal = GetKcalGoalUsecase(
      _FakeUserRepository(),
      _FakeConfigRepository(),
      _FakeUserActivityRepository(),
    );
    final bloc = MealDetailBloc(
      _NoopAddIntakeUsecase(),
      AddTrackedDayUsecase(TrackedDayRepository(dataSource)),
      kcalGoal,
      _FakeGetMacroGoalUsecase(),
      _FakeGetTrackedDayUsecase(),
      _FakeProductsRepository(),
      _FakeRemoteSearchCacheDataSource(),
    );
    addTearDown(bloc.close);

    await bloc.addIntake(
      _FakeBuildContext(),
      'g',
      '200',
      IntakeTypeEntity.breakfast,
      _meal,
      _lastWeek,
    );

    final row = await dataSource.getTrackedDay(_lastWeek);
    expect(
      row!.calorieGoal,
      await kcalGoal.getKcalGoal(totalKcalActivitiesParam: 0),
    );
  });
}
