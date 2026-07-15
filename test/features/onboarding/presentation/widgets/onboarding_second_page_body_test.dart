import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_second_page_body.dart';

void main() {
  testWidgets('Case 1: Value is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    state.validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongHeightLabel), findsOneWidget);
  });

  testWidgets(
    'Case 2: imperial height shows feet and inches fields, empty is not ready',
    (WidgetTester tester) async {
      bool? lastActive;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          home: Scaffold(
            body: OnboardingSecondPageBody(
              setButtonContent: (active, _, _, _, _, _, _) =>
                  lastActive = active,
            ),
          ),
        ),
      );

      final imperialButton = find.byType(ToggleButtons).first;
      await tester.tap(
        find.descendant(
          of: imperialButton,
          matching: find.text(S.current.ftLabel),
        ),
      );
      await tester.pump();

      // Two coupled fields appear: feet (also matched by the toggle) and inches.
      expect(find.text(S.current.ftLabel), findsWidgets);
      expect(find.text(S.current.inLabel), findsOneWidget);
      // Nothing entered yet, so the page is not ready to proceed.
      expect(lastActive ?? false, isFalse);
    },
  );

  testWidgets('Case 3: imperial feet field strips non-digits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ToggleButtons).first,
        matching: find.text(S.current.ftLabel),
      ),
    );
    await tester.pump();

    // The feet field is the first raw TextField (the inches field is second).
    final feetField = find.byType(TextField).at(0);
    await tester.enterText(feetField, '5a-9@');
    await tester.pump();

    // digitsOnly leaves just the digits.
    expect(find.text('59'), findsOneWidget);
  });

  testWidgets('Case 5: Value is empty string with decimal units', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(
      find.descendant(of: metricButton, matching: find.text(S.current.cmLabel)),
    );
    await tester.pump();

    final heightField = find.byType(TextFormField).first;
    await tester.enterText(heightField, '');
    await tester.pump();

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    state.validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongHeightLabel), findsOneWidget);
  });

  testWidgets('Case 6: Value is below minimum height with decimal units', (
    WidgetTester tester,
  ) async {
    // Note: the cm field's input formatter is digitsOnly, so a literal "9.6"
    // is stripped to "96" — a valid cm height. To exercise the validator we
    // use a value that survives the formatter but fails the range check.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(
      find.descendant(of: metricButton, matching: find.text(S.current.cmLabel)),
    );
    await tester.pump();

    final heightField = find.byType(TextFormField).first;
    await tester.enterText(heightField, '9');
    await tester.pump();

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    state.validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongHeightLabel), findsOneWidget);
  });

  testWidgets('Case 4: imperial feet + inches with a weight is accepted', (
    WidgetTester tester,
  ) async {
    bool? lastActive;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (active, _, _, _, _, _, _) => lastActive = active,
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ToggleButtons).first,
        matching: find.text(S.current.ftLabel),
      ),
    );
    await tester.pump();

    // Feet and inches are the first two raw TextFields; weight stays a kg
    // TextFormField.
    await tester.enterText(find.byType(TextField).at(0), '5'); // feet
    await tester.enterText(find.byType(TextField).at(1), '9'); // inches
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), '70'); // weight kg
    await tester.pump();

    expect(lastActive, isTrue);
  });

  testWidgets('Case 7: Metric selected and value is 6.7 (should be valid)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(
      find.descendant(of: metricButton, matching: find.text(S.current.cmLabel)),
    );
    await tester.pump();

    final heightField = find.byType(TextFormField).first;
    await tester.enterText(heightField, '6.7');
    await tester.pump();

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '150');
    await tester.pump();

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    final isValid = state.validate();
    await tester.pump();

    expect(isValid, isTrue);
    expect(find.text(S.current.onboardingWrongHeightLabel), findsNothing);
  });

  // Regression coverage for #244 — the weight field used to be locked to
  // FilteringTextInputFormatter.digitsOnly which silently dropped any '.' or
  // ',' the user typed. Now it accepts a single decimal digit in either
  // separator.
  testWidgets('Weight field: metric accepts decimal input with dot (65.5 kg)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '65.5');
    await tester.pump();

    final weightForm = find.byType(Form).at(1);
    final isValid = tester.state<FormState>(weightForm).validate();
    await tester.pump();

    // The character must survive the input formatter (the previous
    // digitsOnly formatter would have stripped the dot).
    expect(find.text('65.5'), findsOneWidget);
    expect(isValid, isTrue);
    expect(find.text(S.current.onboardingWrongWeightLabel), findsNothing);
  });

  testWidgets(
    'Weight field: metric accepts decimal input with comma (65,5 kg)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          home: Scaffold(
            body: OnboardingSecondPageBody(
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      final weightField = find.byType(TextFormField).at(1);
      await tester.enterText(weightField, '65,5');
      await tester.pump();

      final weightForm = find.byType(Form).at(1);
      final isValid = tester.state<FormState>(weightForm).validate();
      await tester.pump();

      expect(find.text('65,5'), findsOneWidget);
      expect(isValid, isTrue);
      expect(find.text(S.current.onboardingWrongWeightLabel), findsNothing);
    },
  );

  testWidgets('Weight field: zero is rejected (below minWeight=2)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '0');
    await tester.pump();

    final weightForm = find.byType(Form).at(1);
    tester.state<FormState>(weightForm).validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongWeightLabel), findsOneWidget);
  });

  // Regression coverage: switching the body-weight unit used to leave the
  // shared kg/lb text field showing the stale, unconverted number under its
  // new unit label instead of recomputing it — see the "onboarding weight
  // unit toggle" fix.
  testWidgets('Weight field: switching kg -> lb converts the displayed value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Scaffold(
          body: OnboardingSecondPageBody(
            setButtonContent: (_, _, _, _, _, _, _) {},
          ),
        ),
      ),
    );

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '80');
    await tester.pump();

    await tester.tap(find.text(S.current.lbsLabel));
    await tester.pump();

    // 80 kg -> 176.4 lb (UnitCalc.kgToLbs), not a stale "80".
    expect(find.text('176.4'), findsOneWidget);
    expect(find.text('80'), findsNothing);
  });

  testWidgets(
    'Weight field: value survives a round trip through the stones unit',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          home: Scaffold(
            body: OnboardingSecondPageBody(
              setButtonContent: (_, _, _, _, _, _, _) {},
            ),
          ),
        ),
      );

      final weightField = find.byType(TextFormField).at(1);
      await tester.enterText(weightField, '80');
      await tester.pump();

      await tester.tap(find.text(S.current.stLabel));
      await tester.pump();

      // 80 kg -> 12 st 8.4 lb; the stones/pounds fields must show the just
      // -typed value, not be blank (which the initialWeightKg-only seed bug
      // used to produce).
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8.4'), findsOneWidget);

      await tester.tap(find.text(S.current.kgLabel));
      await tester.pump();

      // Back to kg: the shared field must show the original 80, not be blank
      // or stuck showing a stones-unit value.
      expect(find.text('80'), findsOneWidget);
    },
  );
}
