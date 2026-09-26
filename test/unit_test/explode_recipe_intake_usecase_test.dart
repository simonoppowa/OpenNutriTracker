import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/visible_intakes.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/explode_recipe_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

MealEntity _food(String name, double kcal100, {String unit = 'g'}) =>
    MealEntity(
      code: name,
      name: name,
      brands: null,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: '100',
      mealUnit: unit,
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal100,
        carbohydrates100: 10,
        fat100: 2,
        proteins100: 4,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
        iron100: 3.25,
      ),
      source: MealSourceEntity.custom,
    );

RecipeEntity _recipe({double kcal100 = 190}) => RecipeEntity(
  id: 'recipe-1',
  name: 'Oats and banana',
  description: null,
  ingredients: [
    RecipeIngredientEntity(
      snapshotMeal: _food('Oats', 380),
      amount: 60,
      unit: 'g',
      convertedAmountG: 60,
    ),
    RecipeIngredientEntity(
      snapshotMeal: _food('Milk', 90, unit: 'ml'),
      amount: 120,
      unit: 'ml',
      convertedAmountG: 120,
    ),
  ],
  // The recipe yield was overridden from the 180 g ingredient sum.
  totalWeightG: 200,
  aggregatedNutrimentsPer100: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: 9,
    fat100: 2,
    proteins100: 4,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
  servingsCount: 2,
);

IntakeEntity _logged({RecipeEntity? snapshot, double amount = 100}) =>
    IntakeEntity(
      id: 'intake-1',
      unit: 'g',
      amount: amount,
      type: IntakeTypeEntity.breakfast,
      meal: (snapshot ?? _recipe()).toMealEntity(),
      dateTime: DateTime(2026, 9, 26, 8, 30),
      recipeSnapshot: snapshot,
    );

class _DeletedRecipeRepository implements RecipeRepository {
  @override
  RecipeEntity? getRecipeById(String id) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected recipe repository call');
}

class _CaptureIntake extends Fake implements AddIntakeUsecase {
  IntakeEntity? last;

  @override
  Future<void> addIntake(IntakeEntity intake) async {
    last = intake;
  }
}

class _KcalGoal extends Fake implements GetKcalGoalUsecase {}

class _MacroGoal extends Fake implements GetMacroGoalUsecase {}

class _GetTrackedDay extends Fake implements GetTrackedDayUsecase {}

class _Products extends Fake implements ProductsRepository {}

class _TrackedDay extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double calories) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _RecipeRepository extends Fake implements RecipeRepository {
  RecipeEntity current = _recipe();

  @override
  RecipeEntity? getRecipeById(String id) => current;
}

class _RemoteCache extends Fake implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String code) async {}
}

class _BuildContext extends Fake implements BuildContext {}

/// Keeps Hive's real persistence and object lifecycle while controlling writes.
class _ControlledIntakeBox extends Fake implements Box<IntakeDBO> {
  final Box<IntakeDBO> inner;
  Future<void> Function(IntakeDBO)? beforeAdd;
  int addCalls = 0;

  _ControlledIntakeBox(this.inner);

  @override
  Iterable<IntakeDBO> get values => inner.values;

  @override
  Future<int> add(IntakeDBO value) async {
    addCalls++;
    await beforeAdd?.call(value);
    return inner.add(value);
  }
}

class _GatedConfigDataSource extends ConfigDataSource {
  final entered = Completer<void>();
  final release = Completer<void>();

  _GatedConfigDataSource(super.db);

  @override
  Future<ConfigDBO> getConfig() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return super.getConfig();
  }
}

class _SwitchableIntakeProvider extends FakeHiveDBProvider {
  Box<IntakeDBO>? intakeOverride;

  _SwitchableIntakeProvider({
    required super.intakeBox,
    required super.trackedDayBox,
    required super.configBox,
  });

  @override
  Box<IntakeDBO> get intakeBox => intakeOverride ?? super.intakeBox;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('conversion scales saved ingredients by saved yield, not sum', () {
    final intake = _logged(snapshot: _recipe());
    final children = ExplodeRecipeIntakeUsecase.prepareIngredients(intake);
    expect(children.map((i) => i.amount), [30, 60]);
    expect(children.map((i) => i.unit), ['g', 'ml']);
    expect(children.every((i) => i.type == IntakeTypeEntity.breakfast), isTrue);
    expect(
      children.every((i) => i.dateTime == DateTime(2026, 9, 26, 8, 30)),
      isTrue,
    );
    expect(
      children.fold<double>(0.0, (sum, i) => sum + i.totalKcal),
      closeTo(168, 0.0001),
    );
    expect(intake.totalKcal, 190);
  });

  test('a normally saved recipe has matching logged and ingredient totals', () {
    final initial = _recipe();
    final computed = ComputeRecipeNutritionUseCase().compute(
      initial.ingredients,
      totalWeightOverride: initial.totalWeightG,
    );
    final saved = initial.copyWith(
      aggregatedNutrimentsPer100: computed.perHundredG,
    );
    final intake = _logged(snapshot: saved);
    final children = ExplodeRecipeIntakeUsecase.prepareIngredients(intake);
    double total(double Function(IntakeEntity) value) =>
        children.fold<double>(0.0, (sum, child) => sum + value(child));

    expect(total((i) => i.totalKcal), closeTo(intake.totalKcal, 1e-9));
    expect(
      total((i) => i.totalCarbsGram),
      closeTo(intake.totalCarbsGram, 1e-9),
    );
    expect(total((i) => i.totalFatsGram), closeTo(intake.totalFatsGram, 1e-9));
    expect(
      total((i) => i.totalProteinsGram),
      closeTo(intake.totalProteinsGram, 1e-9),
    );
  });

  test('old recipe intakes do not guess ingredients from current recipe', () {
    expect(
      () => ExplodeRecipeIntakeUsecase.prepareIngredients(_logged()),
      throwsStateError,
    );
  });

  test('snapshot survives JSON and CSV without ingredient nutrient loss', () {
    final original = IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe()));
    final fromJson = IntakeDBO.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final fromCsv = CsvDataExporter.parseIntakesFromCsv(
      CsvDataExporter.intakesToCsv([original]),
    ).single;
    for (final restored in [fromJson, fromCsv]) {
      expect(restored.recipeSnapshot?.totalWeightG, 200);
      expect(restored.recipeSnapshot?.ingredients.length, 2);
      expect(
        restored
            .recipeSnapshot
            ?.ingredients
            .first
            .snapshotMeal
            .nutriments
            .iron100,
        3.25,
      );
      expect(
        ExplodeRecipeIntakeUsecase.prepareIngredients(
          IntakeEntity.fromIntakeDBO(restored),
        ).first.amount,
        30,
      );
    }
  });

  test('sharing uses the logged snapshot even after recipe deletion', () {
    final payload = SharedMealPayload.fromIntakeList([
      _logged(snapshot: _recipe()),
    ], recipeRepository: _DeletedRecipeRepository());
    expect(payload.recipes.single.recipe.name, 'Oats and banana');
    expect(payload.recipes.single.recipe.ingredients.length, 2);
  });

  test(
    'logging snapshots the recipe and copying preserves that version',
    () async {
      final capture = _CaptureIntake();
      final recipes = _RecipeRepository();
      final bloc = MealDetailBloc(
        capture,
        _TrackedDay(),
        _KcalGoal(),
        _MacroGoal(),
        _GetTrackedDay(),
        _Products(),
        _RemoteCache(),
        recipeRepository: recipes,
      );
      final loggedMeal = recipes.current.toMealEntity();
      final date = DateTime(2026, 9, 26, 8);
      await bloc.addIntake(
        _BuildContext(),
        'g',
        '100',
        IntakeTypeEntity.breakfast,
        loggedMeal,
        date,
      );
      final first = capture.last!;
      expect(first.recipeSnapshot?.ingredients.length, 2);

      recipes.current = _recipe(kcal100: 999);
      await bloc.addIntake(
        _BuildContext(),
        'g',
        '100',
        IntakeTypeEntity.lunch,
        loggedMeal,
        date,
        copiedFrom: first,
      );
      expect(
        capture.last!.recipeSnapshot?.aggregatedNutrimentsPer100.energyKcal100,
        190,
      );
      await bloc.close();
    },
  );

  group('persistent conversion and recovery', () {
    late Directory temp;
    late Box<IntakeDBO> intakes;
    late Box<TrackedDayDBO> days;
    late Box<ConfigDBO> configBox;
    late _ControlledIntakeBox controlledIntakes;
    late _SwitchableIntakeProvider db;
    late ExplodeRecipeIntakeUsecase usecase;
    final day = DateTime(2026, 9, 26);

    setUpAll(() async {
      temp = await Directory.systemTemp.createTemp('recipe-explode-test-');
      Hive.init(temp.path);
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      intakes = await Hive.openBox<IntakeDBO>('explode-intakes');
      days = await Hive.openBox<TrackedDayDBO>('explode-days');
      configBox = await Hive.openBox<ConfigDBO>('explode-config');
      controlledIntakes = _ControlledIntakeBox(intakes);
      db = _SwitchableIntakeProvider(
        intakeBox: controlledIntakes,
        trackedDayBox: days,
        configBox: configBox,
      );
      final config = ConfigDataSource(db);
      await config.initializeConfig();
      usecase = ExplodeRecipeIntakeUsecase(db, config);
    });

    tearDown(() async {
      await intakes.deleteFromDisk();
      await days.deleteFromDisk();
      await configBox.deleteFromDisk();
    });

    tearDownAll(() async {
      await temp.delete(recursive: true);
    });

    Future<void> addTrackedDay(double calories, {DateTime? forDay}) => days.put(
      (forDay ?? day).toParsedDay(),
      TrackedDayDBO(
        day: forDay ?? day,
        calorieGoal: 2000,
        caloriesTracked: calories,
        carbsGoal: 250,
        carbsTracked: 9,
        fatGoal: 70,
        fatTracked: 2,
        proteinGoal: 100,
        proteinTracked: 4,
      ),
    );

    test(
      'replaces original only after children are written and reconciles',
      () async {
        await intakes.add(
          IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
        );
        await addTrackedDay(190);

        await usecase.explode('intake-1');

        final visible = await IntakeDataSource(db).getAllIntakes();
        expect(visible.map((i) => i.meal.name), ['Oats', 'Milk']);
        expect(visible.every((i) => i.conversionParentId == null), isTrue);
        expect(intakes.values.any((i) => i.id == 'intake-1'), isFalse);
        expect(
          days.get(day.toParsedDay())!.caloriesTracked,
          closeTo(168, 0.0001),
        );
        expect(days.get(day.toParsedDay())!.calorieGoal, 2000);
      },
    );

    test('overlapping conversions persist only one ingredient set', () async {
      await intakes.add(
        IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
      );
      await addTrackedDay(190);
      final entered = Completer<void>();
      final release = Completer<void>();
      controlledIntakes.beforeAdd = (_) async {
        if (controlledIntakes.addCalls == 1) {
          entered.complete();
          await release.future;
        }
      };

      final first = usecase.explode('intake-1');
      await entered.future;
      final second = usecase.explode('intake-1');
      final results = Future.wait([
        for (final run in [first, second])
          run.then<Object?>((_) => null, onError: (Object error) => error),
      ]);
      release.complete();
      final outcomes = await results;

      expect(intakes.length, 2);
      expect(outcomes, [null, null]);
      expect(controlledIntakes.addCalls, 2);
      expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
      expect(intakes.values.map((i) => i.amount), [30, 60]);
      expect(intakes.values.every((i) => i.conversionParentId == null), isTrue);
      final totals = days.get(day.toParsedDay())!;
      expect(totals.caloriesTracked, closeTo(168, 1e-9));
      expect(totals.carbsTracked, closeTo(9, 1e-9));
      expect(totals.fatTracked, closeTo(1.8, 1e-9));
      expect(totals.proteinTracked, closeTo(3.6, 1e-9));

      await intakes.close();
      intakes = await Hive.openBox<IntakeDBO>('explode-intakes');
      final reopenedDb = FakeHiveDBProvider(
        intakeBox: intakes,
        trackedDayBox: days,
        configBox: configBox,
      );
      await ExplodeRecipeIntakeUsecase(
        reopenedDb,
        ConfigDataSource(reopenedDb),
      ).recover();
      expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
      expect(visibleIntakes(intakes.values), hasLength(2));
    });

    test(
      'overlapping calls wait for finalization after the parent is deleted',
      () async {
        await intakes.add(
          IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
        );
        await addTrackedDay(190);
        final config = _GatedConfigDataSource(db);
        usecase = ExplodeRecipeIntakeUsecase(db, config);
        var firstFinished = false;
        var secondFinished = false;

        final first = usecase.explode('intake-1').then((_) {
          firstFinished = true;
        });
        await config.entered.future;
        expect(intakes.values.any((i) => i.id == 'intake-1'), isFalse);
        final second = usecase.explode('intake-1').then((_) {
          secondFinished = true;
        });
        final both = Future.wait([first, second]);
        final succeeds = expectLater(both, completes);
        await pumpEventQueue();
        final finishedWhileBlocked = firstFinished || secondFinished;
        config.release.complete();
        await succeeds;

        expect(finishedWhileBlocked, isFalse);
        expect(firstFinished && secondFinished, isTrue);
        expect(controlledIntakes.addCalls, 2);
        expect(
          intakes.values.every((i) => i.conversionParentId == null),
          isTrue,
        );
        expect(
          days.get(day.toParsedDay())!.caloriesTracked,
          closeTo(168, 1e-9),
        );
      },
    );

    test('overlapping failures roll back once and allow a retry', () async {
      await intakes.add(
        IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
      );
      await addTrackedDay(190);
      final entered = Completer<void>();
      final release = Completer<void>();
      final failure = StateError('Ingredient write failed');
      controlledIntakes.beforeAdd = (_) async {
        if (controlledIntakes.addCalls == 2) {
          entered.complete();
          await release.future;
          throw failure;
        }
      };

      final first = usecase.explode('intake-1');
      await entered.future;
      expect(intakes.length, 2);
      expect(visibleIntakes(intakes.values).single.id, 'intake-1');
      final second = usecase.explode('intake-1');
      final firstFailure = expectLater(first, throwsA(same(failure)));
      final secondFailure = expectLater(second, throwsA(same(failure)));
      release.complete();
      await Future.wait([firstFailure, secondFailure]);

      expect(controlledIntakes.addCalls, 2);
      expect(intakes.values.single.id, 'intake-1');
      expect(days.get(day.toParsedDay())!.caloriesTracked, 190);
      controlledIntakes.beforeAdd = null;
      await usecase.explode('intake-1');

      expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
      expect(days.get(day.toParsedDay())!.caloriesTracked, closeTo(168, 1e-9));
    });

    test(
      'another occurrence of the same recipe converts independently',
      () async {
        await intakes.add(
          IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
        );
        await intakes.add(
          IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe()))
            ..id = 'intake-2',
        );
        await addTrackedDay(380);
        final entered = Completer<void>();
        final release = Completer<void>();
        controlledIntakes.beforeAdd = (child) async {
          if (child.conversionParentId == 'intake-1' && !entered.isCompleted) {
            entered.complete();
            await release.future;
          }
        };

        final first = usecase.explode('intake-1');
        await entered.future;
        try {
          await usecase.explode('intake-2');
          expect(intakes.values.any((i) => i.id == 'intake-1'), isTrue);
          expect(intakes.values.any((i) => i.id == 'intake-2'), isFalse);
          expect(visibleIntakes(intakes.values), hasLength(3));
        } finally {
          release.complete();
          await first;
        }

        expect(intakes.values.map((i) => i.meal.name), [
          'Oats',
          'Milk',
          'Oats',
          'Milk',
        ]);
        expect(
          days.get(day.toParsedDay())!.caloriesTracked,
          closeTo(336, 1e-9),
        );
      },
    );

    test(
      'the same intake ID in another box does not join a running conversion',
      () async {
        final otherIntakes = await Hive.openBox<IntakeDBO>(
          'explode-other-intakes',
        );
        addTearDown(otherIntakes.deleteFromDisk);
        for (final box in [intakes, otherIntakes]) {
          await box.add(
            IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
          );
        }
        final entered = Completer<void>();
        final release = Completer<void>();
        controlledIntakes.beforeAdd = (_) async {
          if (!entered.isCompleted) {
            entered.complete();
            await release.future;
          }
        };

        final first = usecase.explode('intake-1');
        await entered.future;
        db.intakeOverride = otherIntakes;
        try {
          await usecase.explode('intake-1');
          expect(otherIntakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
          expect(intakes.values.single.id, 'intake-1');
        } finally {
          // Restore the first box before letting its conversion finalize.
          db.intakeOverride = null;
          release.complete();
          await first;
        }
        expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
      },
    );

    test('a completed conversion is not cached for later calls', () async {
      await intakes.add(
        IntakeDBO.fromIntakeEntity(_logged(snapshot: _recipe())),
      );
      await usecase.explode('intake-1');

      await expectLater(
        usecase.explode('intake-1'),
        throwsA(
          isStateError.having(
            (error) => error.message,
            'message',
            'Recipe intake no longer exists',
          ),
        ),
      );
      expect(controlledIntakes.addCalls, 2);
      expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
    });

    test(
      'validation failure is released so the intake can be retried',
      () async {
        final parent = IntakeDBO.fromIntakeEntity(_logged());
        await intakes.add(parent);
        await expectLater(usecase.explode('intake-1'), throwsStateError);
        expect(controlledIntakes.addCalls, 0);

        parent.recipeSnapshot = _recipe().toDBO();
        await parent.save();
        await usecase.explode('intake-1');

        expect(intakes.values.map((i) => i.meal.name), ['Oats', 'Milk']);
      },
    );

    test(
      'recovery rolls back partial children while original exists',
      () async {
        final original = _logged(snapshot: _recipe());
        await intakes.add(IntakeDBO.fromIntakeEntity(original));
        await intakes.add(
          IntakeDBO.fromIntakeEntity(
            ExplodeRecipeIntakeUsecase.prepareIngredients(original).first,
          ),
        );
        expect(visibleIntakes(intakes.values).length, 1);

        await usecase.recover();

        expect(intakes.length, 1);
        expect(intakes.values.single.id, 'intake-1');
      },
    );

    test('recovery commits children if parent was already removed', () async {
      final original = _logged(snapshot: _recipe());
      final children = ExplodeRecipeIntakeUsecase.prepareIngredients(original);
      await intakes.addAll(children.map(IntakeDBO.fromIntakeEntity));
      await addTrackedDay(190);

      await usecase.recover();

      expect(intakes.values.every((i) => i.conversionParentId == null), isTrue);
      expect(
        days.get(day.toParsedDay())!.caloriesTracked,
        closeTo(168, 0.0001),
      );
      await usecase.recover();
      expect(intakes.length, 2);
    });

    test('reconciles the logical day when it starts after midnight', () async {
      final previousDay = DateTime(2026, 9, 25);
      final original = _logged(snapshot: _recipe());
      final earlyIntake = IntakeEntity(
        id: original.id,
        unit: original.unit,
        amount: original.amount,
        type: original.type,
        meal: original.meal,
        dateTime: DateTime(2026, 9, 26, 3, 30),
        recipeSnapshot: original.recipeSnapshot,
      );
      await ConfigDataSource(db).setConfigDayStartOffsetHours(4);
      await ConfigDataSource(db).setConfigDayStartOffsetMinutes(15);
      await intakes.add(IntakeDBO.fromIntakeEntity(earlyIntake));
      await addTrackedDay(190, forDay: previousDay);

      await usecase.explode(original.id);

      expect(
        days.get(previousDay.toParsedDay())!.caloriesTracked,
        closeTo(168, 0.0001),
      );
      expect(
        intakes.values.every((i) => i.dateTime == earlyIntake.dateTime),
        isTrue,
      );
    });
  });
}
