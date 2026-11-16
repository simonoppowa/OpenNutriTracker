import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/home/domain/entity/nutrient_contribution_entity.dart';
import 'package:opennutritracker/features/home/presentation/screens/nutrient_contributions_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/intake_entity_fixtures.dart';

void main() {
  testWidgets('tapping a food opens its details (#1266)', (tester) async {
    MealDetailScreenArguments? opened;
    final chicken = intakeOf(
      'Chicken breast',
      150,
      protein100: 23,
      type: IntakeTypeEntity.dinner,
    );
    final day = DateTime(2026, 10, 23);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: NutrientContributionsScreen(
          nutrient: MacroNutrient.protein,
          intakes: [intakeOf('Oats', 80, protein100: 13), chicken],
          total: 45,
          goal: 93,
          day: day,
          usesImperialUnits: true,
        ),
        onGenerateRoute: (settings) {
          if (settings.name == NavigationOptions.mealDetailRoute) {
            opened = settings.arguments as MealDetailScreenArguments;
          }
          return MaterialPageRoute<void>(builder: (_) => const SizedBox());
        },
      ),
    );

    await tester.tap(find.text('Chicken breast'));
    await tester.pumpAndSettle();

    expect(opened?.mealEntity, same(chicken.meal));
    expect(opened?.intakeTypeEntity, IntakeTypeEntity.dinner);
    expect(opened?.day, day);
    expect(opened?.usesImperialUnits, isTrue);
  });
}
