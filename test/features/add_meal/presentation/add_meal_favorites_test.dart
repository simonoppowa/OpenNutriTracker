import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/favorites/domain/favorites_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favorites_usecase.dart';
import '../../../helpers/test_l10n.dart';

MealEntity _meal(String code, String name) => MealEntity(
  code: code,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 63,
    carbohydrates100: 4,
    fat100: 0.2,
    proteins100: 11,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.off,
);

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

class _FakeGetIntakeUsecase extends Fake implements GetIntakeUsecase {
  final List<IntakeEntity> recent;

  _FakeGetIntakeUsecase(this.recent);

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => recent;
}

class _UnusedSearch extends Fake implements SearchProductsUseCase {}

class _FakeCacheManager extends Fake implements CacheManager {}

void main() {
  final getIt = GetIt.instance;
  late FakeFavoritesUsecase favorites;
  final skyr = _meal('skyr', 'Skyr natur');
  final oats = _meal('oats', 'Haferflocken');

  setUp(() {
    favorites = FakeFavoritesUsecase();
    getIt
      ..registerSingleton<FavoritesUsecase>(favorites)
      ..registerFactory(() => AddMealBloc(_FakeGetConfigUsecase()))
      ..registerFactory(
        () => ProductsBloc(_UnusedSearch(), _FakeGetConfigUsecase()),
      )
      ..registerFactory(
        () => FoodBloc(_UnusedSearch(), _FakeGetConfigUsecase()),
      )
      ..registerFactory(
        () => RecentMealBloc(
          _FakeGetIntakeUsecase([
            IntakeEntity(
              id: 'i1',
              unit: 'g',
              amount: 150,
              type: IntakeTypeEntity.breakfast,
              meal: oats,
              dateTime: DateTime(2026, 10, 19, 8),
            ),
          ]),
          _FakeGetConfigUsecase(),
        ),
      )
      ..registerSingleton<CacheManager>(_FakeCacheManager());
  });

  tearDown(() => getIt.reset());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: false),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: RouteSettings(
              arguments: AddMealScreenArguments(
                AddMealType.breakfastType,
                DateTime(2026, 10, 19),
              ),
            ),
            builder: (_) => const AddMealScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the favourites chip lists the favourites', (tester) async {
    favorites.meals.addAll([skyr, oats]);
    favorites.ids.addAll(['meal:off:skyr', 'meal:off:oats']);
    await pumpScreen(tester);

    await tester.tap(find.text(l10nEn.favoritesLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('Skyr natur'), findsOneWidget);
    expect(find.textContaining('Haferflocken'), findsOneWidget);
    expect(find.bySemanticsIdentifier('meal-item-favorite'), findsNWidgets(2));
  });

  testWidgets('typing filters the favourites', (tester) async {
    favorites.meals.addAll([skyr, oats]);
    await pumpScreen(tester);
    await tester.tap(find.text(l10nEn.favoritesLabel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sky');
    await tester.pumpAndSettle();

    expect(find.textContaining('Skyr natur'), findsOneWidget);
    expect(find.textContaining('Haferflocken'), findsNothing);
  });

  testWidgets('without favourites a hint explains the star', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10nEn.favoritesLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.favoritesEmptyTitle), findsOneWidget);
    expect(find.text(l10nEn.favoritesEmptySubtitle), findsOneWidget);
  });

  testWidgets('the recent list shows the star on favourites', (tester) async {
    favorites.ids.add('meal:off:oats');
    await pumpScreen(tester);

    expect(find.textContaining('Haferflocken'), findsOneWidget);
    expect(find.bySemanticsIdentifier('meal-item-favorite'), findsOneWidget);
  });
}
