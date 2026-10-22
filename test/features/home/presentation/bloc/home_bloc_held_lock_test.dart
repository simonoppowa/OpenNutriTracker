import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// #1317 review: Home edits and deletes take the tracked-day lock, so the
/// page reloads after the future they hand back. That future must not
/// complete before the entry and its row are written.
class _FakeGetUserActivity extends Fake implements GetUserActivityUsecase {}

class _FakeDeleteUserActivity extends Fake
    implements DeleteUserActivityUsecase {}

class _FakeGetKcalGoal extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoal extends Fake implements GetMacroGoalUsecase {}

class _FakeUpdateUserActivity extends Fake
    implements UpdateUserActivityUsecase {}

class _FakeGetUser extends Fake implements GetUserUsecase {}

class _FakeGetWaterIntake extends Fake implements GetWaterIntakeUsecase {}

class _FakeAddWaterIntake extends Fake implements AddWaterIntakeUsecase {}

class _FakeDeleteWaterIntake extends Fake implements DeleteWaterIntakeUsecase {}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

/// 100 g of a 200 kcal-per-100 g toast, logged at noon on the 5th.
final _toast = IntakeEntity(
  id: 'toast',
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.breakfast,
  meal: MealEntity(
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
  ),
  dateTime: DateTime(2026, 10, 5, 12),
);

void main() {
  var boxTag = 0;

  late Box<TrackedDayDBO> trackedDayBox;
  late Box<IntakeDBO> intakeBox;
  late HomeBloc bloc;

  setUpAll(registerHiveAdaptersOnce);

  setUp(() async {
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 13);
    GetIt.instance
      ..registerFactory<DiaryBloc>(_FakeDiaryBloc.new)
      ..registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);

    final tag = boxTag++;
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('home_held_lock_${name}_$tag', bytes: Uint8List(0));
    trackedDayBox = await open<TrackedDayDBO>('day');
    intakeBox = await open<IntakeDBO>('intake');
    final db = FakeHiveDBProvider(
      configBox: await open<ConfigDBO>('config'),
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
    );
    final configDataSource = ConfigDataSource(db);
    await configDataSource.initializeConfig();
    final configRepository = ConfigRepository(configDataSource);
    final intakeRepository = IntakeRepository(IntakeDataSource(db));

    await intakeRepository.addIntake(_toast);
    await trackedDayBox.put(
      '2026-10-05',
      TrackedDayDBO(
        day: DateTime(2026, 10, 5),
        calorieGoal: 2000,
        caloriesTracked: 200,
        carbsGoal: 250,
        carbsTracked: 40,
        fatGoal: 70,
        fatTracked: 2,
        proteinGoal: 100,
        proteinTracked: 6,
      ),
    );

    bloc = HomeBloc(
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      GetIntakeUsecase(
        intakeRepository,
        RecipeRepository(RecipeDataSource(db)),
      ),
      DeleteIntakeUsecase(intakeRepository),
      UpdateIntakeUsecase(intakeRepository),
      _FakeGetUserActivity(),
      _FakeDeleteUserActivity(),
      AddTrackedDayUsecase(TrackedDayRepository(TrackedDayDataSource(db))),
      _FakeGetKcalGoal(),
      _FakeGetMacroGoal(),
      _FakeUpdateUserActivity(),
      _FakeGetUser(),
      _FakeGetWaterIntake(),
      _FakeAddWaterIntake(),
      _FakeDeleteWaterIntake(),
    );
  });

  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await bloc.close();
    await GetIt.instance.reset();
  });

  /// Holds the tracked-day lock, as a reconciliation or a profile switch
  /// does, until the returned completer completes.
  Completer<void> holdLock() {
    final release = Completer<void>();
    unawaited(withTrackedDayLock(() => release.future));
    return release;
  }

  /// Runs [write] while the lock is held, checks it has not completed or
  /// touched the row, then releases the lock and waits for it.
  Future<void> writeBehindLock(Future<void> Function() write) async {
    final release = holdLock();
    var done = false;
    final written = write().then((_) => done = true);
    await pumpEventQueue();
    expect(done, isFalse);
    expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 200);

    release.complete();
    await written;
  }

  test(
    'an edit completes only once the entry and its row are written',
    () async {
      await writeBehindLock(
        () => bloc.updateIntakeItem('toast', {'amount': 150.0}),
      );

      expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 300);
      expect(IntakeEntity.fromIntakeDBO(intakeBox.values.single).amount, 150);
    },
  );

  test(
    'a delete completes only once the entry and its row are written',
    () async {
      await writeBehindLock(() => bloc.deleteIntakeItem(_toast));

      expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 0);
      expect(intakeBox.isEmpty, isTrue);
    },
  );

  test(
    'a delete from the outgoing profile is abandoned after a switch',
    () async {
      final releaseSwitch = Completer<void>();
      final switching = withProfileSwitchLock(() => releaseSwitch.future);
      await pumpEventQueue();

      final deleting = bloc.deleteIntakeItem(_toast);
      await pumpEventQueue();
      expect(intakeBox.values, hasLength(1));
      expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 200);

      releaseSwitch.complete();
      await switching;
      await deleting;
      expect(intakeBox.values, hasLength(1));
      expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 200);
    },
  );
}
