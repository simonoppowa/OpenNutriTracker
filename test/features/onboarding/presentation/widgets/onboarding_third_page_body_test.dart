import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_third_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

/// The activity page used to be four chips with the explanation hidden
/// behind a '?' dialog beside each one, a tap away from the choice it
/// informs. It is now four cards that carry their description.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    void Function(bool, UserActivitySelectionEntity?)? onSelected,
    UserActivitySelectionEntity? initial,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: OnboardingThirdPageBody(
            setButtonContent: (active, activity) =>
                onSelected?.call(active, activity),
            initialActivity: initial,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every level shows its description without a tap', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text(l10nEn.palSedentaryDescriptionLabel), findsOneWidget);
    expect(find.text(l10nEn.palLowActiveDescriptionLabel), findsOneWidget);
    expect(find.text(l10nEn.palActiveDescriptionLabel), findsOneWidget);
    expect(find.text(l10nEn.palVeryActiveDescriptionLabel), findsOneWidget);
  });

  testWidgets('nothing is selected until the user picks', (tester) async {
    bool? lastActive;
    await pumpPage(tester, onSelected: (active, _) => lastActive = active);

    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(lastActive, isNull, reason: 'no selection has been reported yet');
  });

  testWidgets('tapping a card selects it and reports the level', (
    tester,
  ) async {
    UserActivitySelectionEntity? reported;
    bool? lastActive;
    await pumpPage(
      tester,
      onSelected: (active, activity) {
        lastActive = active;
        reported = activity;
      },
    );

    await tester.tap(find.text(l10nEn.palVeryActiveLabel));
    await tester.pump();

    expect(reported, UserActivitySelectionEntity.veryActive);
    expect(lastActive, isTrue);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('selecting another level replaces the first', (tester) async {
    UserActivitySelectionEntity? reported;
    await pumpPage(tester, onSelected: (_, activity) => reported = activity);

    await tester.tap(find.text(l10nEn.palSedentaryLabel));
    await tester.pump();
    await tester.tap(find.text(l10nEn.palActiveLabel));
    await tester.pump();

    expect(reported, UserActivitySelectionEntity.active);
    expect(
      find.byIcon(Icons.radio_button_checked),
      findsOneWidget,
      reason: 'the levels are mutually exclusive',
    );
  });

  testWidgets('identifiers the ADB walker relies on are preserved', (
    tester,
  ) async {
    await pumpPage(tester);

    for (final id in [
      'onboarding-activity-sedentary',
      'onboarding-activity-low',
      'onboarding-activity-active',
      'onboarding-activity-very',
    ]) {
      expect(
        find.bySemanticsIdentifier(id),
        findsOneWidget,
        reason: '$id is used by tools/adb/walk-onboarding.sh',
      );
    }
  });
}
