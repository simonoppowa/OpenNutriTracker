import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
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
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
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
  // The screen asks this directly, to decide whether to offer the camera at
  // all. Empty storage means no key, so the action stays hidden.
  getIt.registerLazySingleton<AiCredentialStorage>(
    () => AiCredentialStorage(_EmptyStorage()),
  );
  getIt.registerFactory<BulkAddBloc>(
    () => BulkAddBloc(
      ResolveParsedMealsUseCase(_FakeSearch(results)),
      ReadMealTextUseCase(
        AiCredentialStorage(_EmptyStorage()),
        (_) => throw StateError('must not be built without a key'),
      ),
      ReadMealPhotoUseCase(
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

/// Same graph, but the bloc is a singleton over a stubbed photo reader so a
/// test can hold the instance the screen holds and drive a photo read
/// without a picker. Returns that bloc.
Future<BulkAddBloc> _registerWithPhotoReading(
  MealPhotoReadResult reading,
) async {
  await _register(const {});
  final bloc = BulkAddBloc(
    ResolveParsedMealsUseCase(_FakeSearch(const {})),
    ReadMealTextUseCase(
      AiCredentialStorage(_EmptyStorage()),
      (_) => throw StateError('must not be built without a key'),
    ),
    _StubPhotoReader(reading),
  );
  getIt.unregister<BulkAddBloc>();
  getIt.registerSingleton<BulkAddBloc>(bloc);
  return bloc;
}

/// Same graph, but the text reader always fails the given way and a key *is*
/// present, so the screen renders the "the model was skipped" notice.
Future<BulkAddBloc> _registerWithFailingReader(
  Map<String, List<MealEntity>> results,
  MealInterpreterException failure,
) async {
  await _register(results);
  final bloc = BulkAddBloc(
    ResolveParsedMealsUseCase(_FakeSearch(results)),
    ReadMealTextUseCase(
      AiCredentialStorage(
        _MapStorage({
          'AiApiKeyTag.anthropic': 'sk-test',
          'AiAssistEnabledTag': 'true',
        }),
      ),
      (_) => _AlwaysFailsInterpreter(failure),
    ),
    ReadMealPhotoUseCase(
      AiCredentialStorage(_EmptyStorage()),
      (_) => throw StateError('must not be built without a key'),
    ),
  );
  getIt.unregister<BulkAddBloc>();
  getIt.registerSingleton<BulkAddBloc>(bloc);
  return bloc;
}

class _AlwaysFailsInterpreter implements MealTextInterpreter {
  final MealInterpreterException failure;

  _AlwaysFailsInterpreter(this.failure);

  @override
  Future<MealTextParseResult> interpret(String input, {String? localeCode}) =>
      throw failure;
}

class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;

  _MapStorage(this.values);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The screen reads its arguments off the route and pops back to
/// `mainRoute`, so it needs a real navigator with that route named. The
/// rows render kcal through `EnergyDisplay`, which reads the provider.
/// Records the names of routes pushed, so "the button goes somewhere" is an
/// assertion rather than a hope.
class _PushRecorder extends NavigatorObserver {
  _PushRecorder(this.names);
  final List<String?> names;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    names.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

Widget _app({bool imperial = false, Locale? locale, List<String?>? pushed}) =>
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
        navigatorObservers: [if (pushed != null) _PushRecorder(pushed)],
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

  testWidgets('a rejected key is stated, and fits a phone in German', (
    tester,
  ) async {
    // The German string is 139 characters against a three-line cap. The two
    // layout bugs already found on this feature were both "fits the test
    // viewport, not the handset", so this pins the real one.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'unauthorized',
      failure: MealInterpreterFailure.auth,
      statusCode: 401,
    ));

    await tester.pumpWidget(_app(locale: const Locale('de')));
    await tester.pumpAndSettle();
    // Through the real navigator: a widget test that asserts against a
    // screen it never pushed is the failure this project has already had
    // once, and it passes for the wrong reason rather than failing.
    await _parse(tester, '100g toast');

    final de = lookupS(const Locale('de'));
    expect(find.text(de.bulkAddModelKeyRejectedLabel), findsOneWidget);
    // The rows survive: reporting the failure must not cost the entry.
    expect(find.textContaining('Toast'), findsWidgets);
    expect(
      tester.takeException(),
      isNull,
      reason: 'the notice must not overflow its row',
    );
  });

  testWidgets('an out-of-credit notice does not wear a broken-key icon', (
    tester,
  ) async {
    // The icon was hardcoded to key_off for every model failure, so the
    // billing notice read "you are out of credit" beside a glyph saying the
    // key is broken. Telling these failures apart is worth nothing if the
    // icon still sends the user to the one thing that is not wrong.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'no credit',
      failure: MealInterpreterFailure.billing,
      statusCode: 402,
    ));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    final s = lookupS(const Locale('en'));
    expect(find.text(s.bulkAddModelNoCreditLabel), findsOneWidget);
    expect(find.byIcon(Icons.credit_card_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.key_off_rounded), findsNothing);
    // The parser rows still stand: saying why the model did not run must
    // not cost the user their entry.
    expect(find.textContaining('Toast'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a timed-out server is not dressed up as a network problem', (
    tester,
  ) async {
    // #774. Measured against a real Ollama: two of three requests failed on
    // a cold model load, and every one of them was reported as `transient`,
    // whose advice is to check the connection. The connection was fine — the
    // model was loading — so the user was sent to debug a network problem
    // that did not exist, about a server on their own desk.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'request timed out',
      failure: MealInterpreterFailure.timeout,
    ));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    expect(find.text(l10nEn.bulkAddModelTimedOutLabel), findsOneWidget);
    // The sentence must not send the user to their router, and neither must
    // the glyph beside it.
    expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    // Reporting it must not cost the entry: the parser rows still stand.
    expect(find.textContaining('Toast'), findsWidgets);
  });

  testWidgets('the whole notice is readable at 2x on a narrow screen', (
    tester,
  ) async {
    // #777. The notice was capped at three lines on the reasoning that these
    // strings run long in German. Measured through the widget's own style
    // and width, every one of them overran it — in English too — and the
    // half that vanished was the advice, because the advice came last.
    //
    // No cap survives the combination that matters: German at 2x on a 320dp
    // screen needed twenty lines, which is exactly when a reader needs the
    // words. So the advice became a control, the sentence became the cause
    // alone, and the cap went. This pins the worst case measured.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'request timed out',
      failure: MealInterpreterFailure.timeout,
    ));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(locale: const Locale('de')),
      ),
    );
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    final de = lookupS(const Locale('de'));
    final notice = tester.renderObject<RenderParagraph>(
      find.text(de.bulkAddModelTimedOutLabel),
    );

    expect(
      notice.didExceedMaxLines,
      isFalse,
      reason: 'the sentence saying why the model was skipped is cut off',
    );
    // The cap being gone is the fix, not an implementation detail: any
    // maxLines put back here truncates German at this size.
    expect(notice.maxLines, isNull);
    // Clean now: #820 removed the vertical overflow, #824 the horizontal ones
    // in the rows that it uncovered.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row fits at 2x on an ordinary phone, unit and all', (
    tester,
  ) async {
    // #824. 320dp is the bound; 411dp at 2x is the combination people
    // actually meet, being a Pixel at the accessibility size they actually
    // choose. The food carries a serving, so the unit dropdown has to hold a
    // word rather than "g" — and a unit clipped to "Por" is not a narrower
    // reading of the amount, it is a different one.
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _register({
      'toast': [_meal('Toast', servingQuantity: 30)],
    });

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.toString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(locale: const Locale('de')),
      ),
    );
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    // Put the handler back before asserting. While it is still installed a
    // failed `expect` is an error the framework cannot reconcile, so the test
    // hangs to its ten-minute timeout instead of failing.
    FlutterError.onError = previous;
    expect(
      errors.where((e) => e.contains('overflowed')),
      isEmpty,
      reason: 'something on this row does not fit the space it is given',
    );

    // The dropdown shows one unit but sizes itself to its widest, so this is
    // the width the row has to find even while "g" is the one on screen. Its
    // other items are not in the tree to be found, only measured against.
    final de = lookupS(const Locale('de'));
    final dropdown = find.byType(DropdownButton<String>);
    final needed = (TextPainter(
      text: TextSpan(
        text: de.servingLabel,
        style: Theme.of(tester.element(dropdown)).textTheme.titleMedium,
      ),
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(2.0),
    )..layout()).width;
    expect(
      tester.getSize(dropdown).width,
      greaterThanOrEqualTo(needed),
      reason: 'the unit dropdown is narrower than the unit it has to show, '
          'and a clipped unit reads as a different one',
    );
  });

  testWidgets('the quantity box holds the largest amount at 2x', (
    tester,
  ) async {
    // #824. Where the screen is wide enough to keep the controls on one line
    // the box is a fixed width, and the fixed width was the original bug: at
    // 2x, 10000 — the largest amount this screen accepts — no longer fits the
    // 110px the box used to get, so the number the user typed scrolled out of
    // its own field.
    tester.view.physicalSize = const Size(800 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _register({
      'toast': [_meal('Toast')],
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(locale: const Locale('de')),
      ),
    );
    await tester.pumpAndSettle();
    await _parse(tester, '10000g toast');

    final field = find.byType(TextField).last;
    final needed = (TextPainter(
      text: TextSpan(
        text: '10000',
        style: Theme.of(tester.element(field)).textTheme.bodyLarge,
      ),
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(2.0),
    )..layout()).width;

    expect(
      tester.getSize(field).width,
      greaterThan(needed),
      reason: 'the amount box cannot show the largest amount it accepts',
    );
  });

  testWidgets('the screen fits at 2x on a narrow phone, in German', (
    tester,
  ) async {
    // #820. Only the row list could give ground: the entry block and the
    // submit bar were both fixed, and at 2x they measured 388 and 192 against
    // about 595 of body — so the rows got nothing and the column overflowed
    // by 14px. German, because the buttons carry the longest labels.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'request timed out',
      failure: MealInterpreterFailure.timeout,
    ));

    // Collected rather than asserted away, so the assertion can name what it
    // covers. It began downwards-only: fixing the vertical overflow (#820)
    // uncovered horizontal ones in the rows — 65 and 244 pixels — masked
    // until then because layout aborted before reaching them. #824 fixed
    // those, so it now covers both directions. A blanket `takeException`
    // would pass while the screen overflowed again, which is the regression
    // this exists to catch.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.toString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: _app(locale: const Locale('de')),
      ),
    );
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    // Put the handler back before asserting. While it is still installed a
    // failed `expect` is an error the framework cannot reconcile, so the test
    // hangs to its ten-minute timeout instead of failing.
    FlutterError.onError = previous;
    expect(
      errors.where((e) => e.contains('overflowed')),
      isEmpty,
      reason: 'something on this screen does not fit the space it is given',
    );

    final input = tester
        .getSize(find.bySemanticsIdentifier('bulk-add-input'))
        .height;
    final submit = tester
        .getSize(find.bySemanticsIdentifier('bulk-add-submit'))
        .height;
    final parse = tester
        .getSize(find.bySemanticsIdentifier('bulk-add-parse'))
        .height;

    expect(
      input,
      lessThanOrEqualTo(640 * 0.3),
      reason: 'the field is what gives ground, so the rows do not have to',
    );
    // The rows are what was being squeezed to nothing. 32 of padding above
    // and 32 below the two buttons, and a 1px divider.
    expect(
      input + parse + submit + 65,
      lessThan(640),
      reason: 'the fixed children have to leave the list some height',
    );
  });


  testWidgets('the advice is a control, so nothing can truncate it', (
    tester,
  ) async {
    // The other half of #777. Every one of these failures is answered in the
    // same place, and a button cannot be ellipsised at any text scale — which
    // is what the tail of a sentence could not promise.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'no credit',
      failure: MealInterpreterFailure.billing,
    ));

    final pushed = <String?>[];
    await tester.pumpWidget(_app(pushed: pushed));
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    final action = find.bySemanticsIdentifier('bulk-add-notice-action');
    expect(action, findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(
      pushed,
      contains(NavigationOptions.settingsRoute),
      reason: 'the advice has to go somewhere the user can act',
    );
    expect(tester.takeException(), isNull);
  });


  testWidgets('a refused destination is not dressed as a network fault', (
    tester,
  ) async {
    // #758. The app declined to send; nothing failed to connect. A wifi
    // glyph or "try again later" here would send the user to fix the one
    // thing that is working.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'plaintext to a public address',
      failure: MealInterpreterFailure.insecureDestination,
    ));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    expect(find.text(l10nEn.bulkAddModelInsecureServerLabel), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    // The rows survive: refusing to send must not cost the entry.
    expect(find.textContaining('Toast'), findsWidgets);
  });

  testWidgets('and it fits the notice in German, unlike its siblings', (
    tester,
  ) async {
    // #777 found every string in this family is ellipsised at three lines on
    // a handset — `bulkAddModelNoCreditLabel` is 181 German characters
    // against a budget of roughly 80. This one was written to the measured
    // budget instead of to the family's length, so it is the first that can
    // actually be read to the end.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await _registerWithFailingReader({
      'toast': [_meal('Toast')],
    }, const MealInterpreterException(
      'plaintext to a public address',
      failure: MealInterpreterFailure.insecureDestination,
    ));

    await tester.pumpWidget(_app(locale: const Locale('de')));
    await tester.pumpAndSettle();
    await _parse(tester, '100g toast');

    final de = lookupS(const Locale('de'));
    final notice = tester.renderObject<RenderParagraph>(
      find.text(de.bulkAddModelInsecureServerLabel),
    );

    expect(
      notice.didExceedMaxLines,
      isFalse,
      reason:
          'the German string is ellipsised — it must stay inside the '
          'three-line cap, which is about 80 characters at this size',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the photo sheet names the destination that is actually used', (
    tester,
  ) async {
    // The sheet is the last moment a user can decline sending a photograph.
    // It named Anthropic unconditionally until a Pixel 6 showed it doing so
    // while OpenRouter was selected — a false statement at exactly the
    // moment the statement matters.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    getIt.registerLazySingleton<AiCredentialStorage>(
      () => AiCredentialStorage(
        _MapStorage({
          'AiApiKeyTag.openrouter': 'sk-or-test',
          'AiAssistEnabledTag': 'true',
          'AiProviderTag': 'openrouter',
        }),
      ),
    );

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();

    final vendor = AiModelCatalogue.defaultFor(AiProvider.openrouter)!.servedBy;
    expect(
      find.textContaining(l10nEn.bulkAddPhotoDisclosureOpenRouter(vendor)),
      findsOneWidget,
    );
    // A broker hop has two ends and the sheet has to name both.
    expect(find.textContaining('OpenRouter'), findsWidgets);
    expect(find.textContaining(vendor), findsWidgets);
    // The sentence true either way is still there, once.
    expect(
      find.textContaining(l10nEn.bulkAddPhotoDisclosureCommon),
      findsOneWidget,
    );
  });

  testWidgets('a photo with no food says so, not "nothing to log yet"', (
    tester,
  ) async {
    // Driving this on a Pixel 6, a photo the model found no food in landed
    // on the same line an untouched screen shows. The user had just handed
    // the app a photograph and got back a message that reads as though
    // nothing happened — and the notice saying a model answered is not
    // drawn on the empty branch, so nothing on screen mentioned the photo.
    final bloc = await _registerWithPhotoReading(
      const MealPhotoRead(MealTextParseResult(items: [], errors: [])),
    );
    await tester.pumpWidget(_app());
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/bulk');
    await tester.pumpAndSettle();

    bloc.add(
      ReadMealPhotoEvent(
        photo: MealPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          mediaType: 'image/webp',
        ),
        usesImperialUnits: false,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await S.delegate.load(const Locale('en'));
    expect(find.text(l10n.bulkAddPhotoNoFoodLabel), findsOneWidget);
    expect(find.text(l10n.bulkAddNothingToLogLabel), findsNothing);
  });

  testWidgets('a refused photo destination points at the address, not the model', (
    tester,
  ) async {
    final bloc = await _registerWithPhotoReading(
      const MealPhotoFailed(MealPhotoFailure.insecureDestination),
    );
    await tester.pumpWidget(_app());
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/bulk');
    await tester.pumpAndSettle();

    bloc.add(
      ReadMealPhotoEvent(
        photo: MealPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          mediaType: 'image/webp',
        ),
        usesImperialUnits: false,
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await S.delegate.load(const Locale('en'));
    expect(find.text(l10n.bulkAddModelInsecureServerLabel), findsOneWidget);
    expect(find.text(l10n.bulkAddPhotoUnsupportedLabel), findsNothing);
  });

  testWidgets('an empty text parse still shows the generic line', (
    tester,
  ) async {
    // The photo wording must not leak onto the path it was not written for.
    await _register(const {});
    await tester.pumpWidget(_app());
    await _parse(tester, '');

    final l10n = await S.delegate.load(const Locale('en'));
    expect(find.text(l10n.bulkAddNothingToLogLabel), findsOneWidget);
    expect(find.text(l10n.bulkAddPhotoNoFoodLabel), findsNothing);
  });

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

  testWidgets('the camera is hidden with no credential at all', (
    tester,
  ) async {
    // The other half of the gate, and the one a destination-only check let
    // through: an install that has never opened settings resolves a
    // destination anyway, because nothing stored reads as Anthropic (#688)
    // and an absent model id falls back to the list's first entry. Every
    // such user was offered a camera whose sheet names Anthropic and whose
    // request cannot be signed.
    await _register(const {});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(await getIt<AiCredentialStorage>().isEnabled(), isFalse);
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });

  testWidgets('the camera is hidden once the user switches the feature off', (
    tester,
  ) async {
    // Pausing is the cheap act `setEnabled` exists for, and it has to reach
    // the camera as well as the text path — a destination stays perfectly
    // resolvable while the user is telling the app not to use it.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    final storage = AiCredentialStorage(
      _MapStorage({
        'AiProviderTag': 'anthropic',
        'AiApiKeyTag.anthropic': 'sk-test',
        'AiAssistEnabledTag': 'false',
      }),
    );
    getIt.registerLazySingleton<AiCredentialStorage>(() => storage);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });

  testWidgets('the camera is hidden for a server nobody has probed', (
    tester,
  ) async {
    // Found on a Pixel 6, not here. With an address configured the feature
    // *is* enabled, so gating the icon on `isEnabled()` alone put a camera in
    // the app bar that did nothing. #735 settled what stands in for the
    // behavioural screen the project cannot run against a machine it has
    // never seen — a setup-time self-test — and until one has passed, nothing
    // has established that the model on the other end can see. The photo path
    // has no deterministic fallback, so offering it is offering a dead end.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    // Seeded rather than written, so the assertion is about what the screen
    // does with stored state and does not depend on the writer.
    final storage = AiCredentialStorage(
      _MapStorage({
        'AiProviderTag': 'ownServer',
        'AiEndpointTag.ownServer': 'http://192.168.1.5:11434',
        'AiModelTag.ownServer': 'gemma3:4b',
      }),
    );
    getIt.registerLazySingleton<AiCredentialStorage>(() => storage);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(
      await storage.isEnabled(),
      isTrue,
      reason: 'the feature is on; only the photo path is unproven',
    );
    expect(
      (await storage.readProbe()).photo,
      AiCapability.unknown,
      reason: 'guard against asserting on a state the seed did not create',
    );
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });

  testWidgets('the camera is hidden when the photo probe failed', (
    tester,
  ) async {
    // The gate is the *photo* half and only that half. This seed passes the
    // text probe, which is the state a text-only model on the user's own
    // hardware produces — the commonest thing they will have pulled. #735
    // made the two consequences deliberately asymmetric: a failed text probe
    // only warns, because the deterministic parser is still underneath it,
    // and a failed photo probe takes the camera away, because nothing is.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    final storage = AiCredentialStorage(
      _MapStorage({
        'AiProviderTag': 'ownServer',
        'AiEndpointTag.ownServer': 'http://192.168.1.5:11434',
        'AiModelTag.ownServer': 'gemma3:4b',
        // `text` first, `photo` second — see `AiEndpointProbe.encode`.
        'AiProbeTag.ownServer': 'pf',
      }),
    );
    getIt.registerLazySingleton<AiCredentialStorage>(() => storage);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(
      (await storage.readProbe()).text,
      AiCapability.passed,
      reason: 'the text half passed, so this is the photo half being read',
    );
    expect(find.byIcon(Icons.photo_camera_rounded), findsNothing);
  });

  testWidgets('the camera appears once the photo probe has passed', (
    tester,
  ) async {
    // #781. The strongest privacy story the feature has, and the only
    // destination the app can name exactly rather than by company — but the
    // stored pass is the whole gate, and nothing else opens it.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    final storage = AiCredentialStorage(
      _MapStorage({
        'AiProviderTag': 'ownServer',
        'AiEndpointTag.ownServer': 'http://192.168.1.5:11434',
        'AiModelTag.ownServer': 'gemma3:4b',
        // Photo passed, text never established. The photo half is what this
        // screen reads, and it does not need the other one.
        'AiProbeTag.ownServer': '-p',
      }),
    );
    getIt.registerLazySingleton<AiCredentialStorage>(() => storage);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
  });

  testWidgets('the photo sheet names the address and no company', (
    tester,
  ) async {
    // The address is the whole of what the app knows about this destination,
    // and #736 settled that it is also the whole of what the sheet may claim.
    // Not "no third party receives it", however tempting: a self-hosted proxy
    // forwarding to OpenAI looks identical from here.
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    getIt.registerLazySingleton<AiCredentialStorage>(
      () => AiCredentialStorage(
        _MapStorage({
          'AiProviderTag': 'ownServer',
          // Stored as `writeEndpoint` really stores it — resolved, with the
          // chat route on the end — so this also pins that the sheet shows
          // the host and drops a path that distinguishes nothing.
          'AiEndpointTag.ownServer':
              'http://192.168.1.5:11434/v1/chat/completions',
          'AiModelTag.ownServer': 'gemma3:4b',
          'AiProbeTag.ownServer': '-p',
        }),
      ),
    );

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        l10nEn.bulkAddPhotoDisclosureOwnServer('192.168.1.5:11434'),
      ),
      findsOneWidget,
    );
    // Every company this app has ever sent a photograph to. None of them is
    // known to be involved here, and saying one would be a false statement
    // at exactly the moment the statement matters.
    for (final company in ['Anthropic', 'OpenAI', 'OpenRouter']) {
      expect(
        find.textContaining(company),
        findsNothing,
        reason: 'the sheet names $company for a machine it knows nothing about',
      );
    }
    // The app's own no-copy sentence is about this app, so it survives
    // unchanged — and appears once, not twice.
    expect(
      find.textContaining(l10nEn.bulkAddPhotoDisclosureCommon),
      findsOneWidget,
    );
  });

  testWidgets('the same harness does show the camera for a hosted provider', (
    tester,
  ) async {
    await _register(const {});
    getIt.unregister<AiCredentialStorage>();
    final storage = AiCredentialStorage(
      _MapStorage({
        'AiProviderTag': 'anthropic',
        'AiApiKeyTag.anthropic': 'sk-test',
      }),
    );
    getIt.registerLazySingleton<AiCredentialStorage>(() => storage);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/bulk');
    await tester.pumpAndSettle();

    expect(await storage.isEnabled(), isTrue);
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
  });
}

/// Returns a fixed reading without touching a credential or a network.
class _StubPhotoReader implements ReadMealPhotoUseCase {
  final MealPhotoReadResult reading;

  _StubPhotoReader(this.reading);

  @override
  Future<MealPhotoReadResult> read(
    MealPhoto photo, {
    String? localeCode,
  }) async => reading;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
