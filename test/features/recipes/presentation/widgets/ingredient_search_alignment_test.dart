// #1283: the recipe ingredient picker searches the way the add-food screen
// does — same source chips, same merged and ranked All list, same result
// row — while a pick still hands the food back to the recipe instead of
// logging it.
//
// Both screens run on the real SearchProductsUseCase and the real search
// blocs; only the repository, the local data sources and the config are
// faked, so the same fake answers both.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/empty_hint.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/partial_results_notice.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_builder_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/food_search_tab_view.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_list_item.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_favourites.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeProductsRepository implements ProductsRepository {
  bool offThrows = false;
  bool fdcThrows = false;
  List<MealEntity> offResults = const [];
  List<MealEntity> fdcResults = const [];

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    if (offThrows) throw Exception('OFF offline');
    return offResults;
  }

  @override
  Future<List<MealEntity>> getSupabaseFoodsByString(
    String searchString, {
    bool forResolution = false,
  }) async {
    if (fdcThrows) throw Exception('Supabase offline');
    return fdcResults;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  List<IntakeEntity> recent = const [];

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => recent;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  final List<MealDBO> meals = [];

  @override
  List<MealDBO> getAllCustomMeals() => meals;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRecipeDataSource implements RecipeDataSource {
  final List<RecipeDBO> recipes = [];

  @override
  List<RecipeDBO> getAllRecipes() => recipes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> cacheFromSearch(Iterable<MealDBO> meals) async {}

  @override
  List<MealDBO> getAllByMostRecentlyTouched() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRecipeRepository implements RecipeRepository {
  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String name, MealSourceEntity source) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: source,
);

RecipeEntity _recipe(String id, String name) => RecipeEntity(
  id: id,
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 500,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  servingsCount: null,
);

final getIt = GetIt.instance;

late _FakeProductsRepository _repository;
late _FakeCustomMealDataSource _customMeals;
late _FakeRecipeDataSource _recipes;
late _FakeGetIntakeUsecase _intakes;
FakeFavourites? _favourites;

Future<void> _register() async {
  await getIt.reset();
  _repository = _FakeProductsRepository();
  _customMeals = _FakeCustomMealDataSource();
  _recipes = _FakeRecipeDataSource();
  _intakes = _FakeGetIntakeUsecase();
  final config = _FakeGetConfigUsecase();
  final useCase = SearchProductsUseCase(
    _repository,
    _intakes,
    _customMeals,
    _FakeRemoteSearchCacheDataSource(),
    _recipes,
    config,
  );
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(useCase, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(useCase, config));
  getIt.registerFactory<RecentMealBloc>(() => RecentMealBloc(_intakes, config));
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
  final compute = ComputeRecipeNutritionUseCase();
  getIt.registerFactory<RecipeBuilderBloc>(
    () => RecipeBuilderBloc(
      compute,
      SaveRecipeUseCase(_FakeRecipeRepository(), compute),
    ),
  );
}

/// Every named route either screen pushed. A pick must push none: the
/// meal-detail route is where logging an intake starts.
final _pushedRoutes = <String?>[];

Widget _localized({
  required Widget Function(BuildContext) home,
  Object? arguments,
  double textScale = 1,
}) => ChangeNotifierProvider<EnergyUnitProvider>(
  create: (_) => EnergyUnitProvider(),
  child: MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    onGenerateRoute: (settings) {
      if (settings.name != '/') {
        _pushedRoutes.add(settings.name);
        return MaterialPageRoute<Object?>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('pushed')),
        );
      }
      return MaterialPageRoute<void>(
        settings: RouteSettings(name: settings.name, arguments: arguments),
        builder: home,
      );
    },
  ),
);

enum _Screen { addMeal, ingredientPicker }

final _picked = <MealEntity>[];

Widget _app(_Screen screen, {String? excludedRecipeId, double textScale = 1}) =>
    switch (screen) {
      _Screen.addMeal => _localized(
        arguments: AddMealScreenArguments(
          AddMealType.lunchType,
          DateTime(2026, 10, 1),
        ),
        home: (_) => const AddMealScreen(),
      ),
      _Screen.ingredientPicker => _localized(
        textScale: textScale,
        home: (_) => Scaffold(
          body: FoodSearchTabView(
            onMealSelected: _picked.add,
            onBarcodePressed: () {},
            excludedRecipeId: excludedRecipeId,
          ),
        ),
      ),
    };

/// A tall view, so the lazily built result lists build every row.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Types and submits [query] in the screen's search field.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  // Let the keystroke's debounced search fire too, so no timer outlives
  // the test; it finds the submitted query already answered.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The names of the result rows, top to bottom.
List<String?> _rowNames(WidgetTester tester) => tester
    .widgetList<MealItemCard>(find.byType(MealItemCard))
    .map((card) => card.mealEntity.name)
    .toList();

void main() {
  setUp(() async {
    _pushedRoutes.clear();
    _picked.clear();
    await _register();
  });

  tearDown(() async => getIt.reset());

  void seedAppleSearch() {
    _customMeals.meals.add(
      MealDBO.fromMealEntity(_meal('Apple pie', MealSourceEntity.custom)),
    );
    _repository
      ..offResults = [
        _meal('Sparkling drink with apple flavour', MealSourceEntity.off),
        _meal('Apple', MealSourceEntity.off),
      ]
      ..fdcResults = [
        _meal('Apples, dried, sulfured', MealSourceEntity.fdc),
        _meal('Apple, raw', MealSourceEntity.fdc),
      ];
  }

  group('the same query lists the same rows in the same order', () {
    testWidgets('add-food All list and the ingredient picker agree', (
      tester,
    ) async {
      _tallView(tester);
      seedAppleSearch();

      await _open(tester, _app(_Screen.addMeal));
      await _search(tester, 'apple');
      final addMealRows = _rowNames(tester);

      await _register();
      seedAppleSearch();
      await _open(tester, _app(_Screen.ingredientPicker));
      await _search(tester, 'apple');
      final pickerRows = _rowNames(tester);

      expect(pickerRows, addMealRows);
      // Ranked, not each source's page one after the other: the user's own
      // food first, and the best name match across both sources next.
      expect(pickerRows, [
        'Apple pie',
        ...mergeAndRankMeals(
          [..._repository.offResults],
          [..._repository.fdcResults],
          'apple',
        ).map((meal) => meal.name),
      ]);
      expect(
        pickerRows,
        isNot([
          'Apple pie',
          ..._repository.offResults.map((meal) => meal.name),
          ..._repository.fdcResults.map((meal) => meal.name),
        ]),
        reason: 'ranked across sources, not one page after the other',
      );
    });

    testWidgets('the picker opens on Recent, as add-food does', (tester) async {
      _intakes.recent = [
        IntakeEntity(
          id: 'i1',
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.lunch,
          meal: _meal('Oat milk', MealSourceEntity.off),
          dateTime: DateTime(2026, 10, 1, 12),
        ),
      ];

      await _open(tester, _app(_Screen.ingredientPicker));

      expect(_rowNames(tester), ['Oat milk']);
      for (final label in [
        l10nEn.recentlyAddedLabel,
        l10nEn.favouritesLabel,
        l10nEn.allItemsLabel,
        l10nEn.searchProductsPage,
        l10nEn.searchFoodPage,
      ]) {
        expect(
          find.widgetWithText(ChoiceChip, label),
          findsOneWidget,
          reason: '$label chip',
        );
      }
      expect(find.byType(TabBar), findsNothing);
    });
  });

  group('picking an ingredient', () {
    testWidgets('a tap on the row hands the food back and opens nothing', (
      tester,
    ) async {
      _tallView(tester);
      seedAppleSearch();
      await _open(tester, _app(_Screen.ingredientPicker));
      await _search(tester, 'apple');

      await tester.tap(find.textContaining('Apple, raw', findRichText: true));
      await tester.pumpAndSettle();

      expect(_picked.map((m) => m.name), ['Apple, raw']);
      expect(_pushedRoutes, isEmpty);
    });

    testWidgets('the row\'s + hands the food back too', (tester) async {
      _tallView(tester);
      seedAppleSearch();
      await _open(tester, _app(_Screen.ingredientPicker));
      await _search(tester, 'apple');

      await tester.tap(find.bySemanticsIdentifier('meal-item-add').first);
      await tester.pumpAndSettle();

      expect(_picked.map((m) => m.name), ['Apple pie']);
      expect(_pushedRoutes, isEmpty);
    });

    testWidgets(
      'in the recipe builder a pick adds an ingredient and logs nothing',
      (tester) async {
        _tallView(tester);
        seedAppleSearch();
        await _open(
          tester,
          _localized(
            arguments: const RecipeBuilderArguments(),
            home: (_) => const RecipeBuilderScreen(),
          ),
        );

        await tester.tap(find.text(l10nEn.recipeAddIngredientLabel));
        await tester.pumpAndSettle();
        await _search(tester, 'apple');
        await tester.tap(find.textContaining('Apple, raw', findRichText: true));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          ),
          '150',
        );
        await tester.tap(find.text(l10nEn.addLabel));
        await tester.pumpAndSettle();

        expect(find.byType(FoodSearchTabView), findsNothing);
        expect(find.byType(IngredientListItem), findsOneWidget);
        expect(
          find.textContaining('Apple, raw', findRichText: true),
          findsWidgets,
        );
        // No route toward meal detail (where an intake is logged) opened,
        // and nothing that logs one is registered for this test.
        expect(_pushedRoutes, isEmpty);
      },
    );
  });

  group('a recipe is not offered as an ingredient of itself', () {
    setUp(() {
      _recipes.recipes.addAll([
        _recipe('r1', 'Pancakes').toDBO(),
        _recipe('r2', 'Pancake batter').toDBO(),
      ]);
    });

    testWidgets('All and Products leave the edited recipe out', (tester) async {
      _tallView(tester);
      await _open(
        tester,
        _app(_Screen.ingredientPicker, excludedRecipeId: 'r1'),
      );
      await _search(tester, 'pancake');
      expect(_rowNames(tester), ['Pancake batter']);

      await tester.tap(
        find.widgetWithText(ChoiceChip, l10nEn.searchProductsPage),
      );
      await tester.pumpAndSettle();
      expect(_rowNames(tester), ['Pancake batter']);
    });

    testWidgets('Recent leaves out a logged copy of the edited recipe', (
      tester,
    ) async {
      _intakes.recent = [
        IntakeEntity(
          id: 'i1',
          unit: 'g',
          amount: 100,
          type: IntakeTypeEntity.dinner,
          meal: _recipe('r1', 'Pancakes').toMealEntity(),
          dateTime: DateTime(2026, 10, 1, 19),
        ),
      ];
      await _open(
        tester,
        _app(_Screen.ingredientPicker, excludedRecipeId: 'r1'),
      );

      expect(_rowNames(tester), isEmpty);
    });

    testWidgets('another recipe, or no edited recipe, is still offered', (
      tester,
    ) async {
      _tallView(tester);
      await _open(tester, _app(_Screen.ingredientPicker));
      await _search(tester, 'pancake');

      expect(
        _rowNames(tester),
        unorderedEquals(['Pancakes', 'Pancake batter']),
      );
    });

    testWidgets('the recipe builder passes the recipe it edits', (
      tester,
    ) async {
      _tallView(tester);
      await _open(
        tester,
        _localized(
          arguments: RecipeBuilderArguments(
            existing: _recipe('r1', 'Pancakes'),
          ),
          home: (_) => const RecipeBuilderScreen(),
        ),
      );

      await tester.tap(find.text(l10nEn.recipeAddIngredientLabel));
      await tester.pumpAndSettle();
      await _search(tester, 'pancake');

      expect(_rowNames(tester), ['Pancake batter']);
    });
  });

  for (final screen in _Screen.values) {
    group('${screen.name}: empty, error and offline states', () {
      testWidgets('no history yet: the empty Recent hint', (tester) async {
        await _open(tester, _app(screen));

        expect(find.byType(EmptyHint), findsOneWidget);
        expect(find.text(l10nEn.noMealsRecentlyAddedLabel), findsOneWidget);
      });

      testWidgets('nothing matches: no results, with a scan action', (
        tester,
      ) async {
        await _open(tester, _app(screen));
        await _search(tester, 'zzzz');

        expect(find.byType(NoResultsWidget), findsOneWidget);
        expect(
          find.bySemanticsIdentifier('search-no-results-scan-barcode'),
          findsOneWidget,
        );
      });

      testWidgets('both sources down, nothing saved: the error and Retry', (
        tester,
      ) async {
        _repository
          ..offThrows = true
          ..fdcThrows = true;
        await _open(tester, _app(screen));
        await _search(tester, 'apple');

        expect(find.byType(ErrorDialog), findsOneWidget);
        expect(find.text(l10nEn.errorFetchingProductData), findsOneWidget);

        _repository
          ..offThrows = false
          ..fdcThrows = false
          ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
        await tester.tap(find.bySemanticsIdentifier('search-all-retry'));
        await tester.pumpAndSettle();

        expect(_rowNames(tester), ['Apple, raw']);
      });

      testWidgets('offline with a saved match: the row and a notice', (
        tester,
      ) async {
        _customMeals.meals.add(
          MealDBO.fromMealEntity(_meal('Apple pie', MealSourceEntity.custom)),
        );
        _repository
          ..offThrows = true
          ..fdcThrows = true;
        await _open(tester, _app(screen));
        await _search(tester, 'apple');

        expect(_rowNames(tester), ['Apple pie']);
        expect(
          find.text(l10nEn.partialResultsAllSourcesDownNotice),
          findsOneWidget,
        );
      });

      testWidgets('one source down: its rows and the partial notice', (
        tester,
      ) async {
        _repository
          ..offThrows = true
          ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
        await _open(tester, _app(screen));
        await _search(tester, 'apple');

        expect(_rowNames(tester), ['Apple, raw']);
        expect(find.byType(PartialResultsNotice), findsOneWidget);
        expect(find.text(l10nEn.partialResultsNotice), findsOneWidget);
      });
    });
  }

  testWidgets('the picker fits a phone at text scale 2.0', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    _repository.fdcResults = [
      _meal(
        'Apple, raw, with skin, Fuji variety, organically grown',
        MealSourceEntity.fdc,
      ),
    ];

    await _open(tester, _app(_Screen.ingredientPicker, textScale: 2));
    expect(tester.takeException(), isNull);
    await _search(tester, 'apple');

    expect(tester.takeException(), isNull);
    expect(find.byType(MealItemCard), findsOneWidget);
  });
}
