import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/screens/bulk_add_screen.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

/// One recorded `addIntake` call: what the screen actually asked to be
/// written. The row UI can be right on screen and still hand the wrong
/// number to the write, which is exactly what happened when the raw amount
/// was passed instead of the converted one (4 oz stored as 4 g).
class _Write {
  final String unit;
  final String amount;
  final String? mealName;

  const _Write(this.unit, this.amount, this.mealName);

  @override
  String toString() => '$mealName $amount $unit';
}

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {
  final writes = <_Write>[];
  final bool failOnSecondWrite;

  _FakeMealDetailBloc({this.failOnSecondWrite = false});

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity intakeTypeEntity,
    MealEntity meal,
    DateTime day,
  ) async {
    if (failOnSecondWrite && writes.length == 1) {
      throw StateError('write failed');
    }
    writes.add(_Write(unit, amountText, meal.name));
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

class _FakeSearch implements SearchProductsUseCase {
  final Map<String, List<MealEntity>> results;

  _FakeSearch(this.results);

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => SearchProductsResult(
    meals: results[searchString] ?? const [],
    remoteSourceEmpty: false,
  );

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MealEntity _meal(String name, {double? servingQuantity, String? mealUnit}) =>
    MealEntity(
      code: name,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: mealUnit,
      servingQuantity: servingQuantity,
      servingUnit: null,
      servingSize: null,
      source: MealSourceEntity.off,
      nutriments: const MealNutrimentsEntity(
        energyKcal100: 100,
        carbohydrates100: 0,
        fat100: 0,
        proteins100: 0,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
    );

final getIt = GetIt.instance;

late _FakeMealDetailBloc _mealDetailBloc;
late _FakeHomeBloc _homeBloc;

/// Registers the graph the screen reaches for through the locator. The
/// BulkAddBloc is the *real* one over a stubbed search, so the parse ->
/// resolve -> row pipeline under test is the shipping one; only the data
/// source and the write target are faked.
Future<void> _register(
  Map<String, List<MealEntity>> results, {
  bool failOnSecondWrite = false,
}) async {
  await getIt.reset();
  _mealDetailBloc = _FakeMealDetailBloc(failOnSecondWrite: failOnSecondWrite);
  _homeBloc = _FakeHomeBloc();
  getIt.registerFactory<BulkAddBloc>(
    () => BulkAddBloc(
      ResolveParsedMealsUseCase(_FakeSearch(results)),
      ReadMealTextUseCase(
        AiCredentialStorage(_EmptyStorage()),
        (_) => throw StateError('must not be built without a key'),
      ),
    ),
  );
  getIt.registerFactory<MealDetailBloc>(() => _mealDetailBloc);
  getIt.registerFactory<HomeBloc>(() => _homeBloc);
  getIt.registerFactory<DiaryBloc>(() => _FakeDiaryBloc());
  getIt.registerFactory<CalendarDayBloc>(() => _FakeCalendarDayBloc());
}

/// The screen reads its arguments off the route and pops back to
/// `mainRoute`, so it needs a real navigator with that route named. The
/// rows render kcal through `EnergyDisplay`, which reads the provider.
Widget _app({bool imperial = false, Locale? locale}) =>
    ChangeNotifierProvider<EnergyUnitProvider>(
      create: (_) => EnergyUnitProvider(usesKilojoules: false),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        locale: locale,
        initialRoute: NavigationOptions.mainRoute,
        onGenerateRoute: (settings) {
          if (settings.name == NavigationOptions.mainRoute) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: SizedBox()),
            );
          }
          return MaterialPageRoute<void>(
            settings: RouteSettings(
              name: settings.name,
              arguments: BulkAddScreenArguments(
                IntakeTypeEntity.breakfast,
                DateTime(2026, 8, 10),
                imperial,
              ),
            ),
            builder: (_) => const BulkAddScreen(),
          );
        },
      ),
    );

/// Pushes the screen, types [text] and taps Search, then settles.
Future<void> _parse(WidgetTester tester, String text) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushNamed('/bulk');
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, text);
  // By icon, not label: these tests also pump a German locale, where the
  // button reads something else entirely.
  await tester.tap(find.widgetWithIcon(FilledButton, Icons.search));
  await tester.pumpAndSettle();
}

Finder _submitButton() => find.widgetWithIcon(FilledButton, Icons.add_rounded);

void main() {
  tearDown(() async => getIt.reset());

  testWidgets('writes one intake per loggable row, in order', (tester) async {
    await _register({
      'toast': [_meal('Toast')],
      'eggs': [_meal('Egg')],
      'milk': [_meal('Milk')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, 2 eggs, 200g milk');

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(_mealDetailBloc.writes.map((w) => w.mealName).toList(), [
      'Toast',
      'Egg',
      'Milk',
    ]);
    expect(_homeBloc.refreshed, isTrue);
  });

  testWidgets('converts the amount before writing it', (tester) async {
    // The row shows "4 oz"; the intake must be stored in grams, because
    // IntakeEntity.totalKcal multiplies by a per-gram value and does no
    // conversion of its own. Writing "4" here is a ~28x under-count.
    await _register({
      'steak': [_meal('Steak', mealUnit: 'g')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '4oz steak');

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    final write = _mealDetailBloc.writes.single;
    expect(write.unit, 'oz');
    expect(double.parse(write.amount), closeTo(113.4, 0.1));
  });

  testWidgets('converts a serving into its base quantity', (tester) async {
    await _register({
      'eggs': [_meal('Egg', servingQuantity: 50)],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '2 eggs');

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    final write = _mealDetailBloc.writes.single;
    expect(write.unit, 'serving');
    expect(double.parse(write.amount), 100); // 2 servings x 50 g
  });

  testWidgets('an invalid amount blocks the whole batch', (tester) async {
    // All-or-nothing: addIntake parses the amount with no guard, so one bad
    // row must stop the write before anything lands rather than throwing
    // partway and leaving earlier rows already in the diary.
    await _register({
      'toast': [_meal('Toast')],
      'eggs': [_meal('Egg')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, 2 eggs');

    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(_mealDetailBloc.writes, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('a skipped row is not written', (tester) async {
    await _register({
      'toast': [_meal('Toast')],
      'eggs': [_meal('Egg')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, 2 eggs');

    await tester.tap(find.text(l10nEn.bulkAddSkipLabel).first);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(_mealDetailBloc.writes.map((w) => w.mealName), ['Egg']);
  });

  testWidgets('an unmatched row is flagged and never written', (tester) async {
    await _register({
      'toast': [_meal('Toast')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, unicorn steak');

    expect(find.text(l10nEn.bulkAddNoMatchLabel), findsOneWidget);

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(_mealDetailBloc.writes.map((w) => w.mealName), ['Toast']);
  });

  testWidgets('a bare count with nothing to count is flagged', (tester) async {
    // #622. Device-verified, but it belongs in CI: the label is the only
    // signal that the row's number does not mean what the user typed.
    await _register({
      'eggs': [_meal('Egg')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '2 eggs');

    expect(find.text(l10nEn.bulkAddCheckAmountLabel), findsOneWidget);
  });

  testWidgets('a countable food shows no warning', (tester) async {
    await _register({
      'eggs': [_meal('Egg', servingQuantity: 50)],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '2 eggs');

    expect(find.text(l10nEn.bulkAddCheckAmountLabel), findsNothing);
  });

  testWidgets('parse errors are shown alongside the rows that parsed', (
    tester,
  ) async {
    await _register({
      'toast': [_meal('Toast')],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, 123');

    // The good row survives and the bad one is named by its position, so a
    // rejected item is never a silent drop. Asserted through the ARB string
    // rather than a literal, so the localized text is what is checked.
    expect(find.text('Toast'), findsOneWidget);
    expect(find.text(l10nEn.bulkAddErrorInvalidName(2)), findsOneWidget);

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(_mealDetailBloc.writes.map((w) => w.mealName), ['Toast']);
  });

  testWidgets('a failed write surfaces and does not navigate away', (
    tester,
  ) async {
    await _register({
      'toast': [_meal('Toast')],
      'eggs': [_meal('Egg')],
    }, failOnSecondWrite: true);
    await tester.pumpWidget(_app());
    await _parse(tester, '100g toast, 2 eggs');

    await tester.tap(_submitButton());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    // Still on the bulk screen rather than popped to Home, so the user is
    // not told the meal was logged when it was not.
    expect(find.byType(BulkAddScreen), findsOneWidget);
    // Documenting the limit of the up-front validation: it stops a *bad
    // row* from starting the batch, but a store that fails mid-loop still
    // leaves earlier rows written, and there is no rollback. The user is
    // shown the error and left on the screen to sort it out.
    expect(_mealDetailBloc.writes, hasLength(1));
  });

  testWidgets('picking a different candidate updates the row', (tester) async {
    await _register({
      'eggs': [_meal('Egg'), _meal('Egg, boxed', servingQuantity: 60)],
    });
    await tester.pumpWidget(_app());
    await _parse(tester, '2 eggs');

    await tester.tap(find.text('Egg'));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.bulkAddChooseFoodLabel), findsOneWidget);

    await tester.tap(find.text('Egg, boxed').last);
    await tester.pumpAndSettle();

    expect(find.text('Egg, boxed'), findsOneWidget);
    expect(find.text(l10nEn.bulkAddCheckAmountLabel), findsNothing);
  });

  testWidgets('parse errors render in the app locale, not English', (
    tester,
  ) async {
    // #631. These were built as English literals inside the parser, so a
    // German user saw "Item 2: not a valid food name" in an otherwise
    // translated screen. The parser now reports a kind and an index and the
    // screen builds the sentence, so this asserts the German text.
    await _register({
      'toast': [_meal('Toast')],
    });
    await tester.pumpWidget(_app(locale: const Locale('de')));
    await _parse(tester, '100g toast, 123');

    final de = lookupS(const Locale('de'));
    expect(find.text(de.bulkAddErrorInvalidName(2)), findsOneWidget);
    expect(find.text('Item 2: not a valid food name'), findsNothing);
  });

  testWidgets('a rejected bound is reported with its number', (tester) async {
    await _register({});
    await tester.pumpWidget(_app());
    await _parse(tester, '15kg flour');

    expect(
      find.text(l10nEn.bulkAddErrorQuantityTooLarge(1, 10000)),
      findsOneWidget,
    );
  });
}


/// A keystore with nothing in it, so the read use case always takes the
/// deterministic path.
class _EmptyStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
