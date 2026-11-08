// Search-state coverage for #578: loading and zero-result states.
// Harness copied from add_meal_screen_provider_failure_test.dart.
//
// End-to-end coverage for #578 (PR #1282): a provider outage in the "All"
// search must not read as "no matching foods".
//
// The provider failure starts where it does in the app — the repository
// throws — and travels through the real SearchProductsUseCase (which
// swallows it and falls back to local matches), the real Products/Food
// blocs, and the real AddMealScreen. Only the repository, the local data
// sources and the config are faked.

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
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
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
import 'package:opennutritracker/generated/l10n.dart';

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
  });
}
