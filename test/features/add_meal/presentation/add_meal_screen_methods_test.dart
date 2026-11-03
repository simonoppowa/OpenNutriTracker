import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/screens/bulk_add_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  final bool imperial;
  final int offsetHours;
  final int offsetMinutes;

  _FakeGetConfigUsecase({
    this.imperial = false,
    this.offsetHours = 0,
    this.offsetMinutes = 0,
  });

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: imperial,
    dayStartOffsetHours: offsetHours,
    dayStartOffsetMinutes: offsetMinutes,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeSearch implements SearchProductsUseCase {
  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(
    meals: <MealEntity>[],
    remoteSourceEmpty: true,
  );

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => const SearchProductsResult(
    meals: <MealEntity>[],
    remoteSourceEmpty: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _YesterdayIntakes extends Fake implements IntakeRepository {
  final List<IntakeEntity> intakes;
  final queries = <({DateTime day, int hours, int minutes})>[];
  bool fail = false;

  _YesterdayIntakes(this.intakes);

  @override
  Future<List<IntakeEntity>> getIntakeByDateAndType(
    IntakeTypeEntity type,
    DateTime date, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    if (fail) throw StateError('read failed');
    queries.add((
      day: date,
      hours: dayStartOffsetHours,
      minutes: dayStartOffsetMinutes,
    ));
    return intakes.where((intake) => intake.type == type).toList();
  }
}

class _Copies extends Fake implements MealDetailBloc {
  final written = <IntakeEntity>[];
  int? failAt;

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async {
    if (failAt == written.length) throw StateError('write failed');
    written.add(
      IntakeEntity(
        id: 'copy-${written.length}',
        unit: unit,
        amount: double.parse(amountText),
        type: type,
        meal: meal,
        dateTime: day,
      ),
    );
  }
}

class _HomeRefresh extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _DiaryRefresh extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _CalendarRefresh extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

late _YesterdayIntakes _intakes;
late _Copies _copies;

IntakeEntity _yesterdayFood(
  String id, {
  String unit = 'g',
  double amount = 123.45,
}) => IntakeEntity(
  id: id,
  unit: unit,
  amount: amount,
  type: IntakeTypeEntity.dinner,
  meal: MealEntity(
    code: id,
    name: id,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: 30,
    servingUnit: 'g',
    servingSize: '1 slice (30 g)',
    nutriments: MealEntity.empty().nutriments,
    source: MealSourceEntity.custom,
  ),
  dateTime: DateTime(2026, 10, 17, 20),
);

Future<void> _openYesterday(WidgetTester tester) async {
  final entry = find.bySemanticsIdentifier('add-meal-reuse-yesterday');
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _chooseMeal(
  WidgetTester tester,
  String identifier,
  String label,
) async {
  await tester.tap(find.bySemanticsIdentifier(identifier));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.text(l10nEn.dialogOKLabel));
  await tester.pumpAndSettle();
}

final getIt = GetIt.instance;
FakeFavourites? _favourites;

Future<void> _register({
  bool imperial = false,
  int offsetHours = 0,
  int offsetMinutes = 0,
  List<IntakeEntity> yesterday = const [],
}) async {
  await getIt.reset();
  final config = _FakeGetConfigUsecase(
    imperial: imperial,
    offsetHours: offsetHours,
    offsetMinutes: offsetMinutes,
  );
  getIt.registerSingleton<GetConfigUsecase>(config);
  _intakes = _YesterdayIntakes(yesterday);
  getIt.registerSingleton<IntakeRepository>(_intakes);
  _copies = _Copies();
  getIt.registerSingleton<MealDetailBloc>(_copies);
  getIt.registerSingleton<HomeBloc>(_HomeRefresh());
  getIt.registerSingleton<DiaryBloc>(_DiaryRefresh());
  getIt.registerSingleton<CalendarDayBloc>(_CalendarRefresh());
  final search = _FakeSearch();
  getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(search, config));
  getIt.registerFactory<FoodBloc>(() => FoodBloc(search, config));
  getIt.registerFactory<RecentMealBloc>(
    () => RecentMealBloc(_FakeGetIntakeUsecase(), config),
  );
  await _favourites?.dispose();
  final favourites = _favourites = FakeFavourites();
  getIt.registerFactory<FavouriteMealBloc>(
    () => FavouriteMealBloc(favourites.get, config),
  );
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
}

/// The add-food screen at the root, and a stub for every route it pushes
/// that records what it was asked for.
Widget _app(List<RouteSettings> pushed) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  onGenerateRoute: (settings) {
    if (settings.name == Navigator.defaultRouteName) {
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
);

void main() {
  setUp(() {
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 18, 12);
  });

  tearDown(() {
    DayBoundaryCalc.clock = DateTime.now;
  });

  testWidgets(
    'yesterday Dinner copies only selected foods to confirmed today Lunch',
    (tester) async {
      final dinner = _yesterdayFood('Dinner food');
      await _register(
        yesterday: [dinner, _yesterdayFood('Not selected', amount: 50)],
      );
      final pushed = <RouteSettings>[];
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: _app(pushed),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('add-meal-method-barcode'));
      await tester.pumpAndSettle();
      final tray = (pushed.single.arguments as ScannerScreenArguments).logTray!;
      final pending = LogTrayItem(
        meal: _yesterdayFood('Pending food').meal,
        unit: 'g',
        amount: 75,
        amountLabel: '75 g',
      );
      tray.add(pending);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await _openYesterday(tester);

      expect(_copies.written, isEmpty);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, l10nEn.dialogOKLabel),
            )
            .onPressed,
        isNull,
      );
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      expect(find.text('Dinner food'), findsOneWidget);
      expect(find.textContaining('123.45'), findsOneWidget);
      await tester.tap(find.text('Dinner food'));
      await tester.pump();
      await _confirm(tester);

      expect(_copies.written, isEmpty);
      expect(find.text('Copy to Sunday, October 18, 2026'), findsOneWidget);
      await _chooseMeal(tester, 'copy-destination-meal', l10nEn.lunchLabel);
      expect(_copies.written, isEmpty);
      await _confirm(tester);

      final copied = _copies.written.single;
      expect(copied.type, IntakeTypeEntity.lunch);
      expect(copied.dateTime, DateTime(2026, 10, 18));
      expect(copied.amount, 123.45);
      expect(copied.unit, dinner.unit);
      expect(copied.meal, same(dinner.meal));
      expect(tray.items, [same(pending)]);
      expect(find.text('Pending food'), findsOneWidget);
      expect(
        _intakes.queries.map((q) => q.day),
        everyElement(DateTime(2026, 10, 17)),
      );
    },
  );

  for (final cancelDestination in [false, true]) {
    testWidgets(
      'cancel ${cancelDestination ? 'destination' : 'source'} does not copy foods',
      (tester) async {
        await _register(yesterday: [_yesterdayFood('Dinner food')]);
        await tester.pumpWidget(_app([]));
        await tester.pumpAndSettle();
        await _openYesterday(tester);
        if (cancelDestination) {
          await _chooseMeal(
            tester,
            'yesterday-source-meal',
            l10nEn.dinnerLabel,
          );
          await tester.tap(find.text('Dinner food'));
          await tester.pump();
          await _confirm(tester);
        }
        await tester.tap(find.text(l10nEn.dialogCancelLabel));
        await tester.pumpAndSettle();
        expect(_copies.written, isEmpty);
        expect(find.byType(AlertDialog), findsNothing);
        // Cancellation does not leave the entry or the screen blocked.
        await _openYesterday(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );
  }

  testWidgets('empty yesterday is safe and cannot be confirmed', (
    tester,
  ) async {
    await _register();
    await tester.pumpWidget(_app([]));
    await tester.pumpAndSettle();
    await _openYesterday(tester);
    expect(find.text(l10nEn.nothingAddedLabel), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, l10nEn.dialogOKLabel),
          )
          .onPressed,
      isNull,
    );
    expect(_copies.written, isEmpty);
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'all source categories are available and switching clears food selection',
    (tester) async {
      await _register(yesterday: [_yesterdayFood('Dinner food')]);
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      await _openYesterday(tester);
      for (final label in [
        l10nEn.breakfastLabel,
        l10nEn.lunchLabel,
        l10nEn.snackLabel,
      ]) {
        await _chooseMeal(tester, 'yesterday-source-meal', label);
        expect(find.text(l10nEn.nothingAddedLabel), findsOneWidget);
      }
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      await tester.tap(find.text('Dinner food'));
      await tester.pump();
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.lunchLabel);
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      expect(_copies.written, isEmpty);
    },
  );

  testWidgets('stored serving amounts are copied without scaling again', (
    tester,
  ) async {
    await _register(
      yesterday: [_yesterdayFood('Two slices', unit: 'serving', amount: 60)],
    );
    await tester.pumpWidget(_app([]));
    await tester.pumpAndSettle();
    await _openYesterday(tester);
    await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
    expect(find.text('60 g'), findsOneWidget);
    await tester.tap(find.text('Two slices'));
    await tester.pump();
    await _confirm(tester);
    await _confirm(tester);
    expect(_copies.written.single.amount, 60);
    expect(_copies.written.single.unit, 'serving');
    // Confirmation uses the logging context, not the source's Dinner.
    expect(_copies.written.single.type, IntakeTypeEntity.breakfast);
  });

  for (final scenario in [
    (
      now: DateTime(2026, 1, 1, 6, 29),
      hours: 6,
      minutes: 30,
      today: DateTime(2025, 12, 31),
      yesterday: DateTime(2025, 12, 30),
    ),
    (
      now: DateTime(2026, 1, 1, 6, 30),
      hours: 6,
      minutes: 30,
      today: DateTime(2026, 1, 1),
      yesterday: DateTime(2025, 12, 31),
    ),
    (
      now: DateTime(2026, 3, 30, 12),
      hours: 4,
      minutes: 0,
      today: DateTime(2026, 3, 30),
      yesterday: DateTime(2026, 3, 29),
    ),
    (
      now: DateTime(2026, 10, 26, 12),
      hours: 4,
      minutes: 0,
      today: DateTime(2026, 10, 26),
      yesterday: DateTime(2026, 10, 25),
    ),
  ]) {
    testWidgets('yesterday uses logical calendar days at ${scenario.now}', (
      tester,
    ) async {
      DayBoundaryCalc.clock = () => scenario.now;
      await _register(
        offsetHours: scenario.hours,
        offsetMinutes: scenario.minutes,
        yesterday: [_yesterdayFood('Dinner food')],
      );
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      await _openYesterday(tester);
      expect(_intakes.queries, hasLength(4));
      expect(
        _intakes.queries.map((q) => q.day),
        everyElement(scenario.yesterday),
      );
      expect(
        _intakes.queries.map((q) => q.hours),
        everyElement(scenario.hours),
      );
      expect(
        _intakes.queries.map((q) => q.minutes),
        everyElement(scenario.minutes),
      );
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      await tester.tap(find.text('Dinner food'));
      await tester.pump();
      await _confirm(tester);
      // A boundary passing while confirming must not silently change the date.
      DayBoundaryCalc.clock = () => DateTime(2027, 1, 1, 12);
      await _confirm(tester);
      expect(_copies.written.single.dateTime, scenario.today);
    });
  }

  testWidgets(
    'yesterday food selection scrolls with large text on a small screen',
    (tester) async {
      await _register(
        yesterday: List.generate(20, (i) => _yesterdayFood('Food $i')),
      );
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'add-food');
      await _openYesterday(tester);
      expect(tester.takeException(), isNull, reason: 'source dialog');
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      expect(tester.takeException(), isNull, reason: 'source foods');
      await tester.scrollUntilVisible(
        find.text('Food 19'),
        200,
        scrollable: find.descendant(
          of: find.bySemanticsIdentifier('yesterday-foods-list'),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Food 19'));
      await tester.pump();
      await _confirm(tester);
      expect(tester.takeException(), isNull);
      await _confirm(tester);
      expect(_copies.written.single.meal.name, 'Food 19');
    },
  );

  testWidgets('read failure reports an error and allows reopening', (
    tester,
  ) async {
    await _register();
    _intakes.fail = true;
    await tester.pumpWidget(_app([]));
    await tester.pumpAndSettle();
    await _openYesterday(tester);
    expect(find.text(l10nEn.reuseYesterdayLoadFailedLabel), findsOneWidget);
    expect(_copies.written, isEmpty);
    _intakes.fail = false;
    await _openYesterday(tester);
    expect(find.text(l10nEn.nothingAddedLabel), findsOneWidget);
  });

  testWidgets(
    'partial copy failure reports the written count without replaying',
    (tester) async {
      await _register(
        yesterday: [_yesterdayFood('First'), _yesterdayFood('Second')],
      );
      _copies.failAt = 1;
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      await _openYesterday(tester);
      await _chooseMeal(tester, 'yesterday-source-meal', l10nEn.dinnerLabel);
      await tester.tap(find.text('First'));
      await tester.tap(find.text('Second'));
      await tester.pump();
      await _confirm(tester);
      await _confirm(tester);
      expect(_copies.written.single.meal.name, 'First');
      expect(
        find.text(l10nEn.reuseYesterdayCopyFailedLabel(1)),
        findsOneWidget,
      );
    },
  );

  testWidgets('the three entry methods sit under the search field', (
    tester,
  ) async {
    await _register();
    await tester.pumpWidget(_app([]));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('add-meal-method-barcode'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('add-meal-method-photo'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('add-meal-method-describe'),
      findsOneWidget,
    );
    expect(find.text(l10nEn.customMealBarcodeLabel), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('add-meal-reuse-yesterday'),
      findsOneWidget,
    );
    expect(find.text(l10nEn.addMealSnapMealLabel), findsOneWidget);
    // The barcode moved from the field's suffix to its own tile, and the
    // second screen's app-bar icon is gone: both now start from here.
    expect(find.bySemanticsIdentifier('meal-search-barcode'), findsNothing);
    expect(find.bySemanticsIdentifier('add-meal-bulk-add'), findsNothing);
  });

  testWidgets('Barcode opens the scanner for this meal', (tester) async {
    await _register();
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('add-meal-method-barcode'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.scannerRoute);
    expect(
      (pushed.single.arguments as ScannerScreenArguments).intakeTypeEntity,
      IntakeTypeEntity.breakfast,
    );
  });

  testWidgets('Describe opens a panel, and Find foods takes the text along', (
    tester,
  ) async {
    await _register(imperial: true);
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('add-meal-describe-input'), findsNothing);
    await tester.tap(find.bySemanticsIdentifier('add-meal-method-describe'));
    await tester.pumpAndSettle();

    // Nothing to find yet, so nothing to tap.
    final submit = find.descendant(
      of: find.bySemanticsIdentifier('add-meal-describe-submit'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.descendant(
        of: find.bySemanticsIdentifier('add-meal-describe-input'),
        matching: find.byType(TextField),
      ),
      '200g broccoli and 3 eggs',
    );
    await tester.pump();
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.bulkAddRoute);
    final args = pushed.single.arguments as BulkAddScreenArguments;
    expect(args.initialText, '200g broccoli and 3 eggs');
    expect(args.startWithPhoto, isFalse);
    expect(args.intakeTypeEntity, IntakeTypeEntity.breakfast);
    expect(args.usesImperialUnits, isTrue);
  });

  testWidgets('Snap meal goes to the review screen ready for a photo', (
    tester,
  ) async {
    await _register();
    final pushed = <RouteSettings>[];
    await tester.pumpWidget(_app(pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('add-meal-method-photo'));
    await tester.pumpAndSettle();

    expect(pushed.single.name, NavigationOptions.bulkAddRoute);
    final args = pushed.single.arguments as BulkAddScreenArguments;
    expect(args.startWithPhoto, isTrue);
    expect(args.initialText, isNull);
  });

  // Portrait and the landscape case #165 was about: the tiles and the open
  // panel scroll inside their own share rather than push the results off.
  for (final size in const [Size(360, 780), Size(780, 360)]) {
    testWidgets('the screen fits with Describe open at $size', (tester) async {
      await _register();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app([]));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('add-meal-method-describe'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsIdentifier('add-meal-describe-input'),
        findsOneWidget,
      );
    });
  }
}
