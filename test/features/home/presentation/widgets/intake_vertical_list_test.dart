import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class _FakeMealDetailBloc extends Fake implements MealDetailBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {}

IntakeEntity _buildIntake({
  required double amount,
  required double kcal100,
  required double carbs100,
  required double fat100,
  required double protein100,
}) {
  return IntakeEntity(
    id: 'test-intake',
    unit: 'g',
    amount: amount,
    type: IntakeTypeEntity.breakfast,
    dateTime: DateTime(2026, 1, 1),
    meal: MealEntity(
      code: 'test-meal',
      name: 'Test Meal',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal100,
        carbohydrates100: carbs100,
        fat100: fat100,
        proteins100: protein100,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    ),
  );
}

Widget _wrapWithMaterial(Widget child) {
  return ChangeNotifierProvider<EnergyUnitProvider>(
    create: (_) => EnergyUnitProvider(),
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    final locator = GetIt.instance;
    locator.registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new);
    locator.registerFactory<HomeBloc>(_FakeHomeBloc.new);
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  // 100 g intake of food with 200 kcal/100g, 20 g carbs/100g, 10 g fat/100g, 5 g protein/100g
  // → totals: 200 kcal, 20 g C, 10 g F, 5 g P
  final intakes = [
    _buildIntake(
      amount: 100,
      kcal100: 200,
      carbs100: 20,
      fat100: 10,
      protein100: 5,
    ),
  ];

  String headerWithMacros() =>
      '200 ${S.current.kcalLabel}\n'
      '20 ${S.current.carbsLabelShort}  '
      '10 ${S.current.fatLabelShort}  '
      '5 ${S.current.proteinLabelShort}';

  String headerKcalOnly() => '200 ${S.current.kcalLabel}';

  testWidgets(
    'shows kcal + macro breakdown when showMealMacros is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsOneWidget);
    },
  );

  testWidgets(
    'shows only kcal when showMealMacros is false',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: false,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsNothing);
    },
  );

  testWidgets(
    'defaults to showing macro breakdown when showMealMacros is omitted',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsOneWidget);
    },
  );

  testWidgets(
    'shows no header text when intake list is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: const [],
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      expect(find.text(headerWithMacros()), findsNothing);
      expect(find.text(headerKcalOnly()), findsNothing);
    },
  );

  // Regression: the QR-share/import options were dropped from the popup
  // menu when the macros toggle PR landed on a stale base. Lock in the
  // expected items so it can't happen again silently.
  testWidgets(
    'popup menu shows Copy/Delete/Share/Import for non-empty section',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: intakes,
        usesImperialUnits: false,
        showMealMacros: true,
        onCopyIntakeCallback: (_, _, _) {},
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<VerticalListPopupMenuSelections>));
      await tester.pumpAndSettle();

      expect(find.text(S.current.dialogCopyLabel), findsOneWidget);
      expect(find.text(S.current.deleteAllLabel), findsOneWidget);
      expect(find.text(S.current.shareMealLabel), findsOneWidget);
      expect(find.text(S.current.importMealLabel), findsOneWidget);
    },
  );

  testWidgets(
    'popup menu shows only Import when section is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithMaterial(IntakeVerticalList(
        day: DateTime(2026, 1, 1),
        title: 'Breakfast',
        listIcon: Icons.bakery_dining_outlined,
        addMealType: AddMealType.breakfastType,
        intakeList: const [],
        usesImperialUnits: false,
        showMealMacros: true,
        onDeleteIntakeCallback: (_, _) {},
      )));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<VerticalListPopupMenuSelections>));
      await tester.pumpAndSettle();

      // Empty section: no Copy/Delete/Share — nothing to act on. Import is
      // always available so the user can scan a QR to populate the section.
      expect(find.text(S.current.dialogCopyLabel), findsNothing);
      expect(find.text(S.current.deleteAllLabel), findsNothing);
      expect(find.text(S.current.shareMealLabel), findsNothing);
      expect(find.text(S.current.importMealLabel), findsOneWidget);
    },
  );
}
