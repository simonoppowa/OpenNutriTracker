import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

/// Counts reads of recent history: each one copies and sorts the whole
/// intake box, so typing must not trigger one per keystroke (#1334 review).
class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  final List<IntakeEntity> recent;
  int recentReads = 0;

  _FakeGetIntakeUsecase(this.recent);

  @override
  Future<List<IntakeEntity>> getRecentIntake() async {
    recentReads++;
    return recent;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
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
  final List<String> offQueries = [];
  final List<String> fdcQueries = [];

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    offQueries.add(searchString);
    return const SearchProductsResult(meals: [], remoteSourceEmpty: true);
  }

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async {
    fdcQueries.add(searchString);
    return const SearchProductsResult(meals: [], remoteSourceEmpty: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

IntakeEntity _intake(String name) => IntakeEntity(
  id: name,
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.lunch,
  meal: MealEntity(
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
  ),
  dateTime: DateTime(2026, 10, 1),
);

final getIt = GetIt.instance;

late _FakeGetIntakeUsecase _intakeUsecase;
late _FakeSearch _search;

Future<void> _register(List<IntakeEntity> recent) async {
  await getIt.reset();
  _intakeUsecase = _FakeGetIntakeUsecase(recent);
  _search = _FakeSearch();
  final config = _FakeGetConfigUsecase();
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(_search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(_search, config));
  getIt.registerFactory<RecentMealBloc>(
    () => RecentMealBloc(_intakeUsecase, config),
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

Finder _searchAll() => find.text(l10nEn.noResultsSearchAll);

void main() {
  group('RecentMealBloc search-as-you-type', () {
    test('keystrokes filter the loaded history without re-reading storage',
        () async {
      final usecase = _FakeGetIntakeUsecase([
        _intake('Apple'),
        _intake('Banana'),
      ]);
      final bloc = RecentMealBloc(usecase, _FakeGetConfigUsecase());
      addTearDown(bloc.close);

      bloc.add(const LoadRecentMealEvent(searchString: ''));
      await Future<void>.delayed(Duration.zero);
      for (final query in ['a', 'ap', 'app', 'ban']) {
        bloc.add(RecentMealSearchChangedEvent(searchString: query));
        await Future<void>.delayed(Duration.zero);
      }

      expect(usecase.recentReads, 1);
      final state = bloc.state as RecentMealLoadedState;
      expect(state.recentMeals.map((m) => m.name), ['Banana']);
    });

    test('a keystroke before anything is loaded reads storage once', () async {
      final usecase = _FakeGetIntakeUsecase([_intake('Apple')]);
      final bloc = RecentMealBloc(usecase, _FakeGetConfigUsecase());
      addTearDown(bloc.close);

      bloc.add(const RecentMealSearchChangedEvent(searchString: 'a'));
      bloc.add(const RecentMealSearchChangedEvent(searchString: 'ap'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(usecase.recentReads, 1);
      final state = bloc.state as RecentMealLoadedState;
      expect(state.recentMeals.map((m) => m.name), ['Apple']);
    });

    test('an explicit load re-reads storage', () async {
      final usecase = _FakeGetIntakeUsecase([_intake('Apple')]);
      final bloc = RecentMealBloc(usecase, _FakeGetConfigUsecase());
      addTearDown(bloc.close);

      bloc.add(const LoadRecentMealEvent(searchString: ''));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoadRecentMealEvent(searchString: 'ap'));
      await Future<void>.delayed(Duration.zero);

      expect(usecase.recentReads, 2);
    });
  });

  group('AddMealScreen sticky Recent search', () {
    tearDown(() async => getIt.reset());

    testWidgets(
        'Search all is offered only once the query is long enough to search, '
        'and typing never re-reads recent history', (tester) async {
      await _register([_intake('Apple')]);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Explicitly pick Recent so typing stays there (#576).
      await tester.tap(find.text(l10nEn.recentlyAddedLabel));
      await tester.pumpAndSettle();
      final readsBeforeTyping = _intakeUsecase.recentReads;

      // One character: All would refuse to search it, so no CTA.
      await tester.enterText(find.byType(TextField).first, 'z');
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.noResultsFound), findsOneWidget);
      expect(_searchAll(), findsNothing);

      // Two characters: the CTA appears and runs the promised search.
      await tester.enterText(find.byType(TextField).first, 'zz');
      await tester.pumpAndSettle();
      expect(_searchAll(), findsOneWidget);
      expect(_intakeUsecase.recentReads, readsBeforeTyping);

      await tester.tap(_searchAll());
      await tester.pumpAndSettle();
      expect(_search.offQueries, contains('zz'));
      expect(_search.fdcQueries, contains('zz'));
      expect(find.text(l10nEn.noResultsFound), findsOneWidget);
    });
  });
}
