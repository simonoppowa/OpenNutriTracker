import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_weight_note.dart';
import 'package:opennutritracker/generated/l10n.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double rawWeightG,
  required double cookedWeightG,
  required bool overridden,
  VoidCallback? onReset,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SizedBox(
          width: 320,
          child: RecipeWeightNote(
            rawWeightG: rawWeightG,
            cookedWeightG: cookedWeightG,
            overridden: overridden,
            onReset: onReset ?? () {},
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a cooked weight shows next to the raw one', (tester) async {
    var resets = 0;
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 800,
      overridden: true,
      onReset: () => resets++,
    );

    expect(find.text('Raw: 1000 g · cooked: 800 g'), findsOneWidget);
    await tester.tap(find.text('Use the ingredients\' sum'));
    expect(resets, 1);
  });

  testWidgets('without a cooked weight it names the raw sum', (tester) async {
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 1000,
      overridden: false,
    );

    expect(find.text('Ingredients raw: 1000 g'), findsOneWidget);
    expect(find.text('Use the ingredients\' sum'), findsNothing);
  });

  testWidgets('a cooked weight equal to the raw sum can still be reset', (
    tester,
  ) async {
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 1000,
      overridden: true,
    );

    expect(find.text('Raw: 1000 g · cooked: 1000 g'), findsOneWidget);
    expect(find.text('Use the ingredients\' sum'), findsOneWidget);
  });

  testWidgets('a small difference stays visible', (tester) async {
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 999.6,
      overridden: true,
    );

    expect(find.text('Raw: 1000 g · cooked: 999.6 g'), findsOneWidget);
  });

  testWidgets('large text wraps instead of overflowing', (tester) async {
    await _pump(
      tester,
      rawWeightG: 1000,
      cookedWeightG: 800,
      overridden: true,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Use the ingredients\' sum'), findsOneWidget);
  });
}
