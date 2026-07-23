import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets(
    'MacroNutrientsView lays out under the bounded width from the crash report',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('de'),
          // Declaring the supported locales is what lets the `de` locale
          // actually resolve — without it the test silently falls back to
          // English and never exercises the German-width layout crash.
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 337.4,
                child: MacroNutrientsView(
                  totalCarbsIntake: 56,
                  totalFatsIntake: 30,
                  totalProteinsIntake: 40,
                  totalCarbsGoal: 398,
                  totalFatsGoal: 80,
                  totalProteinsGoal: 120,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );
}
