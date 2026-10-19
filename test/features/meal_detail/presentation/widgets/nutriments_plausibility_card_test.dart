import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/nutriments_plausibility_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

const _hirtenkaese = MealNutrimentsEntity(
  energyKcal100: 102,
  carbohydrates100: 0.6,
  fat100: 19.8,
  proteins100: 17.2,
  sugars100: 0.6,
  saturatedFat100: 12.6,
  fiber100: null,
);

const _skyr = MealNutrimentsEntity(
  energyKcal100: 62.4,
  carbohydrates100: 4,
  fat100: 0.2,
  proteins100: 11,
  sugars100: 4,
  saturatedFat100: 0.1,
  fiber100: 0,
);

void main() {
  var corrections = 0;

  Future<void> pumpCard(WidgetTester tester, MealNutrimentsEntity values) {
    corrections = 0;
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: NutrimentsPlausibilityCard(
            nutriments: values,
            onCorrect: () => corrections++,
          ),
        ),
      ),
    );
  }

  Finder card() => find.bySemanticsIdentifier('meal-detail-plausibility');

  testWidgets('names the stated and the expected energy', (tester) async {
    await pumpCard(tester, _hirtenkaese);

    expect(card(), findsOneWidget);
    expect(find.textContaining('102 kcal are stated'), findsOneWidget);
    expect(find.textContaining('about 249 kcal'), findsOneWidget);
  });

  testWidgets('stays away for plausible values', (tester) async {
    await pumpCard(tester, _skyr);

    expect(card(), findsNothing);
  });

  testWidgets('correcting opens the editor', (tester) async {
    await pumpCard(tester, _hirtenkaese);

    await tester.tap(find.text('Correct values'));

    expect(corrections, 1);
  });

  testWidgets('using the values anyway hides the hint', (tester) async {
    await pumpCard(tester, _hirtenkaese);

    await tester.tap(find.text('Use anyway'));
    await tester.pump();

    expect(card(), findsNothing);
  });
}
