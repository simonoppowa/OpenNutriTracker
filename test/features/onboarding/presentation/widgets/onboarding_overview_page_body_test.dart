import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_overview_page_body.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

/// The overview used to present a calorie goal with no indication of where
/// it came from.
void main() {
  UserEntity user({
    UserWeightGoalEntity goal = UserWeightGoalEntity.loseWeight,
  }) => UserEntity(
    birthday: DateTime(1990, 6, 15),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: goal,
    pal: UserPALEntity.lowActive,
  );

  KcalGoalBreakdownEntity breakdownFor(UserEntity entity) =>
      KcalGoalBreakdownEntity.compute(user: entity, totalKcalActivities: 0);

  Future<void> pumpOverview(
    WidgetTester tester, {
    KcalGoalBreakdownEntity? breakdown,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(usesKilojoules: false),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: OnboardingOverviewPageBody(
                setButtonActive: (_) {},
                calorieGoalDayString: '2000',
                carbsGoalString: '300',
                fatGoalString: '55',
                proteinGoalString: '75',
                breakdown: breakdown,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the steps between maintenance energy and the goal', (
    tester,
  ) async {
    final entity = user();
    final breakdown = breakdownFor(entity);
    await pumpOverview(tester, breakdown: breakdown);

    expect(find.text(l10nEn.kcalGoalInfoTdeeResultLabel), findsOneWidget);
    expect(
      find.text(l10nEn.kcalGoalInfoAppliedAdjustmentLabel),
      findsOneWidget,
    );
    expect(find.text(l10nEn.kcalGoalInfoResultSection), findsOneWidget);

    // The deficit is shown with its sign, since its direction is the point.
    expect(
      find.textContaining('-500'),
      findsOneWidget,
      reason: 'losing weight applies a 500 kcal deficit',
    );
  });

  testWidgets('a surplus is shown with an explicit plus', (tester) async {
    final breakdown = breakdownFor(user(goal: UserWeightGoalEntity.gainWeight));
    await pumpOverview(tester, breakdown: breakdown);

    expect(find.textContaining('+500'), findsOneWidget);
  });

  testWidgets('the derivation total matches the production calculation', (
    tester,
  ) async {
    final breakdown = breakdownFor(user());
    await pumpOverview(tester, breakdown: breakdown);

    // Whatever the equations produce, the row must show that number. That is
    // why this reuses KcalGoalBreakdownEntity instead of recomputing.
    expect(
      find.textContaining(breakdown.totalKcalGoal.toInt().toString()),
      findsWidgets,
    );
  });

  testWidgets('opens the full calculation screen without stored data', (
    tester,
  ) async {
    await pumpOverview(tester, breakdown: breakdownFor(user()));

    final link = find.bySemanticsIdentifier('onboarding-overview-calculation');
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    // Reached with a pre-computed breakdown, so it renders without touching
    // the locator-backed usecase that reads Hive.
    expect(find.byType(KcalGoalInfoScreen), findsOneWidget);
    expect(find.text(l10nEn.kcalGoalInfoIntro), findsOneWidget);
  });

  testWidgets('an incomplete selection shows the goal alone', (tester) async {
    await pumpOverview(tester);

    expect(find.text(l10nEn.kcalGoalInfoTdeeResultLabel), findsNothing);
    expect(
      find.bySemanticsIdentifier('onboarding-overview-calculation'),
      findsNothing,
    );
  });

  group('macro targets read as values, not inputs (#1324)', () {
    testWidgets('each macro is one row: its name and its grams', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpOverview(tester);

      for (final (label, grams) in [
        (l10nEn.carbsLabel, '300 g'),
        (l10nEn.fatLabel, '55 g'),
        (l10nEn.proteinLabel, '75 g'),
      ]) {
        expect(find.text(grams), findsOneWidget);
        // Read out together, as one value, rather than as a bare number.
        expect(
          tester.getSemantics(find.text(grams)),
          matchesSemantics(label: '$label\n$grams'),
        );
      }
      semantics.dispose();
    });

    testWidgets('nothing on the macros looks or acts like a field', (
      tester,
    ) async {
      await pumpOverview(tester);

      expect(find.byType(TextField), findsNothing);
      for (final grams in ['300 g', '55 g', '75 g']) {
        expect(
          find.ancestor(
            of: find.text(grams),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is InkWell ||
                  w is GestureDetector ||
                  w is ButtonStyleButton,
            ),
          ),
          findsNothing,
          reason: '$grams must not offer a tap that does nothing',
        );
      }
    });

    testWidgets('says where the macros can be changed', (tester) async {
      await pumpOverview(tester);

      final hint = l10nEn.onboardingMacrosChangeLaterHint(
        l10nEn.settingsCategoryGoals,
        l10nEn.settingsMacroSplitLabel,
      );
      expect(find.text(hint), findsOneWidget);
      // The path is built from the Settings strings themselves, so it
      // follows them if they are renamed or translated.
      expect(hint, contains(l10nEn.settingsCategoryGoals));
      expect(hint, contains(l10nEn.settingsMacroSplitLabel));
    });
  });
}
