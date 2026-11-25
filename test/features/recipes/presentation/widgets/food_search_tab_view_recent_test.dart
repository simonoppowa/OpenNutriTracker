import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recent_ingredients_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_ingredient_recent_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/food_search_tab_view.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeRecentIngredients implements GetRecentIngredientsUsecase {
  final List<MealEntity> meals;
  int reads = 0;
  bool fail = false;

  _FakeRecentIngredients(this.meals);

  @override
  Future<List<MealEntity>> getRecentIngredients() async {
    reads++;
    if (fail) throw StateError('storage unavailable');
    return meals;
  }
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeSearch implements SearchProductsUseCase {
  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: true);

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: true);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String name) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.custom,
);

final getIt = GetIt.instance;

/// A picker card spells the name and brand as one rich text.
Finder _card(String name) => find.textContaining(name, findRichText: true);

Future<_FakeRecentIngredients> _register(List<MealEntity> recent) async {
  await getIt.reset();
  final config = _FakeGetConfigUsecase();
  final search = _FakeSearch();
  final ingredients = _FakeRecentIngredients(recent);
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(search, config));
  getIt.registerFactory<RecipeIngredientRecentBloc>(
    () => RecipeIngredientRecentBloc(ingredients, config),
  );
  return ingredients;
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  void Function(MealEntity meal)? onMealSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: FoodSearchTabView(onMealSelected: onMealSelected ?? (_) {}),
      ),
    ),
  );
  await tester.tap(find.text(l10nEn.recentlyAddedLabel));
  await tester.pumpAndSettle();
}

/// #516: the ingredient picker's Recent tab offers the foods the saved
/// recipes use, not only the ones that were logged.
void main() {
  tearDown(() => getIt.reset());

  testWidgets('the Recent tab lists recipe ingredients and picks one', (
    tester,
  ) async {
    await _register([_meal('Protein powder XYZ'), _meal('Oats')]);
    MealEntity? picked;

    await _pumpPicker(tester, onMealSelected: (meal) => picked = meal);

    expect(_card('Protein powder XYZ'), findsOneWidget);
    expect(_card('Oats'), findsOneWidget);

    await tester.tap(_card('Protein powder XYZ'));
    expect(picked?.name, 'Protein powder XYZ');
  });

  testWidgets('a submitted search filters the Recent tab', (tester) async {
    await _register([_meal('Protein powder XYZ'), _meal('Oats')]);
    await _pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'prot');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(_card('Protein powder XYZ'), findsOneWidget);
    expect(_card('Oats'), findsNothing);
  });

  testWidgets('with nothing used yet, the Recent tab shows the empty state', (
    tester,
  ) async {
    await _register(const []);

    await _pumpPicker(tester);

    expect(find.text(l10nEn.noResultsFound), findsOneWidget);
  });

  testWidgets('a failed read shows the error and Retry loads again', (
    tester,
  ) async {
    final ingredients = await _register([_meal('Oats')]);
    ingredients.fail = true;

    await _pumpPicker(tester);
    expect(find.text(l10nEn.noMealsRecentlyAddedLabel), findsOneWidget);

    ingredients.fail = false;
    await tester.tap(find.text(l10nEn.retryLabel));
    await tester.pumpAndSettle();

    expect(_card('Oats'), findsOneWidget);
  });
}
