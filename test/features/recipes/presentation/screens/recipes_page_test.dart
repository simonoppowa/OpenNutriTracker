import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipes_page.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class _LoadedRecipes extends Fake implements RecipesBloc {
  @override
  final RecipesState state;

  _LoadedRecipes(this.state);

  @override
  Stream<RecipesState> get stream => const Stream.empty();

  @override
  void add(RecipesEvent event) {}
}

class _NoCustomMeals extends Fake implements CustomMealsBloc {
  @override
  CustomMealsState get state => CustomMealsLoadedState(meals: const []);

  @override
  Stream<CustomMealsState> get stream => const Stream.empty();

  @override
  void add(CustomMealsEvent event) {}
}

class _Config extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

RecipeEntity _recipe(int i) => RecipeEntity(
  id: 'recipe-$i',
  name: 'Recipe $i',
  description: null,
  ingredients: const [],
  totalWeightG: 100,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  servingsCount: null,
);

void main() {
  final locator = GetIt.instance;

  tearDown(() async => locator.reset());

  // Edge-to-edge draws the navigation bar over the list; its end clears
  // the bar so the last recipe can be scrolled into reach.
  testWidgets('the recipe list ends above the navigation bar', (tester) async {
    // As a device reports a 48 dp bar, at 3x.
    tester.view.padding = const FakeViewPadding(bottom: 144);
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);
    final navigationBar = 144 / tester.view.devicePixelRatio;

    locator
      ..registerSingleton<RecipesBloc>(
        _LoadedRecipes(RecipesLoaded([for (var i = 0; i < 3; i++) _recipe(i)])),
      )
      ..registerSingleton<CustomMealsBloc>(_NoCustomMeals())
      ..registerSingleton<GetConfigUsecase>(_Config());

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: const MaterialApp(
          localizationsDelegates: [S.delegate],
          supportedLocales: S.supportedLocales,
          home: RecipesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.vertical,
    );
    final padding = tester.widget<ListView>(list).padding!;
    expect(
      padding.resolve(TextDirection.ltr).bottom,
      greaterThanOrEqualTo(navigationBar),
    );
  });
}
