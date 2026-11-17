import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_l10n.dart';

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

/// A TrendsBloc that answers each range with a canned state, so a pill's
/// effect on the tiles can be asserted without the use cases.
class _RangedTrendsBloc extends TrendsBloc {
  final List<int> loads = [];
  final TrendsLoaded Function(int windowDays, int rangeDays) stateFor;

  _RangedTrendsBloc(this.stateFor)
    : super(
        _FakeGetTrackedDayUsecase(),
        _FakeGetWeightLogUsecase(),
        _FakeGetUserUsecase(),
        _FakeGetConfigUsecase(),
        _FakeGetWaterIntakeUsecase(),
      ) {
    emit(stateFor(7, 7));
  }

  @override
  void add(TrendsEvent event) {
    if (event is LoadTrendsEvent) {
      loads.add(event.rangeDays);
      // "All" resolves to the week of data the states hold.
      emit(
        stateFor(event.rangeDays == 0 ? 7 : event.rangeDays, event.rangeDays),
      );
    }
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Today alone is logged: 1400 kcal of a 2000 goal, 70 g each of carbs, fat
/// and protein, 1400 ml of water, one 80 kg weigh-in. [imperial] asks for
/// fl oz and, unless [unit] says otherwise, pounds; [empty] logs nothing.
TrendsLoaded _loaded(
  int windowDays, {
  int? rangeDays,
  bool imperial = false,
  BodyWeightUnit? unit,
  bool empty = false,
}) => TrendsLoaded(
  rangeDays: rangeDays ?? windowDays,
  windowDays: windowDays,
  days: [
    if (!empty)
      TrackedDayEntity(
        day: _today(),
        calorieGoal: 2000,
        caloriesTracked: 1400,
        carbsTracked: 70,
        fatTracked: 70,
        proteinTracked: 70,
      ),
  ],
  priorWeek: const [],
  weight: [if (!empty) WeightLogEntity(date: _today(), weightKg: 80)],
  bodyWeightUnit: unit ?? (imperial ? BodyWeightUnit.lb : BodyWeightUnit.kg),
  targetWeightKg: null,
  waterByDay: {if (!empty) _today(): 1400},
  waterGoalMl: 2000,
  usesImperialFoodUnits: imperial,
);

Future<_RangedTrendsBloc> _pump(
  WidgetTester tester, {
  Size size = const Size(1080, 2400),
  double textScale = 1,
  bool usesKilojoules = false,
  TrendsLoaded Function(int windowDays, int rangeDays)? stateFor,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = _RangedTrendsBloc(
    stateFor ??
        (windowDays, rangeDays) => _loaded(windowDays, rangeDays: rangeDays),
  );
  locator.registerSingleton<TrendsBloc>(bloc);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: TrendsPage()),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

Finder _tile(String metric) => find.byKey(ValueKey('trends-tile-$metric'));

Finder _inTile(String metric, String text) =>
    find.descendant(of: _tile(metric), matching: find.text(text));

void main() {
  tearDown(() async => locator.reset());

  testWidgets('a tile a metric, each with its headline for the range', (
    tester,
  ) async {
    await _pump(tester);

    // A week: 1400 kcal, 70 g and 1400 ml over 7 days.
    expect(_inTile('calories', '200 / 2000 kcal'), findsOneWidget);
    expect(_inTile('macros', '10 ${l10nEn.gramUnit}'), findsNWidgets(3));
    expect(_inTile('weight', '80 ${l10nEn.kgLabel}'), findsOneWidget);
    expect(_inTile('water', l10nEn.waterChipLabel(200, 2000)), findsOneWidget);
    // The streak card stays above the tiles; the charts are behind them.
    expect(find.text(l10nEn.trendsDayStreakLabel), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('the tiles read in kJ, pounds and fl oz when chosen', (
    tester,
  ) async {
    await _pump(
      tester,
      usesKilojoules: true,
      stateFor: (w, r) => _loaded(w, rangeDays: r, imperial: true),
    );

    // 200 of 2000 kcal; 80 kg; 200 of 2000 ml.
    expect(_inTile('calories', '837 / 8368 ${l10nEn.kjLabel}'), findsOneWidget);
    expect(_inTile('weight', '176.4 ${l10nEn.lbsLabel}'), findsOneWidget);
    expect(_inTile('water', l10nEn.waterChipLabelFlOz(7, 68)), findsOneWidget);
  });

  testWidgets('a range pill reloads at that range and the tiles follow', (
    tester,
  ) async {
    final bloc = await _pump(tester);

    await tester.tap(find.text(l10nEn.trendsRangeMonthLabel));
    await tester.pump();

    expect(bloc.loads, [7, 30]);
    // A month: the same day's intake over 30 days.
    expect(_inTile('calories', '47 / 2000 kcal'), findsOneWidget);
    expect(_inTile('macros', '2 ${l10nEn.gramUnit}'), findsNWidgets(3));
    expect(_inTile('water', l10nEn.waterChipLabel(47, 2000)), findsOneWidget);
  });

  for (final (metric, title, cardText) in [
    ('calories', l10nEn.trendsCaloriesLabel, l10nEn.goalLabel),
    ('macros', l10nEn.trendsMacrosLabel, l10nEn.trendsDailyAverageLabel),
    ('weight', l10nEn.weightHistoryWeightLabel, l10nEn.weightHistoryAddEntry),
    ('water', l10nEn.trendsWaterLabel, l10nEn.waterChipLabel(200, 2000)),
  ]) {
    testWidgets('the $metric tile opens its page', (tester) async {
      await _pump(tester);

      await tester.tap(_tile(metric));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      expect(_tile(metric), findsNothing);
      // The metric's card from the Trends page, with the range pills.
      final shown = cardText == l10nEn.weightHistoryAddEntry
          ? find.byTooltip(cardText)
          : find.text(cardText);
      expect(shown, findsWidgets);
      expect(find.text(l10nEn.trendsRangeWeekLabel), findsOneWidget);
    });
  }

  testWidgets('a range picked on a metric page reloads that page', (
    tester,
  ) async {
    final bloc = await _pump(tester);
    await tester.tap(_tile('water'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.trendsRangeMonthLabel));
    await tester.pump();

    expect(bloc.loads, [7, 30]);
    expect(find.text(l10nEn.waterChipLabel(47, 2000)), findsOneWidget);
  });

  testWidgets('at twice the font on a narrow screen nothing overflows', (
    tester,
  ) async {
    await _pump(tester, size: const Size(360, 3000), textScale: 2);

    expect(tester.takeException(), isNull);
    // One tile a row: the weight tile sits below the macros tile.
    expect(
      tester.getTopLeft(_tile('weight')).dy,
      greaterThan(tester.getBottomLeft(_tile('macros')).dy),
    );
    expect(
      tester.getTopLeft(_tile('weight')).dx,
      tester.getTopLeft(_tile('calories')).dx,
    );

    await tester.tap(_tile('calories'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('6M, 1Y and All reload at 180, 365 and every day', (
    tester,
  ) async {
    final bloc = await _pump(tester);

    for (final label in [
      l10nEn.trendsRangeSixMonthsLabel,
      l10nEn.trendsRangeYearLabel,
      l10nEn.allItemsLabel,
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(bloc.loads, [7, 180, 365, 0]);
  });

  testWidgets('with nothing logged the tiles show no goal and no weight', (
    tester,
  ) async {
    await _pump(
      tester,
      stateFor: (w, r) => _loaded(w, rangeDays: r, empty: true),
    );

    // No day carries a goal, so none is shown.
    expect(_inTile('calories', '0 ${l10nEn.kcalLabel}'), findsOneWidget);
    expect(_inTile('macros', '0 ${l10nEn.gramUnit}'), findsNWidgets(3));
    expect(_inTile('weight', '–'), findsOneWidget);
    expect(_inTile('water', l10nEn.waterChipLabel(0, 2000)), findsOneWidget);

    await tester.tap(_tile('calories'));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.goalLabel), findsNothing);
    expect(find.text('0 ${l10nEn.kcalLabel}'), findsOneWidget);
  });

  testWidgets('a range picked on a metric page holds on the overview', (
    tester,
  ) async {
    final bloc = await _pump(tester);
    await tester.tap(_tile('calories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.trendsRangeMonthLabel));
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(bloc.loads, [7, 30]);
    expect(
      tester
          .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
          .selected,
      {30},
    );
    expect(_inTile('calories', '47 / 2000 kcal'), findsOneWidget);
    expect(_inTile('water', l10nEn.waterChipLabel(47, 2000)), findsOneWidget);
  });

  testWidgets('a small phone at 1.4x font, in kJ and stones, fits', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(360, 800),
      textScale: 1.4,
      usesKilojoules: true,
      stateFor: (w, r) => _loaded(w, rangeDays: r, unit: BodyWeightUnit.st),
    );
    // The list's scrollable, not the pills' sideways one.
    await tester.scrollUntilVisible(
      _tile('water'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Two tiles a row below 1.5x.
    expect(
      tester.getTopLeft(_tile('macros')).dy,
      tester.getTopLeft(_tile('calories')).dy,
    );
    expect(
      _inTile(
        'weight',
        formatBodyWeight(
          80,
          BodyWeightUnit.st,
          kgLabel: l10nEn.kgLabel,
          lbLabel: l10nEn.lbsLabel,
          stLabel: l10nEn.stLabel,
        ),
      ),
      findsOneWidget,
    );
    expect(_inTile('calories', '837 / 8368 ${l10nEn.kjLabel}'), findsOneWidget);

    await tester.tap(_tile('calories'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
