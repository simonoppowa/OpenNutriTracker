// End-to-end coverage for #578 (PR #1282): a provider outage in the "All"
// search must not read as "no matching foods".
//
// The provider failure starts where it does in the app — the repository
// throws — and travels through the real SearchProductsUseCase (which
// swallows it and falls back to local matches), the real Products/Food
// blocs, and the real AddMealScreen. Only the repository, the local data
// sources and the config are faked.

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
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/partial_results_notice.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

class _FakeProductsRepository implements ProductsRepository {
  bool offThrows = false;
  bool fdcThrows = false;
  List<MealEntity> offResults = const [];
  List<MealEntity> fdcResults = const [];

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
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
  final bool imperial;

  _FakeGetConfigUsecase({this.imperial = false});

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

Widget _app() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: RouteSettings(
      name: settings.name,
      arguments: AddMealScreenArguments(
        AddMealType.lunchType,
        DateTime(2026, 10, 1),
      ),
    ),
    builder: (_) => const AddMealScreen(),
  ),
);

/// A result card: the name is the first span of a rich title, after which
/// the card appends the brand.
Finder _card(String name) =>
    find.textContaining(name, findRichText: true);

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

void main() {
  group('Search blocs carry provider failures on the loaded state', () {
    test('a throwing OFF source loads, flagged as failed, not as empty',
        () async {
      final repository = _FakeProductsRepository()..offThrows = true;
      final config = _FakeGetConfigUsecase();
      final bloc = ProductsBloc(_useCase(repository, config), config);
      addTearDown(bloc.close);

      bloc.add(const LoadProductsEvent(searchString: 'apple'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as ProductsLoadedState;
      expect(state.remoteSourceFailed, isTrue);

      repository.offThrows = false;
      bloc.add(const LoadProductsEvent(searchString: 'apples'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((bloc.state as ProductsLoadedState).remoteSourceFailed, isFalse,
          reason: 'a zero-row answer is not a failure');
    });

    test('a throwing Supabase source loads, flagged as failed', () async {
      final repository = _FakeProductsRepository()..fdcThrows = true;
      final config = _FakeGetConfigUsecase();
      final bloc = FoodBloc(_useCase(repository, config), config);
      addTearDown(bloc.close);

      bloc.add(const LoadFoodEvent(searchString: 'apple'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((bloc.state as FoodLoadedState).remoteSourceFailed, isTrue);
    });

    test('Retry keeps the imperial unit preference (products)', () async {
      final repository = _FakeProductsRepository()..offThrows = true;
      final config = _FakeGetConfigUsecase(imperial: true);
      final bloc = ProductsBloc(_useCase(repository, config), config);
      addTearDown(bloc.close);

      bloc.add(const LoadProductsEvent(searchString: 'apple'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repository
        ..offThrows = false
        ..offResults = [_meal('Apple juice', MealSourceEntity.off)];
      bloc.add(const RefreshProductsEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as ProductsLoadedState;
      expect(state.products, isNotEmpty);
      expect(state.usesImperialUnits, isTrue);
      expect(state.remoteSourceFailed, isFalse);
    });

    test('Retry keeps the imperial unit preference (food)', () async {
      final repository = _FakeProductsRepository()..fdcThrows = true;
      final config = _FakeGetConfigUsecase(imperial: true);
      final bloc = FoodBloc(_useCase(repository, config), config);
      addTearDown(bloc.close);

      bloc.add(const LoadFoodEvent(searchString: 'apple'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      repository
        ..fdcThrows = false
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
      bloc.add(const RefreshFoodEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = bloc.state as FoodLoadedState;
      expect(state.food, isNotEmpty);
      expect(state.usesImperialUnits, isTrue);
    });
  });

  group('AddMealScreen All search with a provider outage', () {
    tearDown(() async => getIt.reset());

    testWidgets('one provider down: results plus the partial notice', (
      tester,
    ) async {
      await _register();
      _repository
        ..offThrows = true
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];

      await _search(tester, 'apple');

      expect(_card('Apple, raw'), findsOneWidget);
      expect(find.byType(PartialResultsNotice), findsOneWidget);
      expect(find.text(l10nEn.partialResultsNotice), findsOneWidget);
      expect(
        find.text(l10nEn.partialResultsAllSourcesDownNotice),
        findsNothing,
      );
    });

    testWidgets(
        'both providers down but saved foods match: the list, with a notice '
        'that no online source answered and a Retry for both', (tester) async {
      await _register();
      _customMeals.meals.add(
        MealDBO.fromMealEntity(_meal('Apple pie', MealSourceEntity.custom)),
      );
      _repository
        ..offThrows = true
        ..fdcThrows = true;

      await _search(tester, 'apple');

      expect(_card('Apple pie'), findsOneWidget);
      expect(find.text(l10nEn.partialResultsAllSourcesDownNotice),
          findsOneWidget);
      expect(find.text(l10nEn.partialResultsNotice), findsNothing,
          reason: 'neither source answered, so none is "the one" missing');
      expect(find.text(l10nEn.errorFetchingProductData), findsNothing);

      // Both recover; the notice's Retry re-runs both searches.
      _repository
        ..offThrows = false
        ..fdcThrows = false
        ..offResults = [_meal('Apple juice', MealSourceEntity.off)]
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
      await tester.tap(
        find.bySemanticsIdentifier('search-partial-results-retry'),
      );
      await tester.pumpAndSettle();

      expect(_card('Apple juice'), findsOneWidget);
      expect(_card('Apple, raw'), findsOneWidget);
      expect(find.byType(PartialResultsNotice), findsNothing);
    });

    testWidgets('one provider down, other empty: notice above no-results', (
      tester,
    ) async {
      await _register();
      _repository.fdcThrows = true;

      await _search(tester, 'apple');

      expect(find.byType(PartialResultsNotice), findsOneWidget);
      expect(find.byType(NoResultsWidget), findsOneWidget);
    });

    testWidgets(
        'both providers down on a landscape phone: the error scrolls instead '
        'of overflowing, and Retry stays reachable', (tester) async {
      // 800 x 360 logical: a phone on its side, where the space left under
      // the search field, chips and header is shorter than the error.
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _register();
      _repository
        ..offThrows = true
        ..fdcThrows = true;

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      // The empty-history Recent hint the screen opens on doesn't fit this
      // height either. That is older than this state and outside it, so
      // drop its report and judge only what the search renders.
      tester.takeException();
      await _search(tester, 'apple');

      expect(tester.takeException(), isNull,
          reason: 'the error must not overflow the results area');
      final retry = find.bySemanticsIdentifier('search-all-retry');
      await tester.scrollUntilVisible(
        retry,
        50,
        scrollable: find.byType(Scrollable).last,
      );
      _repository
        ..offThrows = false
        ..fdcThrows = false
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(_card('Apple, raw'), findsOneWidget);
    });

    testWidgets('both providers down: an error with an identified Retry', (
      tester,
    ) async {
      await _register();
      _repository
        ..offThrows = true
        ..fdcThrows = true;

      await _search(tester, 'apple');

      expect(find.text(l10nEn.errorFetchingProductData), findsOneWidget);
      expect(find.byType(NoResultsWidget), findsNothing);
      final retry = find.bySemanticsIdentifier('search-all-retry');
      expect(retry, findsOneWidget);

      // Both providers recover; Retry re-runs both searches.
      _repository
        ..offThrows = false
        ..fdcThrows = false
        ..offResults = [_meal('Apple juice', MealSourceEntity.off)]
        ..fdcResults = [_meal('Apple, raw', MealSourceEntity.fdc)];
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(_card('Apple juice'), findsOneWidget);
      expect(_card('Apple, raw'), findsOneWidget);
      expect(find.byType(PartialResultsNotice), findsNothing);
    });

    testWidgets('both providers answer empty: plain no-results, no notice', (
      tester,
    ) async {
      await _register();

      await _search(tester, 'apple');

      expect(find.byType(NoResultsWidget), findsOneWidget);
      expect(find.byType(PartialResultsNotice), findsNothing);
      expect(find.text(l10nEn.errorFetchingProductData), findsNothing);
    });
  });
}
