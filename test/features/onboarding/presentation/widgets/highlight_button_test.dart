import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/highlight_button.dart';

/// A blocked onboarding step used to swallow the tap. The footer button was
/// built with `onPressed: null`, so a user with an incomplete page got no
/// feedback at all. These cover the replacement: visually disabled, still
/// tappable, and it says what is missing.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool active,
    String? inactiveMessage,
    required VoidCallback onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HighlightButton(
            buttonLabel: 'Next',
            onButtonPressed: onPressed,
            buttonActive: active,
            inactiveMessage: inactiveMessage,
          ),
        ),
      ),
    );
  }

  testWidgets('inactive with a message shows it and does not advance', (
    tester,
  ) async {
    var pressed = 0;
    await pumpButton(
      tester,
      active: false,
      inactiveMessage: 'Select your goal to continue',
      onPressed: () => pressed++,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Select your goal to continue'), findsOneWidget);
    expect(pressed, 0, reason: 'a blocked page must not advance');
  });

  testWidgets('active taps advance and show no snackbar', (tester) async {
    var pressed = 0;
    await pumpButton(
      tester,
      active: true,
      inactiveMessage: 'Select your goal to continue',
      onPressed: () => pressed++,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(pressed, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('inactive without a message stays genuinely disabled', (
    tester,
  ) async {
    var pressed = 0;
    await pumpButton(tester, active: false, onPressed: () => pressed++);

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(pressed, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('repeated blocked taps replace the snackbar rather than queue', (
    tester,
  ) async {
    await pumpButton(
      tester,
      active: false,
      inactiveMessage: 'Select your goal to continue',
      onPressed: () {},
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  group('accessibility', () {
    testWidgets('a blocked button announces why it is blocked', (tester) async {
      // The grey is the only cue that the step is incomplete, and it is a
      // visual one. Without the hint a screen reader announces an ordinary
      // "Next, button" and the user is left guessing.
      await pumpButton(
        tester,
        active: false,
        inactiveMessage: 'Select your goal to continue',
        onPressed: () {},
      );

      final data = tester
          .getSemantics(find.bySemanticsIdentifier('onboarding-button'))
          .getSemanticsData();

      expect(data.label, 'Next');
      expect(data.hint, 'Select your goal to continue');
      expect(data.flagsCollection.isButton, isTrue);
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the explanation must stay reachable by double tap',
      );
    });

    testWidgets('an active button is left as the plain Material one', (
      tester,
    ) async {
      await pumpButton(
        tester,
        active: true,
        inactiveMessage: 'Select your goal to continue',
        onPressed: () {},
      );

      final data = tester
          .getSemantics(find.bySemanticsIdentifier('onboarding-button'))
          .getSemanticsData();

      expect(
        data.hint,
        isEmpty,
        reason: 'nothing is blocking it, so there is nothing to explain',
      );
    });
  });
}
