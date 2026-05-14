import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_second_page_body.dart';

void main() {
  testWidgets('Case 1: Value is null', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    state.validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongHeightLabel), findsOneWidget);
  });

  testWidgets('Case 2: Value is empty string with imperial units', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final imperialButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: imperialButton,
      matching: find.text(S.current.ftLabel),
    ));
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

  testWidgets('Case 3: Value is different than real numbers with imperial units', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final imperialButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: imperialButton,
      matching: find.text(S.current.ftLabel),
    ));
    await tester.pump();

    final heightField = find.byType(TextFormField).first;
    await tester.enterText(heightField, '-9@');
    await tester.pump();

    final form = find.byType(Form).first;
    final state = tester.state<FormState>(form);
    state.validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongHeightLabel), findsOneWidget);
  });

  testWidgets('Case 5: Value is empty string with decimal units', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: metricButton,
      matching: find.text(S.current.cmLabel),
    ));
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

  testWidgets('Case 6: Value is below minimum height with decimal units', (WidgetTester tester) async {
    // Note: the cm field's input formatter is digitsOnly, so a literal "9.6"
    // is stripped to "96" — a valid cm height. To exercise the validator we
    // use a value that survives the formatter but fails the range check.
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: metricButton,
      matching: find.text(S.current.cmLabel),
    ));
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

  testWidgets('Case 4: Imperial selected and value is 6.7 (should be valid)', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final imperialButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: imperialButton,
      matching: find.text(S.current.ftLabel),
    ));
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

  testWidgets('Case 7: Metric selected and value is 6.7 (should be valid)', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
      ],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final metricButton = find.byType(ToggleButtons).first;
    await tester.tap(find.descendant(
      of: metricButton,
      matching: find.text(S.current.cmLabel),
    ));
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
  testWidgets('Weight field: metric accepts decimal input with dot (65.5 kg)',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

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

  testWidgets('Weight field: metric accepts decimal input with comma (65,5 kg)',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '65,5');
    await tester.pump();

    final weightForm = find.byType(Form).at(1);
    final isValid = tester.state<FormState>(weightForm).validate();
    await tester.pump();

    expect(find.text('65,5'), findsOneWidget);
    expect(isValid, isTrue);
    expect(find.text(S.current.onboardingWrongWeightLabel), findsNothing);
  });

  testWidgets('Weight field: zero is rejected (below minWeight=2)',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: OnboardingSecondPageBody(
          setButtonContent: (_, _, _, _, _) {},
        ),
      ),
    ));

    final weightField = find.byType(TextFormField).at(1);
    await tester.enterText(weightField, '0');
    await tester.pump();

    final weightForm = find.byType(Form).at(1);
    tester.state<FormState>(weightForm).validate();
    await tester.pump();

    expect(find.text(S.current.onboardingWrongWeightLabel), findsOneWidget);
  });
}
