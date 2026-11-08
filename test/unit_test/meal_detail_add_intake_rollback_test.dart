import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

/// The intake box and the day's row. The totals stand for the cached Hive
/// record: whatever they hold is what the next save writes, which is how a
/// half-applied update survives a failed save in the real data source.
class _Store {
  final intakes = <String, IntakeEntity>{};
  double kcal = 0;
  double carbs = 0;
  double fat = 0;
  double protein = 0;
}

class _FakeAddIntake extends Fake implements AddIntakeUsecase {
  final _Store store;
  _FakeAddIntake(this.store);

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async =>
      store.intakes[intakeEntity.id] = intakeEntity;
}

class _FakeDeleteIntake extends Fake implements DeleteIntakeUsecase {
  final _Store store;
  bool fail = false;
  _FakeDeleteIntake(this.store);

  @override
  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    if (fail) throw StateError('delete failed');
    store.intakes.remove(intakeEntity.id);
  }
}

/// The day's totals, with a switch to fail either half of the update. A
/// failing write changes the record first and then throws, as
/// `TrackedDayDataSource` does when `save()` fails.
class _FakeTrackedDay extends Fake implements AddTrackedDayUsecase {
  final _Store store;
  bool failCalories = false;
  bool failMacros = false;
  _FakeTrackedDay(this.store);

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double calories) async {
    store.kcal += calories;
    if (failCalories) throw StateError('calories failed');
  }

  @override
  Future<void> reconcileDayTracked(
    DateTime day,
    double calories,
    double carbs,
    double fat,
    double protein,
  ) async {
    store
      ..kcal = calories
      ..carbs = carbs
      ..fat = fat
      ..protein = protein;
  }

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {
    store.carbs += carbsTracked ?? 0;
    store.fat += fatTracked ?? 0;
    store.protein += proteinTracked ?? 0;
    if (failMacros) throw StateError('macros failed');
  }
}

class _FakeContext extends Fake implements BuildContext {}

final _toast = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
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
  late _Store store;
  late _FakeTrackedDay trackedDay;
  late _FakeDeleteIntake deleteIntake;
  late MealDetailBloc bloc;

  setUp(() {
    store = _Store();
    trackedDay = _FakeTrackedDay(store);
    deleteIntake = _FakeDeleteIntake(store);
    bloc = MealDetailBloc(
      _FakeAddIntake(store),
      trackedDay,
      _UnusedKcalGoal(),
      _UnusedMacroGoal(),
      _FakeGetTrackedDay(store),
      _UnusedProducts(),
      _UnusedCache(),
      deleteIntake: deleteIntake,
    );
  });

  tearDown(() => bloc.close());

  Future<void> logToast() => bloc.addIntake(
    _FakeContext(),
    'g',
    '50',
    IntakeTypeEntity.breakfast,
    _toast,
    DateTime(2026, 10, 24),
  );

  test(
    'a failed totals update leaves no intake and no partial total',
    () async {
      // Something already logged that day, which the rollback must keep.
      store
        ..kcal = 300
        ..carbs = 30
        ..fat = 10
        ..protein = 12;
      trackedDay.failMacros = true;

      await expectLater(logToast(), throwsStateError);

      expect(store.intakes, isEmpty);
      expect(store.kcal, 300);
      expect(store.carbs, 30);
      expect(store.fat, 10);
      expect(store.protein, 12);
    },
  );

  test('retrying after the failure logs the food exactly once', () async {
    trackedDay.failMacros = true;
    await expectLater(logToast(), throwsStateError);

    trackedDay.failMacros = false;
    await logToast();

    expect(store.intakes, hasLength(1));
    expect(store.kcal, 100);
    expect(store.carbs, 20);
  });

  test('a calorie save that fails halfway is taken back too', () async {
    trackedDay.failCalories = true;

    await expectLater(logToast(), throwsStateError);

    expect(store.intakes, isEmpty);
    expect(store.kcal, 0);
    expect(store.carbs, 0);
  });

  test('a rollback that fails too still reports the original error', () async {
    trackedDay.failMacros = true;
    deleteIntake.fail = true;

    await expectLater(
      logToast(),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'macros failed'),
      ),
    );
    // The totals were still put back; only the delete was lost.
    expect(store.kcal, 0);
    expect(store.carbs, 0);
  });

  test('a save that succeeds is untouched by any of this', () async {
    await logToast();

    expect(store.intakes, hasLength(1));
    expect(store.kcal, 100);
  });
}

class _UnusedKcalGoal extends Fake implements GetKcalGoalUsecase {}

class _UnusedMacroGoal extends Fake implements GetMacroGoalUsecase {}

/// Reads the day's row as it stands, copied out like the real entity is.
class _FakeGetTrackedDay extends Fake implements GetTrackedDayUsecase {
  final _Store store;
  _FakeGetTrackedDay(this.store);

  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(
        day: day,
        calorieGoal: 2000,
        caloriesTracked: store.kcal,
        carbsTracked: store.carbs,
        fatTracked: store.fat,
        proteinTracked: store.protein,
      );
}

class _UnusedProducts extends Fake implements ProductsRepository {}

class _UnusedCache extends Fake implements RemoteSearchCacheDataSource {}
