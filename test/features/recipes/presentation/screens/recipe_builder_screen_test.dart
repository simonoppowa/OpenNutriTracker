import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_builder_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeRecipeRepository implements RecipeRepository {
  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

RecipeEntity _soup({required double totalWeightG}) {
  return RecipeEntity(
    id: 'soup-1',
    name: 'Soup',
    description: null,
    ingredients: [
      RecipeIngredientEntity(
        snapshotMeal: MealEntity(
          code: 'stock',
          name: 'stock',
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: null,
          servingSize: null,
          nutriments: MealNutrimentsEntity(
            energyKcal100: 90,
            carbohydrates100: null,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
          source: MealSourceEntity.off,
        ),
        amount: 800,
        unit: 'g',
        convertedAmountG: 800,
      ),
    ],
    totalWeightG: totalWeightG,
    aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
    servingsCount: null,
  );
}

Widget _app(RecipeEntity? existing) {
  return ChangeNotifierProvider<EnergyUnitProvider>(
    create: (_) => EnergyUnitProvider(),
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: RouteSettings(
          arguments: RecipeBuilderArguments(existing: existing),
        ),
        builder: (_) => const RecipeBuilderScreen(),
      ),
    ),
  );
}

/// The total-weight field's two states (#1277, PR #1280 review): a weight
/// typed in by hand has to say so, and has to have a way back to the sum.
void main() {
  setUpAll(() {
    final compute = ComputeRecipeNutritionUseCase();
    GetIt.instance.registerFactory<RecipeBuilderBloc>(
      () => RecipeBuilderBloc(
        compute,
        SaveRecipeUseCase(_FakeRecipeRepository(), compute),
      ),
    );
  });

  tearDownAll(() => GetIt.instance.reset());

  Finder reset() => find.bySemanticsIdentifier('recipe-builder-weight-reset');

  /// The weight field sits below the fold of a lazily built list, so on the
  /// default test screen it is never built at all. A tall view builds the
  /// whole form.
  Future<void> pumpBuilder(WidgetTester tester, RecipeEntity existing) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(existing));
    await tester.pumpAndSettle();
  }

  Finder weightField() => find.widgetWithText(
        TextField,
        l10nEn.recipeTotalWeightLabel,
      );

  testWidgets('a typed weight says so, and Use ingredient total undoes it', (
    tester,
  ) async {
    await pumpBuilder(tester, _soup(totalWeightG: 720));

    expect(find.text(l10nEn.recipeTotalWeightManualHelper), findsOneWidget);
    expect(
      tester.widget<TextField>(weightField()).controller!.text,
      '720',
    );

    await tester.ensureVisible(reset());
    await tester.tap(reset());
    await tester.pumpAndSettle();

    expect(
      find.text(l10nEn.recipeTotalWeightCalculatedHelper),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(weightField()).controller!.text,
      '800',
    );
    expect(reset(), findsNothing, reason: 'nothing left to undo');
  });

  testWidgets('a calculated weight says so, with nothing to undo', (
    tester,
  ) async {
    await pumpBuilder(tester, _soup(totalWeightG: 800));

    expect(
      find.text(l10nEn.recipeTotalWeightCalculatedHelper),
      findsOneWidget,
    );
    expect(reset(), findsNothing);
  });

  testWidgets('typing a weight switches the field to entered manually', (
    tester,
  ) async {
    await pumpBuilder(tester, _soup(totalWeightG: 800));

    await tester.ensureVisible(weightField());
    await tester.enterText(weightField(), '650');
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.recipeTotalWeightManualHelper), findsOneWidget);
    expect(reset(), findsOneWidget);
  });
}
