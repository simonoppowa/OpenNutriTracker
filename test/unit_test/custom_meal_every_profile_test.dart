import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/merge_custom_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/other_profile_diaries_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// The custom-meal library is shared by every profile, so deleting or
/// merging a meal reaches the diary entries each profile logged with it,
/// and keeps each profile's day totals in step (#1421).
void main() {
  final day = DateTime(2026, 10, 1, 9);

  late Box<MealDBO> customMealBox;
  late Box<IntakeDBO> intakeBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<ConfigDBO> configBox;
  late Box<ConfigDBO> appConfigBox;
  late Map<String, Box<dynamic>> partnerBoxes;
  late Map<String, Box<dynamic>> guestBoxes;
  late _ProfilesHiveDBProvider db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  Future<Map<String, Box<dynamic>>> openProfileBoxes(String name) async {
    final configBox = await Hive.openBox<ConfigDBO>('${name}_config');
    await configBox.put('ConfigKey', ConfigDBO.empty());
    return {
      HiveDBProvider.intakeBoxName: await Hive.openBox<IntakeDBO>(
        '${name}_intake',
      ),
      HiveDBProvider.trackedDayBoxName: await Hive.openBox<TrackedDayDBO>(
        '${name}_tracked',
      ),
      HiveDBProvider.userBoxName: await Hive.openBox<UserDBO>('${name}_user'),
      HiveDBProvider.configBoxName: configBox,
      HiveDBProvider.userActivityBoxName: await Hive.openBox<UserActivityDBO>(
        '${name}_activity',
      ),
    };
  }

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    customMealBox = await Hive.openBox<MealDBO>('every_custom_$stamp');
    intakeBox = await Hive.openBox<IntakeDBO>('every_intake_$stamp');
    trackedDayBox = await Hive.openBox<TrackedDayDBO>('every_tracked_$stamp');
    configBox = await Hive.openBox<ConfigDBO>('every_config_$stamp');
    await configBox.put('ConfigKey', ConfigDBO.empty());
    appConfigBox = await Hive.openBox<ConfigDBO>('every_app_$stamp');
    partnerBoxes = await openProfileBoxes('every_partner_$stamp');
    guestBoxes = await openProfileBoxes('every_guest_$stamp');
    final profileBox = await Hive.openBox<ProfileDBO>('every_profiles_$stamp');
    await profileBox.addAll([
      ProfileDBO(
        id: 'me',
        name: 'Me',
        createdAt: DateTime(2026),
        boxSuffix: '',
      ),
      ProfileDBO(
        id: 'partner',
        name: 'Partner',
        createdAt: DateTime(2026),
        boxSuffix: '_partner',
      ),
      ProfileDBO(
        id: 'guest',
        name: 'Guest',
        createdAt: DateTime(2026),
        boxSuffix: '_guest',
      ),
    ]);
    db = _ProfilesHiveDBProvider(
      profiles: profileBox,
      scopedBoxes: {'_partner': partnerBoxes, '_guest': guestBoxes},
      customMealBox: customMealBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      configBox: configBox,
      appConfigBox: appConfigBox,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  MealEntity customMeal(String code, {double kcal = 100}) => MealEntity(
    code: code,
    name: 'Oats $code',
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: 100,
    servingUnit: 'g',
    servingSize: '',
    nutriments: MealNutrimentsEntity(
      energyKcal100: kcal,
      carbohydrates100: kcal / 10,
      fat100: kcal / 50,
      proteins100: kcal / 20,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.custom,
  );

  IntakeDBO intakeOf(String id, MealEntity meal) => IntakeDBO(
    id: id,
    unit: 'g',
    amount: 100,
    type: IntakeTypeDBO.breakfast,
    meal: MealDBO.fromMealEntity(meal),
    dateTime: day,
  );

  Box<IntakeDBO> intakesOf(Map<String, Box<dynamic>> boxes) =>
      boxes[HiveDBProvider.intakeBoxName]! as Box<IntakeDBO>;
  Box<ConfigDBO> configOf(Map<String, Box<dynamic>> boxes) =>
      boxes[HiveDBProvider.configBoxName]! as Box<ConfigDBO>;
  Box<TrackedDayDBO> trackedDaysOf(Map<String, Box<dynamic>> boxes) =>
      boxes[HiveDBProvider.trackedDayBoxName]! as Box<TrackedDayDBO>;

  /// Logs [intakes] into a profile's diary, with its day's totals.
  Future<void> log(
    Box<IntakeDBO> intakes,
    Box<TrackedDayDBO> trackedDays,
    Box<ConfigDBO> config,
    List<IntakeDBO> logged,
  ) async {
    await intakes.addAll(logged);
    final addTrackedDay = AddTrackedDayUsecase(
      TrackedDayRepository(
        TrackedDayDataSource(
          FakeHiveDBProvider(
            trackedDayBox: trackedDays,
            configBox: config,
            appConfigBox: appConfigBox,
          ),
        ),
      ),
    );
    await addTrackedDay.addNewTrackedDay(day, 2000, 250, 70, 100);
    for (final intake in logged) {
      final meal = intake.meal.nutriments;
      await addTrackedDay.addDayCaloriesTracked(day, meal.energyKcal100!);
      await addTrackedDay.addDayMacrosTracked(
        day,
        carbsTracked: meal.carbohydrates100,
        fatTracked: meal.fat100,
        proteinTracked: meal.proteins100,
      );
    }
  }

  AddTrackedDayUsecase activeTrackedDays() =>
      AddTrackedDayUsecase(TrackedDayRepository(TrackedDayDataSource(db)));

  MergeCustomMealsUseCase mergeUsecase() => MergeCustomMealsUseCase(
    CustomMealDataSource(db),
    IntakeRepository(IntakeDataSource(db)),
    activeTrackedDays(),
    _NoFavourites(),
    OtherProfileDiariesUsecase(db),
  );

  test('deleting a meal removes the entries every profile logged with it, '
      'and takes them off each day', () async {
    final oats = customMeal('oats');
    final rice = customMeal('rice', kcal: 130);
    await customMealBox.addAll([
      MealDBO.fromMealEntity(oats),
      MealDBO.fromMealEntity(rice),
    ]);
    await log(intakeBox, trackedDayBox, configBox, [intakeOf('m1', oats)]);
    await log(
      intakesOf(partnerBoxes),
      trackedDaysOf(partnerBoxes),
      configOf(partnerBoxes),
      [intakeOf('p1', oats), intakeOf('p2', oats), intakeOf('p3', rice)],
    );
    await log(
      intakesOf(guestBoxes),
      trackedDaysOf(guestBoxes),
      configOf(guestBoxes),
      [intakeOf('g1', rice)],
    );

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final bloc = CustomMealsBloc(
      CustomMealDataSource(db),
      GetIntakeUsecase(
        intakeRepository,
        RecipeRepository(RecipeDataSource(db)),
      ),
      DeleteIntakeUsecase(intakeRepository),
      activeTrackedDays(),
      mergeUsecase(),
      _NoFavourites(),
      OtherProfileDiariesUsecase(db),
    );
    addTearDown(bloc.close);
    bloc.add(DeleteCustomMealEvent('oats'));
    await bloc.stream.firstWhere((state) => state is CustomMealsLoadedState);

    expect(customMealBox.values.map((meal) => meal.code), ['rice']);
    expect(intakeBox.isEmpty, isTrue);
    expect(trackedDayBox.values.single.caloriesTracked, 0);
    expect(intakesOf(partnerBoxes).values.map((intake) => intake.id), ['p3']);
    final partnerDay = trackedDaysOf(partnerBoxes).values.single;
    expect(partnerDay.caloriesTracked, closeTo(130, 1e-9));
    expect(partnerDay.carbsTracked, closeTo(13, 1e-9));
    expect(partnerDay.fatTracked, closeTo(2.6, 1e-9));
    expect(partnerDay.proteinTracked, closeTo(6.5, 1e-9));
    // The guest never logged oats: their diary is left as it was.
    expect(intakesOf(guestBoxes).values.map((intake) => intake.id), ['g1']);
    expect(trackedDaysOf(guestBoxes).values.single.caloriesTracked, 130);
    expect(db.openedScopedBoxes, [
      (HiveDBProvider.intakeBoxName, '_partner'),
      (HiveDBProvider.trackedDayBoxName, '_partner'),
      (HiveDBProvider.userBoxName, '_partner'),
      (HiveDBProvider.configBoxName, '_partner'),
      (HiveDBProvider.userActivityBoxName, '_partner'),
      (HiveDBProvider.intakeBoxName, '_guest'),
    ]);
    expect(
      db.closedScopedBoxes.toSet(),
      db.openedScopedBoxes.toSet(),
      reason: 'every box opened for another profile is closed again',
    );
  });

  test('merging a meal moves the entries every profile logged with it to '
      'the survivor, and corrects each day by the difference', () async {
    final loser = customMeal('loser');
    final winner = customMeal('winner', kcal: 160);
    await customMealBox.addAll([
      MealDBO.fromMealEntity(loser),
      MealDBO.fromMealEntity(winner),
    ]);
    await log(intakeBox, trackedDayBox, configBox, [intakeOf('m1', loser)]);
    await log(
      intakesOf(partnerBoxes),
      trackedDaysOf(partnerBoxes),
      configOf(partnerBoxes),
      [intakeOf('p1', loser), intakeOf('p2', loser)],
    );

    final result = await mergeUsecase().merge(
      loserKey: 'loser',
      winnerKey: 'winner',
    );

    expect(result.rewrittenIntakeCount, 3);
    expect(customMealBox.values.map((meal) => meal.code), ['winner']);
    expect(intakeBox.values.single.meal.code, 'winner');
    expect(trackedDayBox.values.single.caloriesTracked, closeTo(160, 1e-9));
    expect(intakesOf(partnerBoxes).values.map((intake) => intake.meal.code), [
      'winner',
      'winner',
    ]);
    final partnerDay = trackedDaysOf(partnerBoxes).values.single;
    expect(partnerDay.caloriesTracked, closeTo(320, 1e-9));
    expect(partnerDay.carbsTracked, closeTo(32, 1e-9));
    expect(partnerDay.fatTracked, closeTo(6.4, 1e-9));
    expect(partnerDay.proteinTracked, closeTo(16, 1e-9));
    expect(db.closedScopedBoxes.toSet(), db.openedScopedBoxes.toSet());
  });
}

/// Profiles `me` (active), `partner` and `guest`; the other profiles' boxes
/// are handed out by [openScopedBox], as the real provider opens them.
class _ProfilesHiveDBProvider extends FakeHiveDBProvider {
  final Box<ProfileDBO> _profiles;
  final Map<String, Map<String, Box<dynamic>>> _scopedBoxes;
  final openedScopedBoxes = <(String, String)>[];
  final closedScopedBoxes = <(String, String)>[];

  _ProfilesHiveDBProvider({
    required Box<ProfileDBO> profiles,
    required Map<String, Map<String, Box<dynamic>>> scopedBoxes,
    super.customMealBox,
    super.intakeBox,
    super.trackedDayBox,
    super.configBox,
    super.appConfigBox,
  }) : _profiles = profiles,
       _scopedBoxes = scopedBoxes,
       super(activeProfileId: 'me');

  @override
  Box<ProfileDBO> get profileBox => _profiles;

  @override
  Future<Box<E>> openScopedBox<E>(String baseName, String boxSuffix) async {
    openedScopedBoxes.add((baseName, boxSuffix));
    return _scopedBoxes[boxSuffix]![baseName]! as Box<E>;
  }

  // The test keeps reading the boxes afterwards, so record the close instead.
  @override
  Future<void> closeScopedBox<E>(String baseName, String boxSuffix) async {
    closedScopedBoxes.add((baseName, boxSuffix));
  }
}

/// No meal here is starred.
class _NoFavourites implements FavouriteMealRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
