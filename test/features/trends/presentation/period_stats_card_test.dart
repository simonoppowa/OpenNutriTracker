import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/period_stats_card.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

TrackedDayEntity _day(int day, double kcal) => TrackedDayEntity(
  day: DateTime(2026, 10, day),
  calorieGoal: 2000,
  caloriesTracked: kcal,
  carbsGoal: 250,
  carbsTracked: 250,
  fatGoal: 70,
  fatTracked: 70,
  proteinGoal: 100,
  proteinTracked: 100,
);

void main() {
  Future<List<int>> pump(
    WidgetTester tester, {
    required List<TrackedDayEntity> days,
    Map<DateTime, int>? water,
    int tolerance = 10,
  }) async {
    final changes = <int>[];
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: SingleChildScrollView(
              child: PeriodStatsCard(
                start: DateTime(2026, 10, 19),
                end: DateTime(2026, 10, 25),
                days: days,
                waterByDay: water ?? {DateTime(2026, 10, 19): 1500},
                tolerancePercent: tolerance,
                onToleranceChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  testWidgets('shows averages over the days with entries and goals met', (
    tester,
  ) async {
    await pump(tester, days: [_day(19, 1800), _day(20, 2400)]);

    expect(find.text(l10nEn.trendsDaysOfLabel(2, 7)), findsOneWidget);
    expect(find.text('2100 kcal'), findsOneWidget);
    expect(find.text('1500 ml'), findsOneWidget);
    expect(find.text(l10nEn.trendsDaysOfLabel(1, 2)), findsWidgets);
  });

  testWidgets('without entries it says so', (tester) async {
    await pump(tester, days: const [], water: const {});

    expect(find.text(l10nEn.trendsNoEntriesLabel), findsOneWidget);
  });

  testWidgets('the tolerance can be changed', (tester) async {
    final changes = await pump(tester, days: [_day(19, 2150)]);

    await tester.tap(find.text(l10nEn.trendsToleranceLabel(10)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.trendsToleranceLabel(5)).last);
    await tester.pumpAndSettle();

    expect(changes, [5]);
  });

  testWidgets('a smaller tolerance counts fewer days as met', (tester) async {
    await pump(tester, days: [_day(19, 2150)], tolerance: 5);

    expect(find.text(l10nEn.trendsDaysOfLabel(0, 1)), findsWidgets);
  });
}
