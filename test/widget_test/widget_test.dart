import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets('DashboardWidget displays correct data',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const DashboardWidget(
        totalKcalSupplied: 1500,
        totalKcalBurned: 500,
        totalKcalDaily: 2000,
        totalKcalLeft: 1000,
        totalCarbsIntake: 200,
        totalFatsIntake: 50,
        totalProteinsIntake: 100,
        totalCarbsGoal: 250,
        totalFatsGoal: 60,
        totalProteinsGoal: 120,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify that the supplied and burned calorie values are displayed.
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);

    // Verify that the kcal left label is displayed as AnimatedFlipCounter
    final kcalLeftFlipCounter = tester
        .firstWidget<AnimatedFlipCounter>(find.byType(AnimatedFlipCounter));
    expect(kcalLeftFlipCounter.value, 1000);
  });
}
