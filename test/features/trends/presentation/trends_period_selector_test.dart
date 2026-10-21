import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/trends/domain/trends_period.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/trends_period_selector.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

void main() {
  final today = DateTime(2026, 10, 21);

  Future<List<LoadTrendsEvent>> pump(
    WidgetTester tester, {
    int rangeDays = 7,
    TrendsPeriod? period,
  }) async {
    final loads = <LoadTrendsEvent>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: TrendsPeriodSelector(
            rangeDays: rangeDays,
            period: period,
            onLoad: loads.add,
            today: () => today,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return loads;
  }

  testWidgets('the week chip loads the current calendar week', (tester) async {
    final loads = await pump(tester);

    await tester.tap(find.text(l10nEn.trendsWeekLabel));

    expect(loads.single.period, TrendsPeriod.week(today));
  });

  testWidgets('the month chip loads the current month', (tester) async {
    final loads = await pump(tester);

    await tester.tap(find.text(l10nEn.trendsMonthLabel));

    expect(loads.single.period, TrendsPeriod.month(today));
  });

  testWidgets('a week shows its number and steps back and forth', (
    tester,
  ) async {
    final week = TrendsPeriod.week(today);
    final loads = await pump(tester, period: week);

    expect(
      find.textContaining(l10nEn.trendsCalendarWeekLabel(43)),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(l10nEn.trendsPreviousPeriod));
    await tester.tap(find.byTooltip(l10nEn.trendsNextPeriod));

    expect(loads.map((e) => e.period), [week.step(-1), week.step(1)]);
  });

  testWidgets('the days chips drop the period', (tester) async {
    final loads = await pump(tester, period: TrendsPeriod.week(today));

    await tester.tap(find.text('30d'));

    expect(loads.single.period, isNull);
    expect(loads.single.rangeDays, 30);
  });

  testWidgets('without a week or month there is nothing to step', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byTooltip(l10nEn.trendsPreviousPeriod), findsNothing);
  });

  testWidgets('the custom chip opens a date range picker', (tester) async {
    await pump(tester);

    await tester.tap(find.text(l10nEn.trendsCustomPeriodLabel));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('a future week still opens the picker', (tester) async {
    await pump(tester, period: TrendsPeriod.week(DateTime(2026, 10, 28)));

    await tester.tap(find.text(l10nEn.trendsCustomPeriodLabel));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });
}
