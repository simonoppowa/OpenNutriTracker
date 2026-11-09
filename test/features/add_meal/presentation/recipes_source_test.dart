import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_all_recipes_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
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
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_meal_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

/// #1284: the add-food screen's Recipes source lists the user's saved
/// recipes without a search, so a recipe whose name they forgot is a tap
/// away.

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _NoRecentIntake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The Recipes source never reaches the remote search.
class _UnusedSearch implements SearchProductsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The recipe library in memory, firing [watch] on every change the way
/// the Hive box does.
class _FakeRecipes implements GetAllRecipesUseCase {
  final recipes = <RecipeEntity>[];
  Object? readError;
  final _changes = StreamController<void>.broadcast();

  @override
  List<RecipeEntity> getAll() {
    final error = readError;
    if (error != null) throw error;
    return List.of(recipes);
  }

  @override
  Stream<void> watch() => _changes.stream;

  void delete(String id) {
    recipes.removeWhere((r) => r.id == id);
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {
  final writes = <({String unit, String amount, MealEntity meal})>[];

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity intakeTypeEntity,
    MealEntity meal,
    DateTime day,
  ) async {
    writes.add((unit: unit, amount: amountText, meal: meal));
  }
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

RecipeEntity _recipe(
  String id,
  String name, {
  int? servingsCount,
  String? imagePath,
}) => RecipeEntity(
  id: id,
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 400,
  aggregatedNutrimentsPer100: const MealNutrimentsEntity(
    energyKcal100: 150,
    carbohydrates100: 20,
    fat100: 5,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: servingsCount,
  imagePath: imagePath,
);

Widget _app(List<RouteSettings> pushed) => ChangeNotifierProvider(
  create: (_) => EnergyUnitProvider(usesKilojoules: false),
  child: MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    initialRoute: NavigationOptions.mainRoute,
    onGenerateRoute: (settings) {
      if (settings.name == NavigationOptions.mainRoute) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(key: Key('main'), body: SizedBox()),
        );
      }
      if (settings.name == NavigationOptions.addMealRoute) {
        return MaterialPageRoute<void>(
          settings: RouteSettings(
            name: settings.name,
            arguments: AddMealScreenArguments(
              AddMealType.dinnerType,
              DateTime(2026, 11, 9),
            ),
          ),
          builder: (_) => const AddMealScreen(),
        );
      }
      pushed.add(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: SizedBox()),
      );
    },
  ),
);

Finder _chip() => find.bySemanticsIdentifier('add-meal-source-recipes');
Finder _list() => find.bySemanticsIdentifier('add-meal-recipes-list');
Finder _row(String name) => find.textContaining(name, findRichText: true);
Finder _logButton() => find.bySemanticsIdentifier('add-meal-tray-log');

void main() {
  final getIt = GetIt.instance;
  late _FakeRecipes recipes;
  late FakeFavourites favourites;
  late _FakeMealDetailBloc mealDetailBloc;

  setUp(() {
    recipes = _FakeRecipes();
    favourites = FakeFavourites();
    mealDetailBloc = _FakeMealDetailBloc();
    final config = _FakeGetConfigUsecase();
    getIt
      ..registerFactory<AddMealBloc>(() => AddMealBloc(config))
      ..registerFactory<ProductsBloc>(
        () => ProductsBloc(_UnusedSearch(), config),
      )
      ..registerFactory<FoodBloc>(() => FoodBloc(_UnusedSearch(), config))
      ..registerFactory<RecentMealBloc>(
        () => RecentMealBloc(_NoRecentIntake(), config),
      )
      ..registerFactory<FavouriteMealBloc>(
        () => FavouriteMealBloc(favourites.get, config),
      )
      ..registerFactory<FavouriteToggleBloc>(
        () => FavouriteToggleBloc(favourites.get, favourites.toggle),
      )
      ..registerFactory<RecipeMealBloc>(() => RecipeMealBloc(recipes, config))
      ..registerFactory<MealDetailBloc>(() => mealDetailBloc)
      ..registerFactory<HomeBloc>(() => _FakeHomeBloc())
      ..registerFactory<DiaryBloc>(() => _FakeDiaryBloc())
      ..registerFactory<CalendarDayBloc>(() => _FakeCalendarDayBloc());
  });

  tearDown(() async {
    await getIt.reset();
    await recipes.dispose();
    await favourites.dispose();
  });

  Future<void> openRecipes(
    WidgetTester tester, {
    List<RouteSettings>? pushed,
    Size size = const Size(412, 915),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(pushed ?? []));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(NavigationOptions.addMealRoute);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_chip());
    await tester.tap(_chip());
    await tester.pumpAndSettle();
  }

  testWidgets('the Recipes chip sits beside Favourites', (tester) async {
    await openRecipes(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, l10nEn.recipesLabel),
    );
    expect(chip.selected, isTrue);
    expect(
      tester.getTopLeft(_chip()).dx,
      greaterThan(
        tester
            .getTopLeft(find.widgetWithText(ChoiceChip, l10nEn.favouritesLabel))
            .dx,
      ),
    );
    expect(
      tester.getTopLeft(_chip()).dx,
      lessThan(
        tester
            .getTopLeft(find.widgetWithText(ChoiceChip, l10nEn.allItemsLabel))
            .dx,
      ),
    );
  });

  testWidgets('with no recipes, says how to make one', (tester) async {
    await openRecipes(tester);

    expect(find.text(l10nEn.recipesEmptyLabel), findsOneWidget);
    expect(find.text(l10nEn.recipesEmptyHint), findsOneWidget);
    expect(_list(), findsNothing);
  });

  testWidgets('lists every recipe A to Z without a search', (tester) async {
    recipes.recipes.addAll([
      _recipe('3', 'carrot cake'),
      _recipe('1', 'Banana bread'),
      _recipe('2', 'apple pie'),
      for (var i = 30; i >= 1; i--)
        _recipe('r$i', 'Stew ${i.toString().padLeft(2, '0')}'),
    ]);

    await openRecipes(tester);

    expect(_list(), findsOneWidget);
    final apple = tester.getTopLeft(_row('apple pie')).dy;
    final banana = tester.getTopLeft(_row('Banana bread')).dy;
    final carrot = tester.getTopLeft(_row('carrot cake')).dy;
    expect(apple, lessThan(banana));
    expect(banana, lessThan(carrot));
    // The 33rd recipe is below the fold and still reachable by scrolling.
    expect(_row('Stew 30'), findsNothing);
    await tester.scrollUntilVisible(
      _row('Stew 30'),
      300,
      scrollable: find.descendant(
        of: _list(),
        matching: find.byType(Scrollable),
      ),
    );
    expect(_row('Stew 30'), findsOneWidget);
  });

  testWidgets('a recipe without a photo shows as a plain row', (tester) async {
    recipes.recipes.add(_recipe('1', 'Lentil soup'));

    await openRecipes(tester);

    expect(_row('Lentil soup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a very long name at text scale 2.0 does not overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    recipes.recipes.add(
      _recipe(
        '1',
        'Grandma\'s extra creamy slow-cooked tomato, basil and roasted red '
            'pepper soup with sourdough croutons and parmesan crisps',
      ),
    );

    await openRecipes(tester, size: const Size(360, 780));

    expect(_row('Grandma'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recipe deleted elsewhere leaves the list', (tester) async {
    recipes.recipes.addAll([
      _recipe('1', 'Lentil soup'),
      _recipe('2', 'Pancakes'),
    ]);
    await openRecipes(tester);
    expect(_row('Lentil soup'), findsOneWidget);

    recipes.delete('1');
    await tester.pumpAndSettle();

    expect(_row('Lentil soup'), findsNothing);
    expect(_row('Pancakes'), findsOneWidget);

    recipes.delete('2');
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.recipesEmptyLabel), findsOneWidget);
  });

  testWidgets('typing filters the recipes and stays on Recipes', (
    tester,
  ) async {
    recipes.recipes.addAll([
      _recipe('1', 'Lentil soup'),
      _recipe('2', 'Pancakes'),
    ]);
    await openRecipes(tester);

    await tester.enterText(find.byType(TextField), 'SOUP');
    await tester.pumpAndSettle();

    expect(_row('Lentil soup'), findsOneWidget);
    expect(_row('Pancakes'), findsNothing);
    bool selected() => tester
        .widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, l10nEn.recipesLabel),
        )
        .selected;
    expect(selected(), isTrue);

    // No match: the usual no-results actions, still on Recipes.
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(_row('Lentil soup'), findsNothing);
    expect(find.text(l10nEn.recipesEmptyLabel), findsNothing);
    expect(selected(), isTrue);

    // Clearing the field brings the whole list back, not Recently.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(_row('Lentil soup'), findsOneWidget);
    expect(_row('Pancakes'), findsOneWidget);
    expect(selected(), isTrue);
  });

  testWidgets('a failed load offers a Retry a driver can find', (tester) async {
    recipes.readError = StateError('box closed');
    await openRecipes(tester);

    expect(find.text(l10nEn.recipesLoadErrorLabel), findsOneWidget);
    final retry = find.bySemanticsIdentifier('add-meal-recipes-retry');
    expect(retry, findsOneWidget);

    recipes
      ..readError = null
      ..recipes.add(_recipe('1', 'Lentil soup'));
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.recipesLoadErrorLabel), findsNothing);
    expect(_row('Lentil soup'), findsOneWidget);
  });

  testWidgets('tapping a recipe opens it as search does', (tester) async {
    recipes.recipes.add(_recipe('soup-id', 'Lentil soup', servingsCount: 4));
    final pushed = <RouteSettings>[];
    await openRecipes(tester, pushed: pushed);

    await tester.tap(_row('Lentil soup'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.mealDetailRoute);
    final args = pushed.single.arguments! as MealDetailScreenArguments;
    expect(args.mealEntity.source, MealSourceEntity.recipe);
    expect(args.mealEntity.code, 'soup-id');
    expect(args.mealEntity.name, 'Lentil soup');
    expect(args.intakeTypeEntity, IntakeTypeEntity.dinner);
    expect(args.logTray, isNotNull);
  });

  testWidgets('+ on a recipe puts it on the list, and Log logs it', (
    tester,
  ) async {
    recipes.recipes.add(_recipe('soup-id', 'Lentil soup', servingsCount: 4));
    await openRecipes(tester);

    final plus = find.descendant(
      of: _list(),
      matching: find.bySemanticsIdentifier('meal-item-add'),
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    await tester.tap(_logButton());
    await tester.pumpAndSettle();

    expect(mealDetailBloc.writes, hasLength(1));
    final write = mealDetailBloc.writes.single;
    expect(write.meal.code, 'soup-id');
    expect(write.meal.source, MealSourceEntity.recipe);
    expect(find.byKey(const Key('main')), findsOneWidget);
  });
}
