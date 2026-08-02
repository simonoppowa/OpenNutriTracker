import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_goal_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

/// The goal page marks a suggestion and says where it came from. The choice
/// stays with the user; nothing is preselected.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    void Function(bool, UserGoalSelectionEntity?)? onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: OnboardingGoalPageBody(
            setButtonContent: (active, goal) => onSelected?.call(active, goal),
            heightCm: heightCm,
            weightKg: weightKg,
            targetWeightKg: targetWeightKg,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The badge sits in the same Row as its chip, which is how we tell which
  /// option was marked.
  Finder badgeBesideChip(String chipLabel) => find.descendant(
    of: find.ancestor(of: find.text(chipLabel), matching: find.byType(Row)),
    matching: find.text(l10nEn.onboardingGoalSuggestedBadge),
  );

  testWidgets('nothing is preselected even with a suggestion', (tester) async {
    bool? lastActive;
    await pumpPage(
      tester,
      heightCm: 180,
      weightKg: 95,
      onSelected: (active, _) => lastActive = active,
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.every((chip) => !chip.selected), isTrue);
    expect(lastActive, isNull, reason: 'the page must not report a choice');
  });

  testWidgets('a high BMI marks lose and quotes the number and band', (
    tester,
  ) async {
    await pumpPage(tester, heightCm: 180, weightKg: 95);

    expect(badgeBesideChip(l10nEn.goalLoseWeight), findsOneWidget);
    // BMI 29.3, which WHO calls pre-obesity.
    expect(find.textContaining('29.3'), findsOneWidget);
    expect(
      find.textContaining(l10nEn.nutritionalStatusPreObesity),
      findsOneWidget,
    );
  });

  testWidgets('a normal BMI marks maintain', (tester) async {
    await pumpPage(tester, heightCm: 180, weightKg: 70);

    expect(badgeBesideChip(l10nEn.goalMaintainWeight), findsOneWidget);
  });

  testWidgets('a target weight overrides the BMI band and says so', (
    tester,
  ) async {
    // BMI 24.7 is normal, so BMI alone would say maintain.
    await pumpPage(tester, heightCm: 180, weightKg: 80, targetWeightKg: 72);

    expect(badgeBesideChip(l10nEn.goalLoseWeight), findsOneWidget);
    expect(
      find.text(l10nEn.onboardingGoalSuggestionTarget),
      findsOneWidget,
      reason: 'the card should name the target as its basis',
    );
  });

  testWidgets('no suggestion at all when height and weight are unknown', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text(l10nEn.onboardingGoalSuggestedBadge), findsNothing);
    expect(find.text(l10nEn.onboardingGoalSuggestionTarget), findsNothing);
  });

  testWidgets('changing the weight behind the page moves the suggestion', (
    tester,
  ) async {
    // Going back to the height/weight page and correcting a value rebuilds
    // this page in place. The suggestion has to follow the new numbers
    // rather than keep marking what the old ones pointed at.
    await pumpPage(tester, heightCm: 180, weightKg: 95); // BMI 29.3
    expect(badgeBesideChip(l10nEn.goalLoseWeight), findsOneWidget);

    await pumpPage(tester, heightCm: 180, weightKg: 55); // BMI 17.0

    expect(badgeBesideChip(l10nEn.goalGainWeight), findsOneWidget);
    expect(badgeBesideChip(l10nEn.goalLoseWeight), findsNothing);
  });

  testWidgets('the user can still pick something other than the suggestion', (
    tester,
  ) async {
    UserGoalSelectionEntity? reported;
    await pumpPage(
      tester,
      heightCm: 180,
      weightKg: 95,
      onSelected: (_, goal) => reported = goal,
    );

    await tester.tap(find.text(l10nEn.goalGainWeight));
    await tester.pump();

    expect(reported, UserGoalSelectionEntity.gainWeigh);
    expect(
      badgeBesideChip(l10nEn.goalLoseWeight),
      findsOneWidget,
      reason: 'the suggestion stays put; it is advice, not a rule',
    );
  });
}
