import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
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

MealEntity meal(String name, {double? kcal = 200}) => MealEntity(
      code: name,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: null,
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

SharedMealRecipeItem recipeItem() {
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
    totalWeightG: 100,
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
    return meal('OFF food');
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

class _Recipes extends Fake implements SaveRecipeUseCase {
  final saved = <RecipeEntity>[];
  @override
  Future<RecipeEntity> save(RecipeEntity recipe,
      {bool totalWeightOverridden = false}) async {
    saved.add(recipe);
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
  setUp(() {
    meals = _Meals();
    barcode = _Barcode();
    intakes = _Intakes();
    recipes = _Recipes();
    home = _Home();
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
                meal: meal('Sardines'), amount: 90, unit: 'g'),
            SharedMealPreviewItem(
                meal: meal('Unknown energy', kcal: null),
                amount: 3,
                unit: 'pcs'),
            const SharedMealPreviewItem(
                meal: null, amount: 100, unit: 'g', barcode: 'missing'),
          ]),
          kj: kj));
      expect(find.text('90 g'), findsOneWidget);
      expect(find.text('3 pcs'), findsOneWidget);
      expect(find.text(kj ? '753 kJ' : '180 kcal'), findsNWidgets(2));
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text(l10nEn.sharedMealPartialTotalLabel), findsOneWidget);
      expect(find.text(l10nEn.sharedMealUnavailableLabel), findsOneWidget);
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
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('missing'), findsOneWidget);
    expect(find.text(l10nEn.sharedMealUnavailableLabel), findsOneWidget);
    await tester.tap(find.text(l10nEn.importAction));
    await tester.pumpAndSettle();
    expect(intakes.meals.length, 2);
    expect(barcode.calls.length, 3);
  });

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
    expect(intakes.meals.last.nutriments.energyKcal100, 200);
  });
}
