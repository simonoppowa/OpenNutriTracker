import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_custom_activity_template_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_custom_activity_templates_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

// #1373: creating a tracked day used to be check-then-create — ask
// `hasTrackedDay`, and if it said no, write a fresh row with every total at
// zero through `Box.put`. A writer that created and incremented the same day
// in between (the Health Connect import runs unawaited from Home) had its
// totals reset to zero. These pin the create-if-absent path and the callers
// that now use it.

final _day = DateTime.utc(2026, 10, 14);

/// What another writer has put on the day by the time a creator acts.
TrackedDayDBO _rowWithTotals() => TrackedDayDBO(
  day: _day,
  calorieGoal: 2000,
  caloriesTracked: 500,
  carbsGoal: 250,
  carbsTracked: 60,
  fatGoal: 70,
  fatTracked: 20,
  proteinGoal: 100,
  proteinTracked: 30,
);

/// The real use case over a real box, except that its check loses the race:
/// it answers "no such day", and before the caller can act on that, another
/// writer creates the day and logs 500 kcal on it.
class _RacingAddTrackedDayUsecase extends AddTrackedDayUsecase {
  final TrackedDayDataSource _dataSource;

  _RacingAddTrackedDayUsecase(super.repo, this._dataSource);

  @override
  Future<bool> hasTrackedDay(DateTime day) async {
    final exists = await super.hasTrackedDay(day);
    if (!exists) await _dataSource.saveTrackedDay(_rowWithTotals());
    return exists;
  }
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal({
    Object? userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async => 1800;
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

class _NoopAddUserActivityUsecase extends Fake
    implements AddUserActivityUsecase {
  @override
  Future<void> addUserActivity(UserActivityEntity userActivityEntity) async {}
}

/// `addIntake` reads the day's totals before adding to them, to restore
/// them if the update fails (#1461); nothing here exercises that.
class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeAddCustomActivityTemplateUsecase extends Fake
    implements AddCustomActivityTemplateUsecase {}

class _FakeGetCustomActivityTemplatesUsecase extends Fake
    implements GetCustomActivityTemplatesUsecase {}

class _FakeBuildContext extends Fake implements BuildContext {}

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

final _meal = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: _nutriments,
  source: MealSourceEntity.custom,
);

void main() {
  late Box<TrackedDayDBO> box;
  late TrackedDayDataSource dataSource;
  late TrackedDayRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<TrackedDayDBO>('tracked_day_if_absent_test');
    dataSource = TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box));
    repository = TrackedDayRepository(dataSource);
  });

  tearDown(() async {
    await box.clear();
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  void expectTotalsKept(TrackedDayDBO? row) {
    expect(row, isNotNull);
    expect(row!.calorieGoal, 2000);
    expect(row.caloriesTracked, 500);
    expect(row.carbsTracked, 60);
    expect(row.fatTracked, 20);
    expect(row.proteinTracked, 30);
  }

  group('TrackedDayDataSource.saveTrackedDayIfAbsent', () {
    test('creates the day when it has no row', () async {
      final created = await dataSource.saveTrackedDayIfAbsent(
        TrackedDayDBO(day: _day, calorieGoal: 1800, caloriesTracked: 0),
      );

      expect(created, isTrue);
      expect((await dataSource.getTrackedDay(_day))!.calorieGoal, 1800);
    });

    test('never zeroes an existing row with totals', () async {
      await dataSource.saveTrackedDay(_rowWithTotals());

      final created = await dataSource.saveTrackedDayIfAbsent(
        TrackedDayDBO(
          day: _day,
          calorieGoal: 1800,
          caloriesTracked: 0,
          carbsTracked: 0,
          fatTracked: 0,
          proteinTracked: 0,
        ),
      );

      expect(created, isFalse);
      expectTotalsKept(await dataSource.getTrackedDay(_day));
    });

    test('two creators racing for one day write it once', () async {
      // Neither awaits the other: both start before either has finished
      // writing, which is the window a check-then-create left open.
      final results = await Future.wait([
        dataSource.saveTrackedDayIfAbsent(_rowWithTotals()),
        dataSource.saveTrackedDayIfAbsent(
          TrackedDayDBO(day: _day, calorieGoal: 1800, caloriesTracked: 0),
        ),
      ]);

      expect(results, [isTrue, isFalse]);
      expectTotalsKept(await dataSource.getTrackedDay(_day));
    });
  });

  test('a creator whose check went stale leaves the other writer\'s day '
      'alone', () async {
    final usecase = AddTrackedDayUsecase(repository);

    // The creator checks: no such day.
    expect(await usecase.hasTrackedDay(_day), isFalse);
    // Meanwhile another writer creates the day and logs 500 kcal on it.
    await dataSource.saveTrackedDay(_rowWithTotals());
    // The creator acts on its stale answer.
    final created = await usecase.addNewTrackedDayIfAbsent(
      _day,
      1800,
      200,
      60,
      90,
    );

    expect(created, isFalse);
    expectTotalsKept(await dataSource.getTrackedDay(_day));
  });

  group('callers that create a missing day keep what is already there', () {
    late _RacingAddTrackedDayUsecase racingUsecase;

    setUp(() {
      racingUsecase = _RacingAddTrackedDayUsecase(repository, dataSource);
    });

    test('MealDetailBloc, logging an intake', () async {
      final bloc = MealDetailBloc(
        _NoopAddIntakeUsecase(),
        racingUsecase,
        _FakeGetKcalGoalUsecase(),
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
        _day,
      );

      final row = await dataSource.getTrackedDay(_day);
      // The other writer's 500 kcal plus this intake's 200, not 200 alone.
      expect(row!.caloriesTracked, 700);
      expect(row.calorieGoal, 2000);
    });

    test('LogUserActivityUsecase, logging an activity', () async {
      final usecase = LogUserActivityUsecase(
        _NoopAddUserActivityUsecase(),
        racingUsecase,
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
      );

      await usecase.logActivity(
        UserActivityEntity(
          'activity-1',
          30,
          300,
          _day,
          PhysicalActivityFixtures.moderateBicycling,
        ),
        day: _day,
      );

      final row = await dataSource.getTrackedDay(_day);
      expect(row!.caloriesTracked, 500);
      // The other writer's 2000 kcal goal raised by the 300 burned, not the
      // 1800 a fresh row would have started from.
      expect(row.calorieGoal, 2300);
    });

    test('ActivityDetailBloc, logging an activity', () async {
      final bloc = ActivityDetailBloc(
        _FakeGetUserUsecase(),
        _NoopAddUserActivityUsecase(),
        racingUsecase,
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeAddCustomActivityTemplateUsecase(),
        _FakeGetCustomActivityTemplatesUsecase(),
      );
      addTearDown(bloc.close);

      await bloc.persistActivity(
        '30',
        300,
        PhysicalActivityFixtures.moderateBicycling,
        _day,
      );

      final row = await dataSource.getTrackedDay(_day);
      expect(row!.caloriesTracked, 500);
      expect(row.calorieGoal, 2300);
    });
  });

  // #1317 review: a write can wait for the tracked-day lock, so callers
  // refresh after the future it hands back, and that future must not
  // complete before the entry and its row are stored.
  group('writers complete only once their row is written', () {
    late AddTrackedDayUsecase addTrackedDay;

    setUp(() => addTrackedDay = AddTrackedDayUsecase(repository));

    /// Holds the tracked-day lock, as a reconciliation or a profile
    /// switch does, until the returned completer completes.
    Completer<void> holdLock() {
      final release = Completer<void>();
      unawaited(withTrackedDayLock(() => release.future));
      return release;
    }

    test('MealDetailBloc.addIntake', () async {
      final bloc = MealDetailBloc(
        _NoopAddIntakeUsecase(),
        addTrackedDay,
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      );
      addTearDown(bloc.close);
      final release = holdLock();

      var done = false;
      final added = bloc
          .addIntake(
            _FakeBuildContext(),
            'g',
            '200',
            IntakeTypeEntity.breakfast,
            _meal,
            _day,
          )
          .then((_) => done = true);
      await pumpEventQueue();
      expect(done, isFalse);
      expect(await dataSource.getTrackedDay(_day), isNull);

      release.complete();
      await added;
      expect((await dataSource.getTrackedDay(_day))!.caloriesTracked, 200);
    });

    test('ActivityDetailBloc.persistActivity, several in a row as the '
        'activity scanner logs them', () async {
      final bloc = ActivityDetailBloc(
        _FakeGetUserUsecase(),
        _NoopAddUserActivityUsecase(),
        addTrackedDay,
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeAddCustomActivityTemplateUsecase(),
        _FakeGetCustomActivityTemplatesUsecase(),
      );
      addTearDown(bloc.close);
      final release = holdLock();

      var done = false;
      final imported = () async {
        for (final kcal in [300.0, 200.0]) {
          await bloc.persistActivity(
            '30',
            kcal,
            PhysicalActivityFixtures.moderateBicycling,
            _day,
          );
        }
      }().then((_) => done = true);
      await pumpEventQueue();
      expect(done, isFalse);
      expect(await dataSource.getTrackedDay(_day), isNull);

      release.complete();
      await imported;
      // A new day's 1800 kcal goal, raised by both activities.
      expect((await dataSource.getTrackedDay(_day))!.calorieGoal, 2300);
    });
  });
}
