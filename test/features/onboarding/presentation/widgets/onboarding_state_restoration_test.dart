// Regression coverage for issue #202 — when the user enters values on an
// onboarding page and navigates back then forward, the page used to rebuild
// from scratch and lose all entered values, even though the parent screen
// kept the "button active" flag set. The page bodies now accept initial*
// constructor params so the parent can restore previously-entered values.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_about_you_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_goal_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_body_measurements_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_activity_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../helpers/test_l10n.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'OpenNutriTracker',
      packageName: 'com.example.opennutritracker',
      version: '1.2.0',
      buildNumber: '46',
      buildSignature: '',
    );
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      );

  group('OnboardingIntroPageBody restoration', () {
    testWidgets('reflects initialAcceptedPolicy/DataCollection in checkboxes',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingIntroPageBody(
        setPageContent: (_, _) {},
        initialAcceptedPolicy: true,
        initialAcceptedDataCollection: true,
      )));
      await tester.pumpAndSettle();

      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes[0].value, isTrue);
      expect(boxes[1].value, isTrue);
    });
  });

  group('OnboardingAboutYouPageBody restoration', () {
    testWidgets('reflects initialGender on the correct ChoiceChip',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingAboutYouPageBody(
        setPageContent: (_, _, _, _) {},
        initialGender: UserGenderSelectionEntity.genderFemale,
      )));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips[0].selected, isFalse, reason: 'male should be unselected');
      expect(chips[1].selected, isTrue, reason: 'female should be selected');
    });

    testWidgets('reflects initialBirthday in the date input field',
        (tester) async {
      final birthday = DateTime(1990, 6, 15);
      await tester.pumpWidget(wrap(OnboardingAboutYouPageBody(
        setPageContent: (_, _, _, _) {},
        initialBirthday: birthday,
      )));
      await tester.pumpAndSettle();

      // The displayed text is locale-formatted; just confirm the field is non-empty.
      final dateField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(dateField.controller?.text, isNotEmpty);
    });
  });

  group('OnboardingBodyMeasurementsPageBody restoration', () {
    testWidgets('metric: shows the stored cm/kg values in the text fields',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingBodyMeasurementsPageBody(
        setButtonContent: (_, _, _, _, _, _, _) {},
        initialHeightCm: 178,
        initialWeightKg: 72.5,
      )));
      await tester.pumpAndSettle();

      expect(find.text('178'), findsOneWidget);
      expect(find.text('72.5'), findsOneWidget);
    });

    testWidgets('imperial: stored cm restores to feet+inches, kg to lbs',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingBodyMeasurementsPageBody(
        setButtonContent: (_, _, _, _, _, _, _) {},
        initialHeightCm: 180,
        initialWeightKg: 80,
        initialHeightImperial: true,
        initialBodyWeightUnit: BodyWeightUnit.lb,
      )));
      await tester.pumpAndSettle();

      // 180 cm restores into the feet + inches fields (5 ft 11 in). These are
      // raw TextFields; the first two in the tree are feet then inches.
      final raw =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(raw[0].controller?.text, '5');
      expect(raw[1].controller?.text, isNotEmpty);

      // 80 kg ≈ 176.4 lbs in the first weight TextFormField.
      final weightField =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(weightField.controller?.text, startsWith('17'));
    });
  });

  group('OnboardingActivityPageBody restoration', () {
    testWidgets('reflects initialActivity on the correct activity card',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingActivityPageBody(
        setButtonContent: (_, _) {},
        initialActivity: UserActivitySelectionEntity.active,
      )));
      await tester.pumpAndSettle();

      // The four levels each render a card carrying a radio indicator;
      // exactly the restored one is filled in. Order is sedentary,
      // lowActive, active, veryActive.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(l10nEn.palActiveLabel),
            matching: find.byType(Row),
          ),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
        reason: 'the filled indicator belongs to the restored level',
      );
    });
  });

  group('OnboardingGoalPageBody restoration', () {
    testWidgets('reflects initialGoal on the correct ChoiceChip',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingGoalPageBody(
        setButtonContent: (_, _) {},
        initialGoal: UserGoalSelectionEntity.gainWeigh,
      )));
      await tester.pumpAndSettle();

      final chips =
          tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      // Order is loseWeight, maintainWeight, gainWeight.
      expect(chips[0].selected, isFalse);
      expect(chips[1].selected, isFalse);
      expect(chips[2].selected, isTrue);
    });
  });

  group('Default values (no initial* args)', () {
    testWidgets('intro page: both checkboxes start unchecked', (tester) async {
      await tester.pumpWidget(wrap(OnboardingIntroPageBody(
        setPageContent: (_, _) {},
      )));
      await tester.pumpAndSettle();

      final boxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.every((b) => b.value == false), isTrue);
    });

    testWidgets('about-you page: no chip selected, date field empty',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingAboutYouPageBody(
        setPageContent: (_, _, _, _) {},
      )));
      await tester.pumpAndSettle();

      final chips =
          tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips.every((c) => c.selected == false), isTrue);
      final dateField =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(dateField.controller?.text, isEmpty);
    });

    testWidgets('body-measurements page: fields empty without initial values',
        (tester) async {
      await tester.pumpWidget(wrap(OnboardingBodyMeasurementsPageBody(
        setButtonContent: (_, _, _, _, _, _, _) {},
      )));
      await tester.pumpAndSettle();

      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields[0].controller?.text, isEmpty);
      expect(fields[1].controller?.text, isEmpty);
    });
  });
}
