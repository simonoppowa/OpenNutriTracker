import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../../helpers/fake_hive_db_provider.dart';
import '../../helpers/hive_test_setup.dart';

/// "Copy to other meal" (#842): a meal's entries copied into another meal of
/// the same day, through the same `addIntake` every other log goes through.

/// The day's running totals per day, as the tracked-day row keeps them.
class _Totals {
  final kcal = <DateTime, double>{};

  double on(DateTime day) => kcal[_dayOf(day)] ?? 0;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _FakeTrackedDay extends Fake implements AddTrackedDayUsecase {
  final _Totals totals;
  _FakeTrackedDay(this.totals);

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double calories) async {
    final key = _Totals._dayOf(day);
    totals.kcal[key] = (totals.kcal[key] ?? 0) + calories;
  }

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _FakeGetTrackedDay extends Fake implements GetTrackedDayUsecase {
  final _Totals totals;
  _FakeGetTrackedDay(this.totals);

  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(
        day: day,
        calorieGoal: 2000,
        caloriesTracked: totals.on(day),
      );
}

/// Holds the first write open, as a slow disk would.
class _GatedAddIntake extends AddIntakeUsecase {
  Completer<void>? gate;
  final log = <String>[];

  _GatedAddIntake(super.repository);

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    final open = gate;
    gate = null;
    await open?.future;
    await super.addIntake(intakeEntity);
    log.add('add ${intakeEntity.meal.name}');
  }
}

/// Fails the write of one food, to check what a partial copy leaves.
class _FailingAddIntake extends AddIntakeUsecase {
  final String failOn;
  _FailingAddIntake(super.repository, this.failOn);

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    if (intakeEntity.meal.name == failOn) throw StateError('disk full');
    await super.addIntake(intakeEntity);
  }
}

class _UnusedKcalGoal extends Fake implements GetKcalGoalUsecase {}

class _UnusedMacroGoal extends Fake implements GetMacroGoalUsecase {}

class _UnusedProducts extends Fake implements ProductsRepository {}

class _NoopCache extends Fake implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String code) async {}
}

class _FakeContext extends Fake implements BuildContext {}

MealEntity _meal(
  String name, {
  required double kcal100,
  String? code,
  MealSourceEntity source = MealSourceEntity.custom,
  String mealUnit = 'g',
}) => MealEntity(
  code: code,
  name: name,
  url: null,
  mealQuantity: '100',
  mealUnit: mealUnit,
  servingQuantity: null,
  servingUnit: mealUnit,
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: 10,
    fat100: 5,
    proteins100: 3,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

final _today = DateTime(2026, 11, 9, 12, 30);
final _yesterday = DateTime(2026, 11, 8, 13, 15);

IntakeEntity _intake(
  String id,
  MealEntity meal, {
  IntakeTypeEntity type = IntakeTypeEntity.lunch,
  String unit = 'g',
  double amount = 150,
  DateTime? at,
}) => IntakeEntity(
  id: id,
  unit: unit,
  amount: amount,
  type: type,
  meal: meal,
  dateTime: at ?? _today,
);

void main() {
  setUpAll(registerHiveAdaptersOnce);

  late Box<IntakeDBO> box;
  late IntakeRepository repository;
  late _Totals totals;
  late MealDetailBloc bloc;
  var boxNumber = 0;

  MealDetailBloc buildBloc(AddIntakeUsecase add) => MealDetailBloc(
    add,
    _FakeTrackedDay(totals),
    _UnusedKcalGoal(),
    _UnusedMacroGoal(),
    _FakeGetTrackedDay(totals),
    _UnusedProducts(),
    _NoopCache(),
    deleteIntake: DeleteIntakeUsecase(repository),
  );

  setUp(() async {
    box = await Hive.openBox<IntakeDBO>(
      'copy_to_meal_${boxNumber++}',
      bytes: Uint8List(0),
    );
    repository = IntakeRepository(
      IntakeDataSource(FakeHiveDBProvider(intakeBox: box)),
    );
    totals = _Totals();
    bloc = buildBloc(AddIntakeUsecase(repository));
  });

  tearDown(() async {
    await bloc.close();
    await box.close();
  });

  /// Stores [intakes] as already logged, the way the day holds them.
  Future<void> seed(List<IntakeEntity> intakes) async {
    for (final intake in intakes) {
      await repository.addIntake(intake);
    }
  }

  Future<List<IntakeEntity>> intakesOf(IntakeTypeEntity type) async =>
      (await repository.getAllIntakesDBO())
          .map(IntakeEntity.fromIntakeDBO)
          .where((i) => i.type == type)
          .toList();

  test('copies lunch into dinner on the same day, as new entries', () async {
    final rice = _intake('rice', _meal('Rice', kcal100: 130), amount: 200);
    final curry = _intake('curry', _meal('Curry', kcal100: 90), amount: 250);
    await seed([rice, curry]);

    final copied = await bloc.copyIntakesToMeal(_FakeContext(), [
      rice,
      curry,
    ], IntakeTypeEntity.dinner);

    expect(copied, 2);
    final dinner = await intakesOf(IntakeTypeEntity.dinner);
    expect(dinner.map((i) => i.meal.name), unorderedEquals(['Rice', 'Curry']));
    // New ids: the copies are entries of their own, not the source again.
    expect(dinner.map((i) => i.id), isNot(contains('rice')));
    expect(dinner.map((i) => i.id), isNot(contains('curry')));
    expect(dinner.map((i) => i.id).toSet(), hasLength(2));
    // Same day as the source, never "now" or another day.
    for (final copy in dinner) {
      expect(DateUtils.isSameDay(copy.dateTime, _today), isTrue);
    }
    // Copy, never move: lunch is as it was.
    final lunch = await intakesOf(IntakeTypeEntity.lunch);
    expect(lunch.map((i) => i.id), unorderedEquals(['rice', 'curry']));
    // The day's row gained the copies' energy once each.
    expect(totals.on(_today), closeTo(200 * 1.3 + 250 * 0.9, 1e-9));
  });

  test('keeps amount, unit and nutrition of each entry', () async {
    final soup = _intake(
      'soup',
      _meal('Soup', kcal100: 40, mealUnit: 'ml'),
      unit: 'ml',
      amount: 330.5,
    );
    await seed([soup]);

    await bloc.copyIntakesToMeal(_FakeContext(), [
      soup,
    ], IntakeTypeEntity.dinner);

    final copy = (await intakesOf(IntakeTypeEntity.dinner)).single;
    expect(copy.unit, 'ml');
    expect(copy.amount, 330.5);
    expect(copy.totalKcal, soup.totalKcal);
    expect(copy.totalCarbsGram, soup.totalCarbsGram);
    expect(copy.totalFatsGram, soup.totalFatsGram);
    expect(copy.totalProteinsGram, soup.totalProteinsGram);
  });

  test('an empty source meal copies nothing and writes nothing', () async {
    final copied = await bloc.copyIntakesToMeal(
      _FakeContext(),
      const [],
      IntakeTypeEntity.dinner,
    );

    expect(copied, 0);
    expect(await repository.getAllIntakesDBO(), isEmpty);
    expect(totals.kcal, isEmpty);
  });

  test('copying into a meal with entries appends to them', () async {
    final salad = _intake(
      'salad',
      _meal('Salad', kcal100: 20),
      type: IntakeTypeEntity.dinner,
    );
    final bread = _intake('bread', _meal('Bread', kcal100: 250), amount: 60);
    await seed([salad, bread]);

    await bloc.copyIntakesToMeal(_FakeContext(), [
      bread,
    ], IntakeTypeEntity.dinner);

    final dinner = await intakesOf(IntakeTypeEntity.dinner);
    expect(dinner.map((i) => i.meal.name), unorderedEquals(['Salad', 'Bread']));
    expect(dinner.where((i) => i.id == 'salad'), hasLength(1));
  });

  test('deleting a copied entry leaves the source in place', () async {
    final pasta = _intake('pasta', _meal('Pasta', kcal100: 160));
    await seed([pasta]);
    await bloc.copyIntakesToMeal(_FakeContext(), [
      pasta,
    ], IntakeTypeEntity.dinner);
    final copy = (await intakesOf(IntakeTypeEntity.dinner)).single;

    await DeleteIntakeUsecase(repository).deleteIntake(copy);

    expect(await intakesOf(IntakeTypeEntity.dinner), isEmpty);
    final lunch = await intakesOf(IntakeTypeEntity.lunch);
    expect(lunch.single.id, 'pasta');
    expect(lunch.single.amount, 150);
  });

  test('deleting the source leaves the copy in place', () async {
    final pasta = _intake('pasta', _meal('Pasta', kcal100: 160));
    await seed([pasta]);
    await bloc.copyIntakesToMeal(_FakeContext(), [
      pasta,
    ], IntakeTypeEntity.dinner);

    await DeleteIntakeUsecase(repository).deleteIntake(pasta);

    expect(await intakesOf(IntakeTypeEntity.lunch), isEmpty);
    expect(
      (await intakesOf(IntakeTypeEntity.dinner)).single.meal.name,
      'Pasta',
    );
  });

  test('a Quick Add entry copies with its typed totals', () async {
    // Quick Add stores the typed totals per 100 and logs 100 g of it, under
    // a generated code (quick_add_bottom_sheet.dart).
    final quick = _intake(
      'quick',
      _meal(
        'Leftover stew',
        kcal100: 480,
        code: 'quick-add-code',
        mealUnit: 'gml',
      ),
      amount: 100,
    );
    await seed([quick]);

    await bloc.copyIntakesToMeal(_FakeContext(), [
      quick,
    ], IntakeTypeEntity.dinner);

    final copy = (await intakesOf(IntakeTypeEntity.dinner)).single;
    expect(copy.meal.name, 'Leftover stew');
    expect(copy.meal.code, 'quick-add-code');
    expect(copy.totalKcal, 480);
    expect(copy.totalCarbsGram, closeTo(10, 1e-9));
  });

  test('a recipe entry copies as the same recipe and portion', () async {
    final recipe = _intake(
      'recipe',
      _meal(
        'Lasagne',
        kcal100: 180,
        code: 'recipe-42',
        source: MealSourceEntity.recipe,
        mealUnit: 'serving',
      ),
      unit: 'serving',
      amount: 1.5,
    );
    await seed([recipe]);

    await bloc.copyIntakesToMeal(_FakeContext(), [
      recipe,
    ], IntakeTypeEntity.dinner);

    final copy = (await intakesOf(IntakeTypeEntity.dinner)).single;
    expect(copy.meal.source, MealSourceEntity.recipe);
    expect(copy.meal.code, 'recipe-42');
    expect(copy.unit, 'serving');
    expect(copy.amount, 1.5);
    expect(copy.totalKcal, recipe.totalKcal);
  });

  test('on a past day it copies within that day, not to today', () async {
    final oats = _intake(
      'oats',
      _meal('Oats', kcal100: 380),
      type: IntakeTypeEntity.breakfast,
      amount: 50,
      at: _yesterday,
    );
    await seed([oats]);

    await bloc.copyIntakesToMeal(_FakeContext(), [
      oats,
    ], IntakeTypeEntity.snack);

    final copy = (await intakesOf(IntakeTypeEntity.snack)).single;
    expect(DateUtils.isSameDay(copy.dateTime, _yesterday), isTrue);
    expect(totals.on(_yesterday), closeTo(190, 1e-9));
    expect(totals.on(_today), 0);
  });

  test('a profile switch that lands first abandons the copy', () async {
    final rice = _intake('rice', _meal('Rice', kcal100: 130));
    await seed([rice]);
    final release = Completer<void>();
    // The switch holds the lock: the copy starts while it swaps the boxes.
    final switching = withProfileSwitchLock(() => release.future);

    final copying = bloc.copyIntakesToMeal(_FakeContext(), [
      rice,
    ], IntakeTypeEntity.dinner);
    release.complete();
    await switching;

    expect(await copying, 0);
    // Nothing went to the profile the switch brought in.
    expect(await intakesOf(IntakeTypeEntity.dinner), isEmpty);
    expect(totals.kcal, isEmpty);
  });

  test('a profile switch queued mid-copy waits for every copy', () async {
    final add = _GatedAddIntake(repository)..gate = Completer<void>();
    final gate = add.gate!;
    await bloc.close();
    bloc = buildBloc(add);
    final rice = _intake('rice', _meal('Rice', kcal100: 130));
    final curry = _intake('curry', _meal('Curry', kcal100: 90));
    await seed([rice, curry]);

    final copying = bloc.copyIntakesToMeal(_FakeContext(), [
      rice,
      curry,
    ], IntakeTypeEntity.dinner);
    await pumpEventQueue();
    final switched = withProfileSwitchLock(() async => add.log.add('switch'));
    gate.complete();
    await switched;

    expect(await copying, 2);
    expect(add.log, ['add Rice', 'add Curry', 'switch']);
  });

  test('a failed write stops the copy and keeps what was copied', () async {
    await bloc.close();
    bloc = buildBloc(_FailingAddIntake(repository, 'Curry'));
    final rice = _intake('rice', _meal('Rice', kcal100: 130));
    final curry = _intake('curry', _meal('Curry', kcal100: 90));
    final naan = _intake('naan', _meal('Naan', kcal100: 300));
    await seed([rice, curry, naan]);

    await expectLater(
      bloc.copyIntakesToMeal(_FakeContext(), [
        rice,
        curry,
        naan,
      ], IntakeTypeEntity.dinner),
      throwsA(
        isA<CopyIntakesToMealException>()
            .having((e) => e.copied, 'copied', 1)
            .having((e) => e.cause, 'cause', isA<StateError>()),
      ),
    );

    // Rice is a whole entry with its row; nothing half-written for Curry.
    final dinner = await intakesOf(IntakeTypeEntity.dinner);
    expect(dinner.map((i) => i.meal.name), ['Rice']);
    expect(totals.on(_today), closeTo(150 * 1.3, 1e-9));
  });
}
