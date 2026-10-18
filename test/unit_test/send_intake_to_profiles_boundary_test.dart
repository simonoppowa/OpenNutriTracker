import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/send_intake_to_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Hands the usecase profile B's boxes as its scoped box-set, and the
/// shared app config separately, as production does.
class _TestHiveDBProvider extends HiveDBProvider {
  final Map<String, Box<dynamic>> _scoped;
  final Box<ConfigDBO> _appConfig;

  _TestHiveDBProvider(this._scoped, this._appConfig);

  @override
  String get activeProfileId => 'a';

  @override
  Future<Box<E>> openScopedBox<E>(String baseName, String boxSuffix) async =>
      _scoped[baseName] as Box<E>;

  @override
  Future<void> closeScopedBox<E>(String baseName, String boxSuffix) async {}

  @override
  Box<ConfigDBO> get appConfigBox => _appConfig;
}

/// 200 kcal per 100 g.
final _meal = MealEntity(
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

void main() {
  setUpAll(registerHiveAdaptersOnce);
  tearDown(() => DayBoundaryCalc.clock = DateTime.now);

  // #1317 review: profile B was last active under a 00:00 boundary, which
  // is now 04:00. Its 02:00 ride on the 5th is credited on the 5th's row,
  // but is listed on the 4th now. Profile A copies a 02:30 snack to it.
  test('a copy into a profile keyed by an old boundary credits its '
      'activity once', () async {
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 3);
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('send_boundary_$name', bytes: Uint8List(0));
    final appConfig = await open<ConfigDBO>('app');
    final configB = await open<ConfigDBO>('config');
    final intakesB = await open<IntakeDBO>('intake');
    final rowsB = await open<TrackedDayDBO>('day');
    final usersB = await open<UserDBO>('user');
    final activitiesB = await open<UserActivityDBO>('activity');
    final b = FakeHiveDBProvider(
      activeProfileId: 'b',
      configBox: configB,
      appConfigBox: appConfig,
      intakeBox: intakesB,
      trackedDayBox: rowsB,
      userActivityBox: activitiesB,
    );
    final configDataSource = ConfigDataSource(b);
    await configDataSource.initializeConfig();
    await configDataSource.setConfigTrackedDaysOffsetMinutes(0);
    // The shared boundary moved while A was active: B's rows stayed put.
    await configDataSource.setConfigDayStartOffset(4, 0);

    await usersB.put(
      'UserKey',
      UserDBO(
        birthday: DateTime(1990, 6, 15),
        heightCM: 170,
        weightKG: 70,
        gender: UserGenderDBO.female,
        goal: UserWeightGoalDBO.maintainWeight,
        pal: UserPALDBO.sedentary,
      ),
    );
    await activitiesB.put(
      'ride',
      UserActivityDBO(
        'ride',
        30,
        150,
        DateTime(2026, 10, 5, 2),
        PhysicalActivityDBO.fromPhysicalActivityEntity(
          PhysicalActivityFixtures.moderateBicycling,
        ),
      ),
    );
    await rowsB.put(
      '2026-10-05',
      TrackedDayDBO(
        day: DateTime(2026, 10, 5),
        calorieGoal: 2150,
        caloriesTracked: 0,
        carbsGoal: 250,
        carbsTracked: 0,
        fatGoal: 70,
        fatTracked: 0,
        proteinGoal: 100,
        proteinTracked: 0,
      ),
    );

    await SendIntakeToProfilesUsecase(
      _TestHiveDBProvider({
        HiveDBProvider.intakeBoxName: intakesB,
        HiveDBProvider.trackedDayBoxName: rowsB,
        HiveDBProvider.userBoxName: usersB,
        HiveDBProvider.configBoxName: configB,
        HiveDBProvider.userActivityBoxName: activitiesB,
      }, appConfig),
    ).copyToProfiles(
      [
        IntakeEntity(
          id: 'snack',
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.snack,
          meal: _meal,
          dateTime: DateTime(2026, 10, 5, 2, 30),
        ),
      ],
      [
        ProfileEntity(
          id: 'b',
          name: 'B',
          createdAt: DateTime(2026, 1, 1),
          boxSuffix: '_b',
        ),
      ],
    );
    // B is activated later.
    await ensureTrackedDaysMatchEntries(b, configDataSource);

    final row = rowsB.get('2026-10-04');
    expect(row, isNotNull);
    expect(row!.caloriesTracked, 200);
    expect(row.calorieGoal, 2150, reason: 'the ride is credited once');
    expect(rowsB.containsKey('2026-10-05'), isFalse);
  });
}
