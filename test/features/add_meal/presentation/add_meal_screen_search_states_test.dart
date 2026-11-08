// Search-state coverage for #578: untouched, loading, results and
// zero-result states, and the query surviving a trip to the scanner or the
// create-food screen and back. Partial provider failures are covered in
// add_meal_screen_provider_failure_test.dart, whose harness this copies.
//
// Searches travel through the real SearchProductsUseCase, the real
// Products/Food blocs and the real AddMealScreen. Only the repository, the
// local data sources and the config are faked, plus the screens Add Meal
// opens (see the stub routes below).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/navigation_predicates.dart';
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
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/partial_results_notice.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

class _FakeProductsRepository implements ProductsRepository {
  bool offThrows = false;
  bool fdcThrows = false;
  Completer<void>? offGate;
  List<MealEntity> offResults = const [];
  List<MealEntity> fdcResults = const [];

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    if (offGate != null) await offGate!.future;
    if (offThrows) throw Exception('OFF HTTP 429');
    return offResults;
  }

  @override
  Future<List<MealEntity>> getSupabaseFoodsByString(
    String searchString, {
    bool forResolution = false,
  }) async {
    if (fdcThrows) throw Exception('Supabase timeout');
    return fdcResults;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  final bool imperial = false;

  _FakeGetConfigUsecase();

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: imperial,
  );

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
  @override
  List<RecipeDBO> getAllRecipes() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// An empty cache that accepts writes: cached copies would otherwise stand
/// in for remote results and blur what each provider returned.
class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> cacheFromSearch(Iterable<MealDBO> meals) async {}

  @override
  List<MealDBO> getAllByMostRecentlyTouched() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

SearchProductsUseCase _useCase(
  _FakeProductsRepository repository,
  GetConfigUsecase config, {
  _FakeCustomMealDataSource? customMeals,
}) => SearchProductsUseCase(
  repository,
  _FakeGetIntakeUsecase(),
  customMeals ?? _FakeCustomMealDataSource(),
  _FakeRemoteSearchCacheDataSource(),
  _FakeRecipeDataSource(),
  config,
);

final getIt = GetIt.instance;

late _FakeProductsRepository _repository;
late _FakeCustomMealDataSource _customMeals;
FakeFavourites? _favourites;

Future<void> _register() async {
  await getIt.reset();
  _repository = _FakeProductsRepository();
  _customMeals = _FakeCustomMealDataSource();
  final config = _FakeGetConfigUsecase();
  final useCase = _useCase(_repository, config, customMeals: _customMeals);
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(useCase, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(useCase, config));
  getIt.registerFactory<RecentMealBloc>(
    () => RecentMealBloc(_FakeGetIntakeUsecase(), config),
  );
  // #1307: the screen's Favourites source and the stars on its cards.
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
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

/// Opens Add Meal as the named route it is in the app, so the unwinds the
/// screens it opens make (`namedRouteOrFirst(addMealRoute)`) find it by
/// name. The scanner, meal detail and edit-meal routes are stubs that make
/// the same navigator calls as the real screens, so each round trip leaves
/// the stack the way the app does. The energy unit is for the "To log"
/// list those trips fill.
Widget _app() => ChangeNotifierProvider(
  create: (_) => EnergyUnitProvider(usesKilojoules: false),
  child: MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    initialRoute: NavigationOptions.addMealRoute,
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings.name == NavigationOptions.addMealRoute
          ? RouteSettings(
              name: settings.name,
              arguments: AddMealScreenArguments(
                AddMealType.lunchType,
                DateTime(2026, 10, 1),
              ),
            )
          : settings,
      builder: (_) => switch (settings.name) {
        NavigationOptions.scannerRoute => _StubScanner(
          settings.arguments! as ScannerScreenArguments,
        ),
        NavigationOptions.mealDetailRoute => _StubMealDetail(
          settings.arguments! as MealDetailScreenArguments,
        ),
        NavigationOptions.editMealRoute => _StubEditMeal(
          settings.arguments! as EditMealScreenArguments,
        ),
        _ => const AddMealScreen(),
      },
    ),
  ),
);

/// The scanner: a found product replaces the scanner with its detail
/// screen (ScannerScreen, ScannerLoadedState); Back leaves without one.
class _StubScanner extends StatelessWidget {
  final ScannerScreenArguments args;

  const _StubScanner(this.args);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: TextButton(
      onPressed: () => Navigator.of(context).pushReplacementNamed(
        NavigationOptions.mealDetailRoute,
        arguments: MealDetailScreenArguments(
          _meal('Scanned oats', MealSourceEntity.off),
          args.intakeTypeEntity!,
          args.day!,
          false,
          logTray: args.logTray,
        ),
      ),
      child: const Text('stub: product found'),
    ),
  );
}

/// Meal detail with a "To log" list: adds the food to it and unwinds to
/// Add Meal (MealDetailBottomSheet).
class _StubMealDetail extends StatelessWidget {
  final MealDetailScreenArguments args;

  const _StubMealDetail(this.args);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: TextButton(
      onPressed: () {
        args.logTray!.add(
          LogTrayItem(
            meal: args.mealEntity,
            unit: 'g',
            amount: 100,
            amountLabel: '100 g',
          ),
        );
        Navigator.of(
          context,
        ).popUntil(namedRouteOrFirst(NavigationOptions.addMealRoute));
      },
      child: const Text('stub: add to list'),
    ),
  );
}

/// Create food: saving swaps the editor for the new food's detail screen,
/// keeping Add Meal below it (EditMealScreen's save); Back cancels.
class _StubEditMeal extends StatelessWidget {
  final EditMealScreenArguments args;

  const _StubEditMeal(this.args);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: TextButton(
      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationOptions.mealDetailRoute,
        namedRouteOrFirst(NavigationOptions.addMealRoute),
        arguments: MealDetailScreenArguments(
          _meal('My zzqx bar', MealSourceEntity.custom),
          args.intakeTypeEntity,
          args.day,
          args.usesImperialUnits,
          logTray: args.logTray,
        ),
      ),
      child: const Text('stub: save food'),
    ),
  );
}

/// Opens the screen and submits [query], which searches All.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  // Let the keystroke's debounced search fire too, so no timer outlives
  // the test; it finds the submitted query already answered.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

/// The zero-result state for a completed search, with both next steps.
void _expectZeroResultState() {
  expect(find.byType(NoResultsWidget), findsOneWidget);
  expect(find.text(l10nEn.noResultsFound), findsOneWidget);
  expect(find.text(l10nEn.noResultsSubtitle), findsOneWidget);
  expect(
    find.bySemanticsIdentifier('search-no-results-scan-barcode'),
    findsOneWidget,
  );
  expect(
    find.bySemanticsIdentifier('search-no-results-create-custom-food'),
    findsOneWidget,
  );
}

/// Back on Add Meal after a round trip: the query is still in the field and
/// its zero-result state is still showing.
void _expectQueryKept(WidgetTester tester, String query) {
  expect(find.byType(AddMealScreen), findsOneWidget);
  expect(_fieldText(tester), query);
  _expectZeroResultState();
}

void main() {
  group('AddMealScreen search states (#578)', () {
    tearDown(() async => getIt.reset());

    testWidgets('no zero-result state while providers are still loading', (
      tester,
    ) async {
      await _register();
      final gate = _repository.offGate = Completer<void>();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'zzqx');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.byType(NoResultsWidget), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(NoResultsWidget), findsWidgets);
    });

    testWidgets('an untouched search field shows no zero-result state', (
      tester,
    ) async {
      await _register();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.noResultsFound), findsNothing);
    });

    testWidgets('a short query that never searches shows the defaults, not '
        'a zero-result state', (tester) async {
      await _register();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      // Searches All, below the length the providers are asked at.
      await tester.enterText(find.byType(TextField).first, 'z');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(DefaultsResultsWidget), findsOneWidget);
      expect(find.byType(NoResultsWidget), findsNothing);
    });

    testWidgets('matches from both providers show as results', (tester) async {
      await _register();
      _repository
        ..offResults = [_meal('Apple juice', MealSourceEntity.off)]
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];

      await _search(tester, 'apple');

      expect(
        find.textContaining('Apple juice', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Apple, raw', findRichText: true),
        findsOneWidget,
      );
      expect(find.bySemanticsIdentifier('add-meal-all-list'), findsOneWidget);
      expect(find.byType(NoResultsWidget), findsNothing);
      expect(find.byType(PartialResultsNotice), findsNothing);
    });

    testWidgets('a completed search with no matches explains it and offers '
        'scan and create', (tester) async {
      await _register();

      await _search(tester, 'zzqx');

      _expectZeroResultState();
      expect(find.byType(PartialResultsNotice), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(l10nEn.errorFetchingProductData), findsNothing);
    });
  });

  group('AddMealScreen keeps the query across navigation (#578)', () {
    tearDown(() async => getIt.reset());

    testWidgets('back from the scanner without a result', (tester) async {
      await _register();
      await _search(tester, 'zzqx');

      await tester.tap(
        find.bySemanticsIdentifier('search-no-results-scan-barcode'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(_StubScanner), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      _expectQueryKept(tester, 'zzqx');
    });

    testWidgets('back from the scanner after adding the scanned food', (
      tester,
    ) async {
      await _register();
      await _search(tester, 'zzqx');

      await tester.tap(
        find.bySemanticsIdentifier('search-no-results-scan-barcode'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('stub: product found'));
      await tester.pumpAndSettle();
      expect(find.byType(_StubMealDetail), findsOneWidget);
      await tester.tap(find.text('stub: add to list'));
      await tester.pumpAndSettle();

      _expectQueryKept(tester, 'zzqx');
      expect(
        find.bySemanticsIdentifier('add-meal-tray-list'),
        findsOneWidget,
        reason: 'the trip did add the scanned food to the list',
      );
    });

    testWidgets('back from create food after saving it', (tester) async {
      await _register();
      await _search(tester, 'zzqx');

      await tester.tap(
        find.bySemanticsIdentifier('search-no-results-create-custom-food'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.buttonYesLabel));
      await tester.pumpAndSettle();
      expect(find.byType(_StubEditMeal), findsOneWidget);
      await tester.tap(find.text('stub: save food'));
      await tester.pumpAndSettle();
      expect(find.byType(_StubMealDetail), findsOneWidget);
      await tester.tap(find.text('stub: add to list'));
      await tester.pumpAndSettle();

      _expectQueryKept(tester, 'zzqx');
      expect(
        find.bySemanticsIdentifier('add-meal-tray-list'),
        findsOneWidget,
        reason: 'the trip did add the new food to the list',
      );
    });

    testWidgets('back from create food after cancelling, at the prompt or '
        'in the editor', (tester) async {
      await _register();
      await _search(tester, 'zzqx');

      // Cancelled at the "create a custom food?" prompt.
      await tester.tap(
        find.bySemanticsIdentifier('search-no-results-create-custom-food'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.dialogCancelLabel));
      await tester.pumpAndSettle();
      _expectQueryKept(tester, 'zzqx');

      // Cancelled in the editor itself.
      await tester.tap(
        find.bySemanticsIdentifier('search-no-results-create-custom-food'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.buttonYesLabel));
      await tester.pumpAndSettle();
      expect(find.byType(_StubEditMeal), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      _expectQueryKept(tester, 'zzqx');
      expect(find.bySemanticsIdentifier('add-meal-tray-list'), findsNothing);
    });

    testWidgets('an empty query stays empty, on Recent, after the scanner', (
      tester,
    ) async {
      await _register();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('add-meal-method-barcode'));
      await tester.pumpAndSettle();
      expect(find.byType(_StubScanner), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(_fieldText(tester), isEmpty);
      expect(find.text(l10nEn.noMealsRecentlyAddedLabel), findsOneWidget);
      expect(find.byType(NoResultsWidget), findsNothing);
    });
  });
}
