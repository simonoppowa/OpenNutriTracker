import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
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

/// The intake box: what is stored, by id.
class _Store {
  final intakes = <String, IntakeEntity>{};
  double kcal = 0;
  double carbs = 0;
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

/// The day's totals, with a switch to fail either half of the update.
class _FakeTrackedDay extends Fake implements AddTrackedDayUsecase {
  final _Store store;
  bool failCalories = false;
  bool failMacros = false;
  _FakeTrackedDay(this.store);

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double calories) async {
    if (failCalories) throw StateError('calories failed');
    store.kcal += calories;
  }

  @override
  Future<void> removeDayCaloriesTracked(DateTime day, double calories) async =>
      store.kcal -= calories;

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {
    if (failMacros) throw StateError('macros failed');
    store.carbs += carbsTracked ?? 0;
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
      _UnusedTrackedDay(),
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
      trackedDay.failMacros = true;

      await expectLater(logToast(), throwsStateError);

      expect(store.intakes, isEmpty);
      expect(store.kcal, 0);
      expect(store.carbs, 0);
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

  test(
    'a failure before any total was added only removes the intake',
    () async {
      trackedDay.failCalories = true;

      await expectLater(logToast(), throwsStateError);

      expect(store.intakes, isEmpty);
      expect(store.kcal, 0);
    },
  );

  test('a rollback that fails too still reports the original error', () async {
    trackedDay.failMacros = true;
    deleteIntake.fail = true;

    await expectLater(
      logToast(),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'macros failed'),
      ),
    );
    // The totals were still taken back; only the delete was lost.
    expect(store.kcal, 0);
  });

  test('a save that succeeds is untouched by any of this', () async {
    await logToast();

    expect(store.intakes, hasLength(1));
    expect(store.kcal, 100);
  });
}

class _UnusedKcalGoal extends Fake implements GetKcalGoalUsecase {}

class _UnusedMacroGoal extends Fake implements GetMacroGoalUsecase {}

class _UnusedTrackedDay extends Fake implements GetTrackedDayUsecase {}

class _UnusedProducts extends Fake implements ProductsRepository {}

class _UnusedCache extends Fake implements RemoteSearchCacheDataSource {}
