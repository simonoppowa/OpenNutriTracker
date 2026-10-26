import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
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
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/presentation/screens/bulk_add_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/log_tray_widgets.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

MealEntity _meal(
  String name, {
  double kcal100 = 200,
  String? mealUnit = 'g',
  double? servingQuantity,
  String? servingSize,
  bool complete = true,
  MealSourceEntity source = MealSourceEntity.custom,
  bool detailed = false,
}) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: mealUnit,
  servingQuantity: servingQuantity,
  servingUnit: 'g',
  servingSize: servingSize,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: complete ? 10 : null,
    fat100: complete ? 5 : null,
    proteins100: complete ? 3 : null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
  detailed: detailed,
);

IntakeEntity _intake(MealEntity meal) => IntakeEntity(
  id: meal.name!,
  unit: 'g',
  amount: 100,
  type: IntakeTypeEntity.breakfast,
  meal: meal,
  dateTime: DateTime(2026, 10, 1),
);

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  final List<IntakeEntity> recent;

  _FakeGetIntakeUsecase(this.recent);

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => recent;

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
  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: true);

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: true);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCache extends Fake implements RemoteSearchCacheDataSource {
  @override
  MealDBO? getDetailedByBarcode(String barcode) => null;

  @override
  Future<void> cache(MealDBO meal) async {}
}

/// Answers a barcode lookup with [full], or fails when it is null.
class _FakeProducts extends Fake implements ProductsRepository {
  MealEntity? full;
  var lookups = 0;

  @override
  Future<MealEntity> getOFFProductByBarcode(
    String barcode, {
    String? knownName,
  }) async {
    lookups++;
    final meal = full;
    if (meal == null) throw StateError('offline');
    return meal;
  }
}

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {
  final writes = <({String unit, String amount, String? name})>[];
  int? failAt;

  /// When set, every write waits on it.
  Completer<void>? gate;

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity intakeTypeEntity,
    MealEntity meal,
    DateTime day,
  ) async {
    if (failAt == writes.length) throw StateError('write failed');
    await gate?.future;
    writes.add((unit: unit, amount: amountText, name: meal.name));
  }
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  var refreshed = false;

  @override
  void add(HomeEvent event) => refreshed = true;
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

final getIt = GetIt.instance;
FakeFavourites? _favourites;
late _FakeMealDetailBloc _mealDetailBloc;
late _FakeHomeBloc _homeBloc;
late _FakeProducts _products;

Future<void> _register(List<MealEntity> recent) async {
  await getIt.reset();
  final config = _FakeGetConfigUsecase();
  final search = _FakeSearch();
  _mealDetailBloc = _FakeMealDetailBloc();
  _homeBloc = _FakeHomeBloc();
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(search, config));
  getIt.registerFactory<RecentMealBloc>(
    () => RecentMealBloc(
      _FakeGetIntakeUsecase(recent.map(_intake).toList()),
      config,
    ),
  );
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
  getIt.registerFactory<MealDetailBloc>(() => _mealDetailBloc);
  getIt.registerFactory<HomeBloc>(() => _homeBloc);
  getIt.registerFactory<DiaryBloc>(() => _FakeDiaryBloc());
  getIt.registerFactory<CalendarDayBloc>(() => _FakeCalendarDayBloc());
  _products = _FakeProducts();
  getIt.registerSingleton<RemoteSearchCacheDataSource>(_FakeCache());
  getIt.registerSingleton<ProductsRepository>(_products);
}

/// Main at the bottom, the add-food screen pushed over it, and a recording
/// stub for every other route.
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
              AddMealType.breakfastType,
              DateTime(2026, 10, 18),
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

Future<void> _openAddMeal(
  WidgetTester tester,
  List<RouteSettings> pushed,
) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(pushed));
  await tester.pumpAndSettle();
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushNamed(NavigationOptions.addMealRoute);
  await tester.pumpAndSettle();
}

Finder _plusOn(String name) => find.descendant(
  of: find.ancestor(of: _card(name), matching: find.byType(Row)).first,
  matching: find.bySemanticsIdentifier('meal-item-add'),
);

Finder _card(String name) =>
    find.textContaining(name, findRichText: true).first;

/// Scrolls the result into view first: once the list has items, the log
/// button takes the bottom of the screen and the results scroll above it.
Future<void> _tapPlus(WidgetTester tester, String name) async {
  await tester.ensureVisible(_plusOn(name));
  await tester.pumpAndSettle();
  await tester.tap(_plusOn(name));
}

Finder _logButton() => find.bySemanticsIdentifier('add-meal-tray-log');

void main() {
  group('LogTray', () {
    test('sums energy and keeps order through removals', () {
      final tray = LogTray();
      addTearDown(tray.dispose);
      var notified = 0;
      tray.addListener(() => notified++);

      final a = _meal('A', kcal100: 200);
      final b = _meal('B', kcal100: 50);
      tray.add(LogTrayItem(meal: a, unit: 'g', amount: 150, amountLabel: ''));
      tray.addAll([
        LogTrayItem(meal: b, unit: 'g', amount: 200, amountLabel: ''),
        LogTrayItem(meal: a, unit: 'g', amount: 50, amountLabel: ''),
      ]);
      expect(tray.length, 3);
      expect(tray.totalKcal, closeTo(300 + 100 + 100, 0.001));

      tray.removeAt(0);
      expect(tray.items.map((i) => i.meal.name), ['B', 'A']);

      // By identity: an equal-looking entry that was not named stays.
      final again = LogTrayItem(
        meal: b,
        unit: 'g',
        amount: 200,
        amountLabel: '',
      );
      tray.add(again);
      tray.removeAll([tray.items.first]);
      expect(tray.items.map((i) => i.meal.name), ['A', 'B']);
      expect(identical(tray.items.last, again), isTrue);
      tray.clear();
      expect(tray.isEmpty, isTrue);
      expect(notified, 6);
    });
  });

  group('the log button', () {
    Future<void> pumpButton(WidgetTester tester, int items) async {
      final tray = LogTray();
      addTearDown(tray.dispose);
      for (var i = 0; i < items; i++) {
        tray.add(
          LogTrayItem(
            meal: _meal('M$i'),
            unit: 'g',
            amount: 100,
            amountLabel: '',
          ),
        );
      }
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => EnergyUnitProvider(usesKilojoules: false),
          child: MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: LogTrayLogButton(tray: tray, onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // #1470: one item read "Log 1 items".
    testWidgets('one item reads singular', (tester) async {
      await pumpButton(tester, 1);
      expect(find.text('Log 1 item'), findsOneWidget);
    });

    testWidgets('two items read plural', (tester) async {
      await pumpButton(tester, 2);
      expect(find.text('Log 2 items'), findsOneWidget);
    });

    test('the review screen\'s add-to-list label agrees', () {
      expect(l10nEn.bulkAddToListLabel(1), 'Add 1 item');
      expect(l10nEn.bulkAddToListLabel(2), 'Add 2 items');
    });
  });

  group('the default amount behind the +', () {
    Future<LogTrayItem?> resolve(
      WidgetTester tester,
      MealEntity meal, {
      bool imperial = false,
      bool raw = false,
    }) async {
      LogTrayItem? item;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (context) {
              item = defaultLogTrayItem(
                context,
                meal,
                usesImperialUnits: imperial,
                defaultToRawFoodUnits: raw,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return item;
    }

    testWidgets('a food with a serving goes on as one serving', (tester) async {
      final item = await resolve(
        tester,
        _meal('Bread', servingQuantity: 38, servingSize: '1 slice (38 g)'),
      );
      expect(item!.unit, 'serving');
      expect(item.amount, 38);
    });

    testWidgets('raw units win over the serving when the user prefers them', (
      tester,
    ) async {
      final item = await resolve(
        tester,
        _meal('Bread', servingQuantity: 38),
        raw: true,
      );
      expect(item!.unit, 'g');
      expect(item.amount, 100);
      expect(item.amountLabel, '100 ${l10nEn.gramUnit}');
    });

    testWidgets('imperial starts at one ounce', (tester) async {
      final item = await resolve(tester, _meal('Rice'), imperial: true);
      expect(item!.unit, 'oz');
      expect(item.amount, closeTo(28.35, 0.01));
    });

    testWidgets('a food missing a macro has no default', (tester) async {
      expect(await resolve(tester, _meal('Odd', complete: false)), isNull);
    });
  });

  group('the add-food screen', () {
    testWidgets('+ adds at the default amount, and the list can be edited', (
      tester,
    ) async {
      await _register([_meal('Oats', kcal100: 380), _meal('Milk')]);
      await _openAddMeal(tester, []);

      expect(_logButton(), findsNothing);
      await _tapPlus(tester, 'Oats');
      await tester.pumpAndSettle();
      await _tapPlus(tester, 'Milk');
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.logTrayTitle(2).toUpperCase()), findsOneWidget);
      expect(find.text(l10nEn.bulkAddSubmitLabel(2)), findsOneWidget);
      expect(find.text('580 kcal'), findsOneWidget);

      await tester.tap(find.byTooltip(l10nEn.logTrayRemoveLabel).first);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.bulkAddSubmitLabel(1)), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier('add-meal-tray-clear'));
      await tester.pumpAndSettle();
      expect(_logButton(), findsNothing);
      expect(_mealDetailBloc.writes, isEmpty);
    });

    testWidgets('one button logs the whole list and returns to the day', (
      tester,
    ) async {
      await _register([_meal('Oats', kcal100: 380), _meal('Milk')]);
      await _openAddMeal(tester, []);
      await _tapPlus(tester, 'Oats');
      await tester.pumpAndSettle();
      await _tapPlus(tester, 'Milk');
      await tester.pumpAndSettle();

      await tester.tap(_logButton());
      await tester.pumpAndSettle();

      expect(_mealDetailBloc.writes.map((w) => w.name), ['Oats', 'Milk']);
      expect(_mealDetailBloc.writes.first.unit, 'g');
      expect(_mealDetailBloc.writes.first.amount, '100.0');
      expect(_homeBloc.refreshed, isTrue);
      expect(find.byKey(const Key('main')), findsOneWidget);
    });

    testWidgets('a failed write keeps only what was not logged', (
      tester,
    ) async {
      await _register([_meal('Oats'), _meal('Milk')]);
      await _openAddMeal(tester, []);
      await _tapPlus(tester, 'Oats');
      await tester.pumpAndSettle();
      await _tapPlus(tester, 'Milk');
      await tester.pumpAndSettle();
      _mealDetailBloc.failAt = 1;

      await tester.tap(_logButton());
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.logTrayLogFailedLabel), findsOneWidget);
      // Oats is in the diary; retrying must not write it a second time.
      expect(find.text(l10nEn.bulkAddSubmitLabel(1)), findsOneWidget);
      _mealDetailBloc.failAt = null;
      await tester.tap(_logButton());
      await tester.pumpAndSettle();
      expect(_mealDetailBloc.writes.map((w) => w.name), ['Oats', 'Milk']);
    });

    testWidgets('leaving with items on the list asks first', (tester) async {
      await _register([_meal('Oats')]);
      await _openAddMeal(tester, []);
      await _tapPlus(tester, 'Oats');
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.discardChangesTitle), findsOneWidget);
      await tester.tap(find.text(l10nEn.dialogCancelLabel));
      await tester.pumpAndSettle();
      expect(find.byType(AddMealScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nEn.discardChangesConfirmLabel));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('main')), findsOneWidget);
      expect(_mealDetailBloc.writes, isEmpty);
    });

    testWidgets('every screen it opens is handed the same list', (
      tester,
    ) async {
      await _register([_meal('Oats')]);
      final pushed = <RouteSettings>[];
      await _openAddMeal(tester, pushed);

      await tester.tap(_card('Oats'));
      await tester.pumpAndSettle();
      final detail = pushed.last.arguments as MealDetailScreenArguments;
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('add-meal-method-barcode'));
      await tester.pumpAndSettle();
      final scanner = pushed.last.arguments as ScannerScreenArguments;
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('add-meal-method-photo'));
      await tester.pumpAndSettle();
      final review = pushed.last.arguments as BulkAddScreenArguments;

      expect(detail.logTray, isNotNull);
      expect(scanner.logTray, same(detail.logTray));
      expect(review.logTray, same(detail.logTray));
    });

    testWidgets('Quick add puts its entry on the list and stays here', (
      tester,
    ) async {
      await _register([]);
      await _openAddMeal(tester, []);

      await tester.tap(find.bySemanticsIdentifier('add-meal-quick-add'));
      await tester.pumpAndSettle();
      Finder field(String id) => find.descendant(
        of: find.bySemanticsIdentifier(id),
        matching: find.byType(TextField),
      );
      await tester.enterText(field('quick-add-title'), 'Cake');
      await tester.enterText(field('quick-add-energy'), '350');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('quick-add-submit'));
      await tester.pumpAndSettle();

      expect(find.byType(AddMealScreen), findsOneWidget);
      expect(find.text(l10nEn.bulkAddSubmitLabel(1)), findsOneWidget);
      expect(find.text('350 kcal'), findsWidgets);
      expect(_mealDetailBloc.writes, isEmpty);

      await tester.tap(_logButton());
      await tester.pumpAndSettle();
      expect(_mealDetailBloc.writes.single.name, 'Cake');
    });

    testWidgets('+ on a thin search hit uses the full record\'s serving', (
      tester,
    ) async {
      await _register([_meal('Granola', source: MealSourceEntity.off)]);
      _products.full = _meal(
        'Granola',
        source: MealSourceEntity.off,
        servingQuantity: 45,
        servingSize: '45 g',
        detailed: true,
      );
      await _openAddMeal(tester, []);

      await _tapPlus(tester, 'Granola');
      await tester.pumpAndSettle();
      await tester.tap(_logButton());
      await tester.pumpAndSettle();

      expect(_products.lookups, 1);
      final write = _mealDetailBloc.writes.single;
      expect(write.unit, 'serving');
      expect(write.amount, '45.0');
    });

    testWidgets('+ keeps the thin record when the lookup fails', (
      tester,
    ) async {
      await _register([_meal('Granola', source: MealSourceEntity.off)]);
      await _openAddMeal(tester, []);

      await _tapPlus(tester, 'Granola');
      await tester.pumpAndSettle();
      await tester.tap(_logButton());
      await tester.pumpAndSettle();

      expect(_mealDetailBloc.writes.single.unit, 'g');
      expect(_mealDetailBloc.writes.single.amount, '100.0');
    });

    testWidgets('the list cannot change while it is being written', (
      tester,
    ) async {
      await _register([_meal('Oats'), _meal('Milk')]);
      await _openAddMeal(tester, []);
      await _tapPlus(tester, 'Oats');
      await tester.pumpAndSettle();
      await _tapPlus(tester, 'Milk');
      await tester.pumpAndSettle();
      final gate = _mealDetailBloc.gate = Completer<void>();

      await tester.tap(_logButton());
      await tester.pump();
      await tester.tap(
        find.bySemanticsIdentifier('add-meal-tray-remove').first,
        warnIfMissed: false,
      );
      await tester.tap(
        find.bySemanticsIdentifier('add-meal-tray-clear'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text(l10nEn.bulkAddSubmitLabel(2)), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(_mealDetailBloc.writes.map((w) => w.name), ['Oats', 'Milk']);
      expect(find.byKey(const Key('main')), findsOneWidget);
    });

    testWidgets('a food missing a macro opens its detail instead', (
      tester,
    ) async {
      await _register([_meal('Odd', complete: false)]);
      final pushed = <RouteSettings>[];
      await _openAddMeal(tester, pushed);

      await _tapPlus(tester, 'Odd');
      await tester.pumpAndSettle();

      expect(pushed.single.name, NavigationOptions.mealDetailRoute);
      expect(_logButton(), findsNothing);
    });
  });
}
