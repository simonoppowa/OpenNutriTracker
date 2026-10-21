import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/shared_meal_import_dialogs.dart';
import 'package:opennutritracker/features/home/presentation/widgets/shared_meal_importer.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

MealEntity meal(String name, {double? kcal = 200, String? unit}) => MealEntity(
      code: name,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: unit,
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
          energyKcal100: kcal,
          carbohydrates100: null,
          fat100: null,
          proteins100: null,
          sugars100: null,
          saturatedFat100: null,
          fiber100: null),
      source: MealSourceEntity.custom,
    );

SharedMealItem item(String name) =>
    SharedMealItem.fromIntakeEntity(IntakeEntity(
      id: name,
      unit: 'g',
      amount: 90,
      type: IntakeTypeEntity.dinner,
      meal: meal(name),
      dateTime: DateTime(2026, 1, 1),
    ));

SharedMealPayload payload(
        {List<SharedMealOffRef> refs = const [],
        List<SharedMealRecipeItem> recipes = const []}) =>
    SharedMealPayload(
      version: 2,
      offRefs: refs,
      items: [item('Sardines'), item('Bread')],
      recipes: recipes,
    );

SharedMealRecipeItem recipeItem({double totalWeightG = 100}) {
  final recipe = RecipeEntity(
    id: 'r',
    name: 'Recipe',
    description: null,
    servingsCount: null,
    ingredients: [
      RecipeIngredientEntity(
          snapshotMeal: meal('Ingredient'),
          amount: 100,
          unit: 'g',
          convertedAmountG: 100)
    ],
    totalWeightG: totalWeightG,
    aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  return SharedMealRecipeItem(
      recipe: SharedRecipePayload.fromRecipe(recipe), amount: 50, unit: 'g');
}

Widget app(Widget child, {bool kj = false, double scale = 1}) =>
    ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(usesKilojoules: kj),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );

class _Meals extends Fake implements CustomMealDataSource {
  final saved = <MealDBO>[];
  @override
  Future<void> saveCustomMeal(MealDBO value) async => saved.add(value);
}

class _Barcode extends Fake implements SearchProductByBarcodeUseCase {
  final calls = <String>[];
  @override
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    calls.add(barcode);
    if (barcode == 'missing') throw StateError('unavailable');
    if (barcode == 'stall') return Completer<MealEntity>().future;
    return meal('OFF food', unit: 'g');
  }
}

class _Intakes extends Fake implements MealDetailBloc {
  final meals = <MealEntity>[];
  final amounts = <String>[];
  final units = <String>[];
  Completer<void>? firstWrite;
  @override
  Future<void> addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, MealEntity meal, DateTime day) async {
    meals.add(meal);
    amounts.add(amountText);
    units.add(unit);
    if (meals.length == 1 && firstWrite != null) await firstWrite!.future;
  }
}

class _Config extends Fake implements GetConfigUsecase {
  bool imperial = false;
  @override
  Future<ConfigEntity> getConfig() async =>
      ConfigEntity(true, true, false, AppThemeEntity.system,
          usesImperialFoodUnits: imperial);
}

class _Recipes extends Fake implements SaveRecipeUseCase {
  final saved = <RecipeEntity>[];
  final overridden = <bool>[];
  @override
  Future<RecipeEntity> save(RecipeEntity recipe,
      {bool totalWeightOverridden = false}) async {
    saved.add(recipe);
    overridden.add(totalWeightOverridden);
    return recipe;
  }
}

class _Home extends Fake implements HomeBloc {
  int refreshes = 0;
  @override
  void add(dynamic event) => refreshes++;
}

class _Diary extends Fake implements DiaryBloc {
  @override
  void add(dynamic event) {}
}

class _Day extends Fake implements CalendarDayBloc {
  @override
  void add(dynamic event) {}
}

class _RecipeBloc extends Fake implements RecipesBloc {
  @override
  void add(dynamic event) {}
}

class _CustomBloc extends Fake implements CustomMealsBloc {
  @override
  void add(dynamic event) {}
}

void main() {
  late _Meals meals;
  late _Barcode barcode;
  late _Intakes intakes;
  late _Recipes recipes;
  late _Home home;
  late _Config config;
  setUp(() {
    meals = _Meals();
    barcode = _Barcode();
    intakes = _Intakes();
    recipes = _Recipes();
    home = _Home();
    config = _Config();
    locator.registerSingleton<GetConfigUsecase>(config);
    locator.registerSingleton<CustomMealDataSource>(meals);
    locator.registerSingleton<SearchProductByBarcodeUseCase>(barcode);
    locator.registerSingleton<MealDetailBloc>(intakes);
    locator.registerSingleton<SaveRecipeUseCase>(recipes);
    locator.registerSingleton<ComputeRecipeNutritionUseCase>(
        ComputeRecipeNutritionUseCase());
    locator.registerSingleton<HomeBloc>(home);
    locator.registerSingleton<DiaryBloc>(_Diary());
    locator.registerSingleton<CalendarDayBloc>(_Day());
    locator.registerSingleton<RecipesBloc>(_RecipeBloc());
    locator.registerSingleton<CustomMealsBloc>(_CustomBloc());
  });
  tearDown(() async => locator.reset());

  testWidgets('Parse preserves empty and invalid input until it is valid',
      (tester) async {
    SharedMealPayload? parsed;
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
              onPressed: () async {
                parsed = await showDialog<SharedMealPayload>(
                    context: context,
                    builder: (_) => const SharedMealCodeDialog());
              },
              child: const Text('open'),
            ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.sharedMealParseLabel));
    await tester.pump();
    expect(find.text(l10nEn.sharedMealInvalidCodeLabel), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'bad code');
    await tester.tap(find.text(l10nEn.sharedMealParseLabel));
    await tester.pump();
    expect(find.text('bad code'), findsOneWidget);
    expect(parsed, isNull);
    await tester.enterText(find.byType(TextField), payload().toJsonString());
    await tester.tap(find.text(l10nEn.sharedMealParseLabel));
    await tester.pumpAndSettle();
    expect(parsed!.totalCount, 2);
    expect(meals.saved, isEmpty);
    expect(intakes.meals, isEmpty);
  });

  for (final kj in [false, true]) {
    testWidgets('Preview shows amounts, missing energy and total (kJ=$kj)',
        (tester) async {
      await tester.pumpWidget(app(
          SharedMealPreviewDialog(mealType: 'Dinner', items: [
            SharedMealPreviewItem(
                meal: meal('Sardines', unit: 'g'), amount: 90, unit: 'g'),
            SharedMealPreviewItem(
                meal: meal('Unknown energy', kcal: null),
                amount: 3,
                unit: 'pcs'),
            const SharedMealPreviewItem(
                meal: null, amount: 100, unit: 'g', barcode: 'missing'),
          ]),
          kj: kj));
      expect(find.text('90 g'), findsOneWidget);
      expect(find.text('3 g/ml'), findsOneWidget);
      expect(find.text('100 g'), findsOneWidget);
      expect(find.text(kj ? '753 kJ' : '180 kcal'), findsNWidgets(2));
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text(l10nEn.sharedMealPartialTotalLabel), findsOneWidget);
      expect(find.text(l10nEn.sharedMealUnavailableLabel), findsOneWidget);
    });
  }

  testWidgets('A failed lookup marks an otherwise complete total incomplete',
      (tester) async {
    await tester.pumpWidget(
        app(SharedMealPreviewDialog(mealType: 'Dinner', items: [
      SharedMealPreviewItem(meal: meal('Sardines'), amount: 90, unit: 'g'),
      const SharedMealPreviewItem(
          meal: null, amount: 100, unit: 'g', barcode: 'missing'),
    ])));
    expect(find.text(l10nEn.sharedMealPartialTotalLabel), findsOneWidget);
    expect(find.text(l10nEn.sharedMealTotalLabel), findsNothing);
  });

  for (final imperial in [false, true]) {
    testWidgets('Converted amounts show in the base unit (imperial=$imperial)',
        (tester) async {
      // 4 oz and 2 x 30 g servings are stored as their gram weights.
      await tester.pumpWidget(app(SharedMealPreviewDialog(
          mealType: 'Dinner',
          usesImperialUnits: imperial,
          items: [
            SharedMealPreviewItem(
                meal: meal('Steak', unit: 'g'), amount: 113.398, unit: 'oz'),
            SharedMealPreviewItem(
                meal: meal('Milk', unit: 'ml'),
                amount: 236.588,
                unit: 'fl.oz'),
            SharedMealPreviewItem(
                meal: meal('Crisps', unit: 'g'), amount: 60, unit: 'serving'),
            const SharedMealPreviewItem(
                meal: null, amount: 113.398, unit: 'oz', barcode: 'missing'),
          ])));
      // The unavailable row has no food to convert with, so it stays in g.
      expect(find.text('113.4 g'), findsNWidgets(imperial ? 1 : 2));
      expect(find.text('4 oz'), imperial ? findsOneWidget : findsNothing);
      expect(find.text(imperial ? '8 fl.oz' : '236.59 ml'), findsOneWidget);
      expect(find.text(imperial ? '2.12 oz' : '60 g'), findsOneWidget);
      expect(find.textContaining('serving'), findsNothing);
      expect(find.text('113.4 oz'), findsNothing);
    });
  }

  testWidgets('All unavailable items disable Import', (tester) async {
    await tester.pumpWidget(
        app(const SharedMealPreviewDialog(mealType: 'Dinner', items: [
      SharedMealPreviewItem(
          meal: null, amount: 100, unit: 'g', barcode: 'missing'),
    ])));
    final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, l10nEn.importAction));
    expect(button.onPressed, isNull);
  });

  testWidgets('Long names and large text remain scrollable without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(
        SharedMealPreviewDialog(mealType: 'Dinner', items: [
          for (var i = 0; i < 20; i++)
            SharedMealPreviewItem(
                meal: meal('Very long food name ' * 8), amount: 100, unit: 'g'),
        ]),
        scale: 2));
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  Future<void> start(WidgetTester tester, SharedMealPayload value) async {
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
              onPressed: () => SharedMealImporter(
                      context,
                      IntakeTypeEntity.dinner,
                      AddMealType.dinnerType,
                      DateTime(2026, 1, 1))
                  .importCode(value.toJsonString()),
              child: const Text('start'),
            ))));
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
  }

  testWidgets('Importer previews with the imperial food unit setting',
      (tester) async {
    config.imperial = true;
    await start(
        tester,
        payload(refs: [
          const SharedMealOffRef(barcode: 'ok', amount: 113.398, unit: 'oz')
        ]));
    expect(find.text('4 oz'), findsOneWidget);
  });

  for (final imperial in [false, true]) {
    testWidgets(
        'Pasted custom items keep their base unit (imperial=$imperial)',
        (tester) async {
      SharedMealItem entered(String name, String unit, double amount) =>
          SharedMealItem.fromIntakeEntity(IntakeEntity(
            id: name,
            unit: unit,
            amount: amount,
            type: IntakeTypeEntity.dinner,
            meal: meal(name, unit: unit == 'oz' ? 'g' : 'ml'),
            dateTime: DateTime(2026, 1, 1),
          ));
      config.imperial = imperial;
      await start(
          tester,
          SharedMealPayload(
            version: 2,
            offRefs: const [],
            items: [
              entered('Steak', 'oz', 113.398),
              entered('Milk', 'fl.oz', 236.588),
            ],
            recipes: const [],
          ));
      expect(find.text(imperial ? '4 oz' : '113.4 g'), findsOneWidget);
      expect(find.text(imperial ? '8 fl.oz' : '236.6 ml'), findsOneWidget);
      expect(find.textContaining('g/ml'), findsNothing);
      await tester.tap(find.text(l10nEn.importAction));
      await tester.pumpAndSettle();
      expect(meals.saved.map((m) => m.mealUnit), ['g', 'ml']);
    });
  }

  testWidgets('Cancelling preview saves no meals, recipes or intakes',
      (tester) async {
    await start(
        tester,
        payload(recipes: [
          recipeItem()
        ], refs: [
          const SharedMealOffRef(barcode: 'ok', amount: 50, unit: 'g')
        ]));
    expect(find.text('OFF food'), findsOneWidget);
    expect(barcode.calls, ['ok']);
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();
    expect(meals.saved, isEmpty);
    expect(recipes.saved, isEmpty);
    expect(intakes.meals, isEmpty);
    expect(home.refreshes, 0);
  });

  testWidgets('Import uses prepared OFF data and waits for sequential writes',
      (tester) async {
    intakes.firstWrite = Completer<void>();
    await start(
        tester,
        payload(refs: [
          const SharedMealOffRef(barcode: 'ok', amount: 50, unit: 'g')
        ]));
    await tester.tap(find.text(l10nEn.importAction));
    await tester.pump();
    expect(intakes.meals.length, 1);
    expect(home.refreshes, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    intakes.firstWrite!.complete();
    await tester.pumpAndSettle();
    expect(intakes.meals.map((m) => m.name), ['Sardines', 'Bread', 'OFF food']);
    expect(intakes.amounts, ['90.0', '90.0', '50.0']);
    expect(intakes.units, ['g', 'g', 'g']);
    expect(meals.saved.length, 2);
    expect(barcode.calls, ['ok']);
    expect(home.refreshes, 1);
  });

  testWidgets('Repeated preparation opens one preview and performs no writes',
      (tester) async {
    Future<bool>? first;
    bool? duplicate;
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
              onPressed: () async {
                final importer = SharedMealImporter(
                    context,
                    IntakeTypeEntity.dinner,
                    AddMealType.dinnerType,
                    DateTime(2026, 1, 1));
                first = importer.importPayload(payload());
                duplicate = await importer.importPayload(payload());
              },
              child: const Text('start'),
            ))));
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    expect(duplicate, false);
    expect(find.byType(SharedMealPreviewDialog), findsOneWidget);
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();
    expect(await first, false);
    expect(intakes.meals, isEmpty);
  });

  testWidgets('Failed OFF lookup is previewed and skipped at import',
      (tester) async {
    await tester.pumpWidget(app(Builder(
        builder: (context) => TextButton(
              onPressed: () => SharedMealImporter(
                      context,
                      IntakeTypeEntity.dinner,
                      AddMealType.dinnerType,
                      DateTime(2026, 1, 1))
                  .importPayload(payload(refs: [
                const SharedMealOffRef(
                    barcode: 'missing', amount: 50, unit: 'g'),
              ])),
              child: const Text('start'),
            ))));
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    expect(find.text('missing'), findsOneWidget);
    expect(find.text(l10nEn.sharedMealUnavailableLabel), findsOneWidget);
    await tester.tap(find.text(l10nEn.importAction));
    await tester.pumpAndSettle();
    expect(intakes.meals.length, 2);
    // OFFDataSource retries on its own; the importer asks only once.
    expect(barcode.calls, ['missing']);
  });

  for (final viaBack in [true, false]) {
    testWidgets(
        'A stalled lookup can be cancelled and imports nothing '
        '(${viaBack ? 'Back' : 'Cancel'})', (tester) async {
      Future<bool>? result;
      await tester.pumpWidget(app(Builder(
          builder: (context) => TextButton(
                onPressed: () => result = SharedMealImporter(
                        context,
                        IntakeTypeEntity.dinner,
                        AddMealType.dinnerType,
                        DateTime(2026, 1, 1))
                    .importPayload(payload(refs: [
                  const SharedMealOffRef(
                      barcode: 'stall', amount: 50, unit: 'g'),
                ])),
                child: const Text('start'),
              ))));
      await tester.tap(find.text('start'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (viaBack) {
        await tester.binding.handlePopRoute();
      } else {
        // Let the dialog finish opening so its semantics are published.
        await tester.pump(const Duration(seconds: 1));
        await tester
            .tap(find.bySemanticsIdentifier('import-meal-prepare-cancel'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SharedMealPreviewDialog), findsNothing);
      expect(await result, false);
      expect(barcode.calls, ['stall']);
      expect(meals.saved, isEmpty);
      expect(recipes.saved, isEmpty);
      expect(intakes.meals, isEmpty);
      expect(home.refreshes, 0);
    });
  }

  testWidgets(
      'Recipe preview matches computed nutrition and is saved only on Import',
      (tester) async {
    await start(tester, payload(recipes: [recipeItem()]));
    expect(find.text('Recipe'), findsOneWidget);
    expect(find.text('100 kcal'), findsOneWidget);
    expect(recipes.saved, isEmpty);
    await tester.tap(find.text(l10nEn.importAction));
    await tester.pumpAndSettle();
    expect(recipes.saved.length, 1);
    expect(recipes.overridden, [false]);
    expect(intakes.meals.last.nutriments.energyKcal100, 200);
  });

  testWidgets(
      'An embedded recipe keeps its hand-entered total weight through '
      'preview and save (#1194)', (tester) async {
    // 100 g of ingredients cooked down to 80 g: 200 kcal over 80 g.
    await start(tester, payload(recipes: [recipeItem(totalWeightG: 80)]));
    expect(find.text('125 kcal'), findsOneWidget);
    await tester.tap(find.text(l10nEn.importAction));
    await tester.pumpAndSettle();
    expect(recipes.overridden, [true]);
    expect(recipes.saved.single.totalWeightG, 80);
    expect(intakes.meals.last.nutriments.energyKcal100, 250);
  });
}
