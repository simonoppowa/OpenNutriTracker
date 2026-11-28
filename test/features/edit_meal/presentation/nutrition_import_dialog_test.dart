import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/presentation/nutrition_import_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

void main() {
  testWidgets('save feedback stays visible beside the action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NutritionImportDialog(
                  saveAll: (_) async =>
                      '1 saved, 0 duplicates skipped, 0 invalid skipped.',
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Oats\nPer 100 g\nEnergy 100 kcal',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('nutrition-save-all'));
    await tester.pumpAndSettle();
    expect(
      find.text('1 saved, 0 duplicates skipped, 0 invalid skipped.'),
      findsOneWidget,
    );
  });

  testWidgets('food tabs preserve edits and block invalid tab changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NutritionImportDialog(saveAll: (_) async => ''),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Oats\nPer 100 g\nEnergy 100 kcal\n\nBread\nPer 100 g\nEnergy 250 kcal',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    final name = find.bySemanticsIdentifier('nutrition-name');
    await tester.enterText(name, 'Edited Oats');
    await tester.tap(find.bySemanticsIdentifier('nutrition-entry-tab-1'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: name, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      'Bread',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-entry-tab-0'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: name, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      'Edited Oats',
    );
    await tester.enterText(name, '');
    await tester.tap(find.bySemanticsIdentifier('nutrition-entry-tab-1'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: name, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      '',
    );
    expect(find.bySemanticsIdentifier('nutrition-entry-tab-0'), findsOneWidget);
  });

  testWidgets('basis selector reloads the other pasted table column', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NutritionImportDialog(saveAll: (_) async => ''),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Paste nutrition information'),
      'Oats\nNutrient\tPer 100 g\tPer serving\nServing size: 25 g\nProtein\t12g\t3g',
    );
    await tester.tap(find.text('Import and populate fields'));
    await tester.pumpAndSettle();

    final protein = find.descendant(
      of: find.bySemanticsIdentifier('nutrition-protein'),
      matching: find.byType(TextField),
    );
    final basis = find.byKey(const ValueKey('basis-NutritionBasis.per100g'));
    await tester.scrollUntilVisible(
      protein,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextField>(protein).controller!.text, '12.0');
    await tester.scrollUntilVisible(
      basis,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(basis);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.servingLabel).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      protein,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextField>(protein).controller!.text, '3.0');
  });

  // PR #1491 review: acknowledging each food's parser issues was forgotten
  // on switching foods, so a batch with two such foods could never be added.
  group('issue acknowledgement is kept per food', () {
    const twoAmbiguous =
        'Oats\nPer 100 g\nEnergy 100 kcal\nFat 3 g 4 g\n\n'
        'Bread\nPer 100 g\nEnergy 250 kcal\nFat 1 g 2 g';

    Future<void> open(
      WidgetTester tester, {
      Future<String> Function(List<dynamic>)? saveAll,
      Future<void> Function(List<dynamic>)? applyAll,
    }) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => NutritionImportDialog(
                    saveAll: saveAll,
                    applyAll: applyAll,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsIdentifier('nutrition-paste-text'),
        twoAmbiguous,
      );
      await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
      await tester.pumpAndSettle();
    }

    Future<void> acknowledge(WidgetTester tester) async {
      final checkbox = find.descendant(
        of: find.bySemanticsIdentifier('nutrition-acknowledge-issues'),
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }

    Future<void> showFood(WidgetTester tester, int index) async {
      await tester.scrollUntilVisible(
        find.bySemanticsIdentifier('nutrition-entry-tab-$index'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.bySemanticsIdentifier('nutrition-entry-tab-$index'));
      await tester.pumpAndSettle();
    }

    bool acknowledged(WidgetTester tester) => tester
        .widget<Checkbox>(
          find.descendant(
            of: find.bySemanticsIdentifier('nutrition-acknowledge-issues'),
            matching: find.byType(Checkbox),
          ),
        )
        .value!;

    testWidgets('both reviewed foods are added to the meal', (tester) async {
      List<dynamic>? applied;
      await open(tester, applyAll: (entries) async => applied = entries);
      await acknowledge(tester);
      await showFood(tester, 1);
      await acknowledge(tester);
      await showFood(tester, 0);
      expect(acknowledged(tester), isTrue);

      await tester.tap(find.bySemanticsIdentifier('nutrition-add-all-to-meal'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(2));
    });

    testWidgets('saving stops at a food whose issues were not reviewed', (
      tester,
    ) async {
      var saves = 0;
      await open(
        tester,
        saveAll: (_) async {
          saves++;
          return '';
        },
      );
      await acknowledge(tester);
      await tester.tap(find.bySemanticsIdentifier('nutrition-save-all'));
      await tester.pumpAndSettle();

      expect(saves, 0);
      await tester.scrollUntilVisible(
        find.bySemanticsIdentifier('nutrition-entry-tab-1'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.descendant(
                of: find.bySemanticsIdentifier('nutrition-entry-tab-1'),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        isTrue,
      );
      expect(acknowledged(tester), isFalse);
    });
  });

  // Codex review: with a block that holds no food before two labels, a
  // basis change re-read the food before the selected one.
  testWidgets('a basis change re-reads the selected food\'s own label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NutritionImportDialog(saveAll: (_) async => ''),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Shopping list\n\n'
      'Oats\nNutrient\tPer 100 g\tPer serving\nServing size: 25 g\n'
      'Protein\t12g\t3g\n\n'
      'Bread\nNutrient\tPer 100 g\tPer serving\nServing size: 50 g\n'
      'Protein\t8g\t4g',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('nutrition-entry-tab-1'));
    await tester.pumpAndSettle();

    final protein = find.descendant(
      of: find.bySemanticsIdentifier('nutrition-protein'),
      matching: find.byType(TextField),
    );
    final basis = find.byKey(const ValueKey('basis-NutritionBasis.per100g'));
    await tester.scrollUntilVisible(
      basis,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(basis);
    await tester.pumpAndSettle();
    await tester.tap(basis);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.servingLabel).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      protein,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextField>(protein).controller!.text, '4.0');
  });

  // Codex review: the nutrient fields' identifiers took the camel-case
  // field keys (`nutrition-saturatedFat`).
  testWidgets('nutrient fields have kebab-case identifiers', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: const Scaffold(body: NutritionImportDialog()),
      ),
    );
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Oats\nPer 100 g\nEnergy 370 kcal',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    for (final id in ['saturated-fat', 'vitamin-d', 'vitamin-b12']) {
      await tester.scrollUntilVisible(
        find.bySemanticsIdentifier('nutrition-$id'),
        200,
        scrollable: scrollable,
      );
      expect(find.bySemanticsIdentifier('nutrition-$id'), findsOneWidget);
    }
  });
}
