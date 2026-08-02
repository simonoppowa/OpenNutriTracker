import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_second_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

/// The WHO healthy-range card and the confirm-this-value dialog, both added
/// so the height/weight page suggests a target with its reasoning attached
/// and questions typos without blocking real outliers.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    void Function(double? target)? onTarget,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, target, _, _, _) =>
                onTarget?.call(target),
          ),
        ),
      ),
    );
  }

  Future<void> enterHeightAndWeight(
    WidgetTester tester, {
    required String height,
    required String weight,
  }) async {
    await tester.enterText(find.byType(TextFormField).first, height);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), weight);
    await tester.pump();
  }

  testWidgets('no card until both height and weight are entered', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(ActionChip), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '180');
    await tester.pump();

    expect(
      find.byType(ActionChip),
      findsNothing,
      reason: 'the suggestion depends on the current weight too',
    );
  });

  testWidgets('shows the range and its source once both are entered', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '95');

    // 180 cm -> BMI 18.5 is 59.9 kg, BMI 24.9 is 80.7 kg.
    expect(find.textContaining('59.9 kg'), findsOneWidget);
    expect(find.textContaining('80.7 kg'), findsOneWidget);
    expect(find.text(l10nEn.onboardingHealthyRangeSource), findsOneWidget);
  });

  testWidgets('chip offers the midpoint when the weight is above the band', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '95');

    // Midpoint for 180 cm is BMI 21.7 -> 70.3 kg.
    expect(
      find.text(l10nEn.onboardingHealthyRangeApply('70.3 kg')),
      findsOneWidget,
    );
  });

  testWidgets('chip offers the current weight when already healthy', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '75');

    expect(
      find.text(l10nEn.onboardingHealthyRangeApply('75 kg')),
      findsOneWidget,
      reason: 'a healthy weight should be offered as maintain, not nudged',
    );
  });

  testWidgets('tapping the chip fills the target field', (tester) async {
    double? reportedTarget;
    await pumpPage(tester, onTarget: (target) => reportedTarget = target);
    await enterHeightAndWeight(tester, height: '180', weight: '95');

    // The card sits below the fold on the 800x600 test surface.
    await tester.ensureVisible(find.byType(ActionChip));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ActionChip));
    await tester.pump();

    expect(reportedTarget, closeTo(70.3, 0.05));
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller?.text,
      '70.3',
    );
  });

  testWidgets('the card links to the sources behind the calculation', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '95');

    final link = find.bySemanticsIdentifier('onboarding-healthy-range-sources');
    expect(link, findsOneWidget);

    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    // The BMI entry names the WHO classification the suggestion rests on.
    expect(find.text(l10nEn.sourcesBmiTitle), findsOneWidget);
  });

  testWidgets('focusing the target field scrolls the suggestion into view', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '95');

    final viewport = tester.getRect(find.byType(Scrollable).first);
    expect(
      tester.getRect(find.byType(ActionChip)).bottom,
      greaterThan(viewport.bottom),
      reason: 'the card starts below the fold',
    );

    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();

    final chip = tester.getRect(find.byType(ActionChip));
    expect(
      chip.bottom,
      lessThanOrEqualTo(viewport.bottom),
      reason: 'the suggestion must be readable while the target is focused',
    );
    expect(chip.top, greaterThanOrEqualTo(viewport.top));
  });

  testWidgets('an implausible weight asks for confirmation on blur', (
    tester,
  ) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '5');

    expect(
      find.text(l10nEn.onboardingImplausibleTitle),
      findsNothing,
      reason: 'not while the field still has focus',
    );

    // Move focus to the target field.
    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.onboardingImplausibleTitle), findsOneWidget);
  });

  testWidgets('keeping an implausible value accepts it and does not re-ask', (
    tester,
  ) async {
    bool? lastActive;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (active, _, _, _, _, _, _) => lastActive = active,
          ),
        ),
      ),
    );
    await enterHeightAndWeight(tester, height: '180', weight: '5');

    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.onboardingImplausibleKeep));
    await tester.pumpAndSettle();

    expect(
      lastActive,
      isTrue,
      reason: '5 kg clears the hard bounds, so the page can still proceed',
    );

    // Leaving the field again must not re-open the dialog for the same value.
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.onboardingImplausibleTitle), findsNothing);
  });

  testWidgets('a plausible weight is never questioned', (tester) async {
    await pumpPage(tester);
    await enterHeightAndWeight(tester, height: '180', weight: '75');

    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.onboardingImplausibleTitle), findsNothing);
  });

  group('imperial units get the same checks as metric', () {
    testWidgets('an incomplete ft/in height reports its error on blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: OnboardingSecondPageBody(
              initialHeightImperial: true,
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      // Feet without inches parses to null, the same way an out-of-range cm
      // value does, but FeetInchesInput has no validator of its own, so the
      // page has to supply the message.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2');
      await tester.pump();
      expect(
        find.text(l10nEn.onboardingWrongHeightLabel),
        findsNothing,
        reason: 'still typing',
      );

      await tester.tap(fields.at(2));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.onboardingWrongHeightLabel), findsOneWidget);
    });

    testWidgets('an incomplete stones weight reports its error on blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: OnboardingSecondPageBody(
              initialBodyWeightUnit: BodyWeightUnit.st,
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '11');
      await tester.pump();
      expect(find.text(l10nEn.onboardingWrongWeightLabel), findsNothing);

      await tester.tap(fields.at(0));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.onboardingWrongWeightLabel), findsOneWidget);
    });

    testWidgets('an implausible ft/in height asks for confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: OnboardingSecondPageBody(
              initialHeightImperial: true,
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      // 2 ft 0 in is 61 cm: inside the hard bounds, outside the plausible band.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '2');
      await tester.pump();
      await tester.enterText(fields.at(1), '0');
      await tester.pump();
      await tester.tap(fields.at(2));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.onboardingImplausibleTitle), findsOneWidget);
    });

    testWidgets('an implausible stones weight asks for confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: OnboardingSecondPageBody(
              initialBodyWeightUnit: BodyWeightUnit.st,
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '180');
      await tester.pump();
      // 1 st 0 lb is 6.35 kg.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '1');
      await tester.pump();
      await tester.enterText(fields.at(2), '0');
      await tester.pump();
      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.onboardingImplausibleTitle), findsOneWidget);
    });
  });
}
