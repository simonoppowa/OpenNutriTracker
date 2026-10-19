import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/missing_nutriments_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('explains the gap and starts the table scan', (tester) async {
    var scans = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: MissingNutrimentsCard(onScan: () => scans++)),
      ),
    );

    expect(
      find.bySemanticsIdentifier('meal-detail-missing-nutrients'),
      findsOneWidget,
    );
    expect(find.text(l10nEn.labelScanMissingTitle), findsOneWidget);
    expect(find.text(l10nEn.labelScanMissingBody), findsOneWidget);

    await tester.tap(find.text(l10nEn.labelScanAction));

    expect(scans, 1);
  });
}
