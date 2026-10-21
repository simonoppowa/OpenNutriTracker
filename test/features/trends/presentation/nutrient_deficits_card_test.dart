import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/trends/domain/nutrient_deficits.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/nutrient_deficits_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

Future<List<int>> _pump(
  WidgetTester tester, {
  required List<NutrientDeficit> deficits,
}) async {
  final changes = <int>[];
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
        body: NutrientDeficitsCard(
          deficits: deficits,
          thresholdPercent: 70,
          onThresholdChanged: changes.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changes;
}

void main() {
  testWidgets('lists the deficits with their share of days', (tester) async {
    await _pump(
      tester,
      deficits: const [
        NutrientDeficit(
          key: NutrientPanelKeys.iron,
          deficitDays: 4,
          evaluatedDays: 5,
        ),
        NutrientDeficit(
          key: NutrientPanelKeys.vitaminD,
          deficitDays: 2,
          evaluatedDays: 6,
        ),
      ],
    );

    expect(find.text(l10nEn.ironLabel), findsOneWidget);
    expect(find.text(l10nEn.trendsDaysOfLabel(4, 5)), findsOneWidget);
    expect(find.text(l10nEn.trendsDaysOfLabel(2, 6)), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text(l10nEn.trendsDeficitThresholdLabel(70)), findsOneWidget);
  });

  testWidgets('without deficits it says so', (tester) async {
    await _pump(tester, deficits: const []);

    expect(find.text(l10nEn.trendsNoDeficitsLabel), findsOneWidget);
  });

  testWidgets('the threshold can be changed', (tester) async {
    final changes = await _pump(tester, deficits: const []);

    await tester.tap(find.text(l10nEn.trendsDeficitThresholdLabel(70)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.trendsDeficitThresholdLabel(50)).last);
    await tester.pumpAndSettle();

    expect(changes, [50]);
  });
}
