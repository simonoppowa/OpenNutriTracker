import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  localizationsDelegates: const [S.delegate],
  supportedLocales: S.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('the plus at the foot of a list says where it adds', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        PlaceholderCard(
          day: DateTime(2026, 10, 30),
          onTap: () {},
          firstListElement: true,
          semanticIdentifier: 'add-meal-placeholder',
          label: 'Add to Breakfast',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Add to Breakfast'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the search bar\'s icon buttons say what they do', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MealSearchBar(
          searchStringListener: ValueNotifier(''),
          onSearchSubmit: (_) {},
          onBarcodePressed: () {},
        ),
      ),
    );
    expect(find.byTooltip('Scan Product'), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
  });

  testWidgets('at twice the font size the macro rings stack, uncut', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const MacroNutrientsView(
          totalCarbsIntake: 56,
          totalFatsIntake: 30,
          totalProteinsIntake: 40,
          totalCarbsGoal: 398,
          totalFatsGoal: 80,
          totalProteinsGoal: 120,
        ),
        textScale: 2,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    final carbs = tester.getTopLeft(find.text('carbs'));
    final protein = tester.getTopLeft(find.text('protein'));
    expect(protein.dy, greaterThan(carbs.dy));
  });
}
