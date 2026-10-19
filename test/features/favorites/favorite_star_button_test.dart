import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/favorites/presentation/favorite_star_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/fake_favorites_usecase.dart';
import '../../helpers/test_l10n.dart';

final _meal = MealEntity(
  code: '4002971234567',
  name: 'Skyr',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

final _recipe = RecipeEntity(
  id: 'r1',
  name: 'Overnight oats',
  description: null,
  ingredients: const [],
  totalWeightG: 400,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: 2,
);

void main() {
  Future<void> pump(WidgetTester tester, Widget button) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(appBar: AppBar(actions: [button])),
    ),
  );

  testWidgets('the meal star toggles and shows the state at once', (
    tester,
  ) async {
    final favorites = FakeFavoritesUsecase();
    await pump(tester, FavoriteStarButton.meal(_meal, usecase: favorites));

    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('meal-detail-favorite'));
    await tester.pumpAndSettle();

    expect(favorites.isMealFavorite(_meal), isTrue);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text(l10nEn.favoriteAddedLabel), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('meal-detail-favorite'));
    await tester.pumpAndSettle();

    expect(favorites.isMealFavorite(_meal), isFalse);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('a stored favourite shows filled, e.g. after a restart', (
    tester,
  ) async {
    final favorites = FakeFavoritesUsecase()..ids.add('recipe:r1');
    await pump(tester, FavoriteStarButton.recipe(_recipe, usecase: favorites));

    expect(find.bySemanticsIdentifier('recipe-detail-favorite'), findsOne);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byTooltip(l10nEn.favoriteRemoveTooltip), findsOneWidget);
  });

  testWidgets('a change made elsewhere updates the star', (tester) async {
    final favorites = FakeFavoritesUsecase();
    await pump(tester, FavoriteStarButton.recipe(_recipe, usecase: favorites));

    await favorites.toggleRecipe(_recipe);
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('a failed save says so and keeps the star', (tester) async {
    final favorites = FakeFavoritesUsecase()..toggleError = StateError('disk');
    await pump(tester, FavoriteStarButton.meal(_meal, usecase: favorites));

    await tester.tap(find.bySemanticsIdentifier('meal-detail-favorite'));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.favoriteToggleFailed), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });
}
