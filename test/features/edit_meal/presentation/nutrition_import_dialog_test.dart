import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/presentation/nutrition_import_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

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
    await tester.tap(find.text('serving').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      protein,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextField>(protein).controller!.text, '3.0');
  });
}
