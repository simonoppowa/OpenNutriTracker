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
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
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
  List<MealEntity> products = const [];
  List<MealEntity> food = const [];

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    offQueries.add(searchString);
    return SearchProductsResult(meals: products, remoteSourceEmpty: true);
  }

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async {
    fdcQueries.add(searchString);
    return SearchProductsResult(meals: food, remoteSourceEmpty: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

IntakeEntity _intake(String name, {double? servingQuantity}) => IntakeEntity(
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
    servingQuantity: servingQuantity,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.custom,
  ),
  dateTime: DateTime(2026, 10, 1),
);

class _RecordingMealDetailBloc extends Fake implements MealDetailBloc {
  final writes = <({String name, String unit, double amount})>[];
  final attempts = <String>[];
  final String? failOnceForName;
  bool _failed = false;

  _RecordingMealDetailBloc({this.failOnceForName});

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async {
    attempts.add(meal.name!);
    if (!_failed && meal.name == failOnceForName) {
      _failed = true;
      throw StateError('Simulated write failure');
    }
    writes.add((
      name: meal.name!,
      unit: unit,
      amount: double.parse(amountText),
    ));
  }
}

class _NoopDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _NoopCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _NoopHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
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

Finder _withIdentifier(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

final getIt = GetIt.instance;

late _FakeGetIntakeUsecase _intakeUsecase;
late _FakeSearch _search;
FakeFavourites? _favourites;

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

Finder _searchAll() => find.text(l10nEn.noResultsSearchAll);

void main() {
  group('RecentMealBloc search-as-you-type', () {
    test(
      'keystrokes filter the loaded history without re-reading storage',
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
      },
    );

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
      'quick serving chips keep each selected food independent and save base amounts',
      (tester) async {
        await _register([
          _intake('Bread', servingQuantity: 30),
          _intake('Cheese', servingQuantity: 20),
        ]);
        final saved = _RecordingMealDetailBloc();
        getIt.registerSingleton<MealDetailBloc>(saved);
        getIt.registerSingleton<DiaryBloc>(_NoopDiaryBloc());
        getIt.registerSingleton<CalendarDayBloc>(_NoopCalendarDayBloc());
        getIt.registerSingleton<HomeBloc>(_NoopHomeBloc());
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        await tester.tap(_withIdentifier('add-meal-select-multiple'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MealItemCard).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MealItemCard).at(1));
        await tester.pumpAndSettle();
        expect(find.text(l10nEn.reviewSelectedFoodsCount(2)), findsOneWidget);
        await tester.tap(find.text(l10nEn.reviewSelectedFoodsCount(2)));
        await tester.pumpAndSettle();

        expect(find.text('½×'), findsNWidgets(2));
        expect(find.text('1×'), findsNWidgets(2));
        expect(find.text('2×'), findsNWidgets(2));
        await tester.tap(find.text('½×').first);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(1))
              .controller!
              .text,
          '0.5',
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(2))
              .controller!
              .text,
          '100',
        );
        await tester.ensureVisible(find.text('2×').last);
        await tester.tap(find.text('2×').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
        await tester.pumpAndSettle();
        expect(saved.writes, [
          (name: 'Bread', unit: 'serving', amount: 15),
          (name: 'Cheese', unit: 'serving', amount: 40),
        ]);
      },
    );

    testWidgets(
      'retry after a partial multi-food write skips committed foods',
      (tester) async {
        await _register([_intake('Bread'), _intake('Cheese')]);
        final saved = _RecordingMealDetailBloc(failOnceForName: 'Cheese');
        getIt.registerSingleton<MealDetailBloc>(saved);
        getIt.registerSingleton<DiaryBloc>(_NoopDiaryBloc());
        getIt.registerSingleton<CalendarDayBloc>(_NoopCalendarDayBloc());
        getIt.registerSingleton<HomeBloc>(_NoopHomeBloc());
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        await tester.tap(_withIdentifier('add-meal-select-multiple'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MealItemCard).at(0));
        await tester.tap(find.byType(MealItemCard).at(1));
        await tester.pumpAndSettle();
        expect(_withIdentifier('add-meal-review-selected'), findsOneWidget);
        await tester.tap(_withIdentifier('add-meal-review-selected'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
        await tester.pumpAndSettle();
        expect(saved.attempts, ['Bread', 'Cheese']);
        expect(saved.writes.map((write) => write.name), ['Bread']);
        expect(
          find.text(l10nEn.selectedFoodsPartialFailureLabel),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Bread'),
          ),
          findsNothing,
        );

        await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
        await tester.pumpAndSettle();
        expect(saved.attempts, ['Bread', 'Cheese', 'Cheese']);
        expect(saved.writes.map((write) => write.name), ['Bread', 'Cheese']);
      },
    );

    testWidgets('closing a partial batch keeps only unwritten foods selected', (
      tester,
    ) async {
      await _register([_intake('Bread'), _intake('Cheese')]);
      final saved = _RecordingMealDetailBloc(failOnceForName: 'Cheese');
      getIt.registerSingleton<MealDetailBloc>(saved);
      getIt.registerSingleton<DiaryBloc>(_NoopDiaryBloc());
      getIt.registerSingleton<CalendarDayBloc>(_NoopCalendarDayBloc());
      getIt.registerSingleton<HomeBloc>(_NoopHomeBloc());
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(_withIdentifier('add-meal-select-multiple'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MealItemCard).at(0));
      await tester.tap(find.byType(MealItemCard).at(1));
      await tester.pumpAndSettle();
      await tester.tap(_withIdentifier('add-meal-review-selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10nEn.dialogCancelLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.reviewSelectedFoodsCount(1)), findsOneWidget);
      await tester.tap(_withIdentifier('add-meal-review-selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
      await tester.pumpAndSettle();
      expect(saved.attempts, ['Bread', 'Cheese', 'Cheese']);
      expect(saved.writes.map((write) => write.name), ['Bread', 'Cheese']);
    });

    testWidgets('selects multiple foods and validates every reviewed amount', (
      tester,
    ) async {
      await _register([_intake('Apple'), _intake('Banana')]);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(_withIdentifier('add-meal-select-multiple'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MealItemCard).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MealItemCard).at(1));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.reviewSelectedFoodsCount(2)), findsOneWidget);
      await tester.tap(find.text(l10nEn.reviewSelectedFoodsCount(2)));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.reviewSelectedFoodsTitle), findsOneWidget);
      expect(find.text('½×'), findsNothing);
      expect(find.text('100 g'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).last, '-1');
      await tester.tap(find.text(l10nEn.addSelectedFoodsLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.enterPositiveAmountsLabel), findsOneWidget);
    });

    testWidgets('each meal result list identifies its parent surface', (
      tester,
    ) async {
      await _register([_intake('Apple')]);
      _search
        ..products = [_meal('Product', MealSourceEntity.off)]
        ..food = [_meal('Food', MealSourceEntity.fdc)];
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ap');
      await tester.pumpAndSettle();

      expect(_withIdentifier('add-meal-all-list'), findsOneWidget);

      await tester.tap(find.text(l10nEn.searchProductsPage));
      await tester.pumpAndSettle();
      expect(_withIdentifier('add-meal-products-list'), findsOneWidget);

      await tester.tap(find.text(l10nEn.searchFoodPage));
      await tester.pumpAndSettle();
      expect(_withIdentifier('add-meal-food-list'), findsOneWidget);

      await tester.tap(find.text(l10nEn.recentlyAddedLabel));
      await tester.pumpAndSettle();
      expect(_withIdentifier('add-meal-recent-list'), findsOneWidget);
    });

    testWidgets(
      'Search all is offered only once the query is long enough to search, '
      'and typing never re-reads recent history',
      (tester) async {
        await _register([_intake('Apple')]);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        // Explicitly pick Recent so typing stays there (#576).
        await tester.tap(find.text(l10nEn.recentlyAddedLabel));
        await tester.pumpAndSettle();
        expect(_withIdentifier('add-meal-recent-list'), findsOneWidget);
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

        await tester.ensureVisible(_searchAll());
        await tester.tap(_searchAll());
        await tester.pumpAndSettle();
        expect(_search.offQueries, contains('zz'));
        expect(_search.fdcQueries, contains('zz'));
        expect(find.text(l10nEn.noResultsFound), findsOneWidget);
      },
    );
  });
}
