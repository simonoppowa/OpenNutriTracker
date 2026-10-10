import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

IntakeEntity intake({bool missingMacros = false}) => IntakeEntity(
  id: 'test',
  unit: 'g',
  amount: 150,
  type: IntakeTypeEntity.breakfast,
  dateTime: DateTime(2026, 1, 1),
  meal: MealEntity(
    code: 'meal',
    name: 'A long meal name that should still fit on a narrow screen',
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: '100 g',
    nutriments: MealNutrimentsEntity(
      energyKcal100: 200,
      carbohydrates100: missingMacros ? null : 20,
      fat100: missingMacros ? null : 10,
      proteins100: missingMacros ? null : 5,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceEntity.custom,
  ),
);

Widget wrap(
  DiarySortType? sort, {
  bool kj = false,
  bool missing = false,
  Locale locale = const Locale('en'),
  double scale = 1,
}) => ChangeNotifierProvider<EnergyUnitProvider>(
  create: (_) => EnergyUnitProvider(usesKilojoules: kj),
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: SizedBox(
          width: 320,
          child: IntakeCard(
            key: const ValueKey('card'),
            intake: intake(missingMacros: missing),
            firstListElement: false,
            usesImperialUnits: false,
            sortType: sort,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final (sort, label) in [
    (DiarySortType.protein, '7.5 g protein'),
    (DiarySortType.carbs, '30.0 g carbs'),
    (DiarySortType.fat, '15.0 g fat'),
  ]) {
    testWidgets('shows portion-scaled $sort with secondary energy', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(sort));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
      expect(find.text('300 kcal'), findsOneWidget);
      final primary = tester.widget<Text>(find.text(label));
      final energy = tester.widget<Text>(find.text('300 kcal'));
      expect(primary.style!.fontWeight, FontWeight.w700);
      expect(energy.style!.color, isNot(primary.style!.color));
      expect(tester.takeException(), isNull);
    });
  }
  for (final sort in [null, DiarySortType.timeAdded, DiarySortType.kcal]) {
    testWidgets('keeps energy-only rows for $sort', (tester) async {
      await tester.pumpWidget(wrap(sort));
      await tester.pump();
      expect(find.text('300 kcal'), findsOneWidget);
      expect(find.textContaining('g protein'), findsNothing);
      expect(find.textContaining('g carbs'), findsNothing);
      expect(find.textContaining('g fat'), findsNothing);
    });
  }
  testWidgets('updates macro when sort changes and keeps kJ', (tester) async {
    await tester.pumpWidget(wrap(DiarySortType.protein, kj: true));
    await tester.pump();
    expect(find.text('7.5 g protein'), findsOneWidget);
    expect(find.text('1255 kJ'), findsOneWidget);
    await tester.pumpWidget(wrap(DiarySortType.fat, kj: true));
    await tester.pump();
    expect(find.text('7.5 g protein'), findsNothing);
    expect(find.text('15.0 g fat'), findsOneWidget);
    expect(find.text('1255 kJ'), findsOneWidget);
  });
  testWidgets('missing macros match the zero used for sorting', (tester) async {
    await tester.pumpWidget(wrap(DiarySortType.protein, missing: true));
    await tester.pump();
    expect(find.text('0.0 g protein'), findsOneWidget);
  });
  testWidgets('German labels fit a narrow row at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(DiarySortType.carbs, locale: const Locale('de'), scale: 2),
    );
    await tester.pump();
    final context = tester.element(find.byType(IntakeCard));
    final s = S.of(context);
    expect(find.text('30,0 ${s.gramUnit} ${s.carbsLabel}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
