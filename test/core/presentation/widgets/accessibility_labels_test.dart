import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/settings_rows.dart';
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

  testWidgets('an activity list\'s title is a heading and its menu says '
      'whose it is', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        ActivityVerticalList(
          day: DateTime(2026, 10, 30),
          title: 'Activity',
          userActivityList: const [],
          onItemLongPressedCallback: (_, _) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Activity')),
      isSemantics(isHeader: true),
    );
    expect(find.byTooltip('Activity options'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a settings category header is a heading', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(SettingsCategoryHeader(palette: AppPalette.light, label: 'Goals')),
    );
    expect(
      tester.getSemantics(find.text('Goals')),
      isSemantics(isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('at twice the font size the edit dialog scrolls above the '
      'keyboard, uncut', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: EditDialog(
            intakeEntity: IntakeEntity(
              id: 'i',
              unit: 'g',
              amount: 100,
              type: IntakeTypeEntity.breakfast,
              dateTime: DateTime(2026, 10, 30),
              meal: MealEntity(
                code: 'm',
                name: 'Skyr',
                url: null,
                mealQuantity: '100',
                mealUnit: 'g',
                servingQuantity: null,
                servingUnit: null,
                servingSize: null,
                nutriments: MealNutrimentsEntity.empty(),
                source: MealSourceEntity.custom,
              ),
            ),
            usesImperialUnits: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(
        of: find.byType(TextFormField),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });
}
