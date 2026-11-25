import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/quick_add_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('pasted nutrition populates the quick add fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: QuickAddBottomSheet(
              intakeType: IntakeTypeEntity.breakfast,
              day: DateTime(2026, 10, 27),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('quick-add-paste-nutrition'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Oat Milk\nPer serving 50 g\nEnergy 60 kcal\nCarbs 6.6 g\nFat 3 g\nProtein 1 g',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('nutrition-apply-form'));
    await tester.pumpAndSettle();

    String value(String id) => tester
        .widget<TextField>(
          find.descendant(
            of: find.bySemanticsIdentifier(id),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;

    expect(value('quick-add-title'), 'Oat Milk');
    expect(value('quick-add-energy'), '60.0');
    expect(value('quick-add-carbs'), '6.6');
    expect(value('quick-add-fat'), '3.0');
    expect(value('quick-add-protein'), '1.0');
  });
}
