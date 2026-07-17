import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/send_intake_to_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/hive_test_setup.dart';

/// Returns pre-opened, unencrypted boxes so the usecase can run against a
/// "target profile" without the full Hive/encryption bootstrap.
class _TestHiveDBProvider extends HiveDBProvider {
  final Map<String, Box<dynamic>> _scoped;
  final List<(String, String)> closedBoxes = [];

  _TestHiveDBProvider(this._scoped);

  @override
  Future<Box<E>> openScopedBox<E>(String baseName, String boxSuffix) async {
    return _scoped[baseName] as Box<E>;
  }

  // The fake hands back long-lived boxes it doesn't own (the test keeps
  // asserting on them after copyToProfiles returns), unlike production's
  // openScopedBox which opens a dedicated box per suffix that the usecase
  // is responsible for closing. Closing here would invalidate the test's
  // box references, so this records the call instead of actually closing,
  // letting tests assert the usecase asks every scoped box to be closed.
  @override
  Future<void> closeScopedBox<E>(String baseName, String boxSuffix) async {
    closedBoxes.add((baseName, boxSuffix));
  }

  // App config is global; the goal calc reads it via ConfigDataSource. Reuse
  // the test's config box so the merge has a valid shared box to read from.
  @override
  Box<ConfigDBO> get appConfigBox =>
      _scoped[HiveDBProvider.configBoxName] as Box<ConfigDBO>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<IntakeDBO> intakeBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<UserDBO> userBox;
  late Box<ConfigDBO> configBox;
  late Box<UserActivityDBO> activityBox;
  late SendIntakeToProfilesUsecase sut;
  late _TestHiveDBProvider provider;

  setUp(() async {
    Hive.init('.');
    registerHiveAdaptersOnce();
    final tag = DateTime.now().microsecondsSinceEpoch;
    intakeBox = await Hive.openBox<IntakeDBO>('send_intake_$tag');
    trackedDayBox = await Hive.openBox<TrackedDayDBO>('send_tracked_$tag');
    userBox = await Hive.openBox<UserDBO>('send_user_$tag');
    configBox = await Hive.openBox<ConfigDBO>('send_config_$tag');
    activityBox = await Hive.openBox<UserActivityDBO>('send_activity_$tag');

    // The target profile must be set up (have user data) for a copy to land.
    await userBox.put(
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
    await configBox.put('ConfigKey', ConfigDBO.empty());

    provider = _TestHiveDBProvider({
      HiveDBProvider.intakeBoxName: intakeBox,
      HiveDBProvider.trackedDayBoxName: trackedDayBox,
      HiveDBProvider.userBoxName: userBox,
      HiveDBProvider.configBoxName: configBox,
      HiveDBProvider.userActivityBoxName: activityBox,
    });
    sut = SendIntakeToProfilesUsecase(provider);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  IntakeEntity buildIntake() => IntakeEntity(
    id: 'source-intake',
    unit: 'g',
    amount: 100,
    type: IntakeTypeEntity.breakfast,
    dateTime: DateTime(2026, 1, 1, 8),
    meal: MealEntity(
      code: 'meal-1',
      name: 'Test Meal',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      nutriments: MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 20,
        fat100: 10,
        proteins100: 5,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
  );

  test('copies the intake into the target profile with a fresh id', () async {
    final intake = buildIntake();
    final target = ProfileEntity(
      id: 'target',
      name: 'Target',
      createdAt: DateTime(2026, 1, 1),
      boxSuffix: 'target',
    );

    await sut.copyToProfiles([intake], [target]);

    expect(intakeBox.length, 1);
    final copied = intakeBox.values.first;
    expect(copied.meal.name, 'Test Meal');
    expect(copied.amount, 100);
    // The copy must not reuse the source id.
    expect(copied.id, isNot('source-intake'));
  });

  test('seeds the target tracked day with the copied calories', () async {
    final intake = buildIntake();
    final target = ProfileEntity(
      id: 'target',
      name: 'Target',
      createdAt: DateTime(2026, 1, 1),
      boxSuffix: 'target',
    );

    await sut.copyToProfiles([intake], [target]);

    expect(trackedDayBox.isNotEmpty, isTrue);
    // 100 g * 200 kcal/100g = 200 kcal.
    expect(trackedDayBox.values.first.caloriesTracked, 200);
  });

  test('skips a target profile that has no user data', () async {
    await userBox.delete('UserKey');

    await sut.copyToProfiles(
      [buildIntake()],
      [
        ProfileEntity(
          id: 'target',
          name: 'Target',
          createdAt: DateTime(2026, 1, 1),
          boxSuffix: 'target',
        ),
      ],
    );

    expect(intakeBox.isEmpty, isTrue);
    expect(trackedDayBox.isEmpty, isTrue);
  });

  // Regression coverage: the scoped box-set opened for a copy used to never
  // be closed, leaking it for the rest of the app's lifetime. The usecase
  // now closes every box it opened via openScopedBox, for both the normal
  // completion path and the early-return "no user data" path.
  test('closes every scoped box it opened once the copy completes', () async {
    final target = ProfileEntity(
      id: 'target',
      name: 'Target',
      createdAt: DateTime(2026, 1, 1),
      boxSuffix: 'target',
    );

    await sut.copyToProfiles([buildIntake()], [target]);

    expect(provider.closedBoxes.toSet(), {
      (HiveDBProvider.intakeBoxName, 'target'),
      (HiveDBProvider.trackedDayBoxName, 'target'),
      (HiveDBProvider.userBoxName, 'target'),
      (HiveDBProvider.configBoxName, 'target'),
      (HiveDBProvider.userActivityBoxName, 'target'),
    });
  });

  test(
    'closes every scoped box even when the target profile is skipped',
    () async {
      await userBox.delete('UserKey');
      final target = ProfileEntity(
        id: 'target',
        name: 'Target',
        createdAt: DateTime(2026, 1, 1),
        boxSuffix: 'target',
      );

      await sut.copyToProfiles([buildIntake()], [target]);

      expect(provider.closedBoxes.toSet(), {
        (HiveDBProvider.intakeBoxName, 'target'),
        (HiveDBProvider.trackedDayBoxName, 'target'),
        (HiveDBProvider.userBoxName, 'target'),
        (HiveDBProvider.configBoxName, 'target'),
        (HiveDBProvider.userActivityBoxName, 'target'),
      });
    },
  );
}
