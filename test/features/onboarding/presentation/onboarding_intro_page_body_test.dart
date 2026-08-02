import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/test_l10n.dart';

void main() {
  setUpAll(() {
    // The widget shows AppConst.getVersionNumber() in a FutureBuilder, which
    // calls PackageInfo.fromPlatform(). Mock it so the widget renders in tests.
    PackageInfo.setMockInitialValues(
      appName: 'OpenNutriTracker',
      packageName: 'com.example.opennutritracker',
      version: '1.2.0',
      buildNumber: '46',
      buildSignature: '',
    );
  });

  Future<void> pumpIntroPage(
    WidgetTester tester, {
    required void Function(bool acceptedPolicy, bool acceptedData)
        onSetPageContent,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: OnboardingIntroPageBody(
          setPageContent: onSetPageContent,
        ),
      ),
    ));
    // Let the version-number FutureBuilder resolve before continuing.
    await tester.pumpAndSettle();
  }

  testWidgets('renders both checkboxes unchecked initially', (tester) async {
    await pumpIntroPage(tester, onSetPageContent: (_, _) {});

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxes, hasLength(2));
    expect(checkboxes[0].value, isFalse, reason: 'policy checkbox starts unchecked');
    expect(checkboxes[1].value, isFalse, reason: 'data-collection checkbox starts unchecked');
  });

  testWidgets('tapping the policy checkbox reports (true, false) and checks the box',
      (tester) async {
    bool? lastPolicy;
    bool? lastData;
    await pumpIntroPage(tester, onSetPageContent: (policy, data) {
      lastPolicy = policy;
      lastData = data;
    });

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(lastPolicy, isTrue);
    expect(lastData, isFalse);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).first).value,
      isTrue,
    );
  });

  testWidgets('tapping the data-collection checkbox reports (false, true)',
      (tester) async {
    bool? lastPolicy;
    bool? lastData;
    await pumpIntroPage(tester, onSetPageContent: (policy, data) {
      lastPolicy = policy;
      lastData = data;
    });

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    expect(lastPolicy, isFalse);
    expect(lastData, isTrue);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).last).value,
      isTrue,
    );
  });

  testWidgets('tapping both checkboxes reports (true, true)', (tester) async {
    bool? lastPolicy;
    bool? lastData;
    await pumpIntroPage(tester, onSetPageContent: (policy, data) {
      lastPolicy = policy;
      lastData = data;
    });

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    expect(lastPolicy, isTrue);
    expect(lastData, isTrue);
  });

  testWidgets('tapping the policy checkbox twice toggles it back off',
      (tester) async {
    final reportedStates = <(bool, bool)>[];
    await pumpIntroPage(tester, onSetPageContent: (policy, data) {
      reportedStates.add((policy, data));
    });

    final policyBox = find.byType(Checkbox).first;
    await tester.tap(policyBox);
    await tester.pump();
    await tester.tap(policyBox);
    await tester.pump();

    expect(reportedStates, equals([(true, false), (false, false)]));
    expect(tester.widget<Checkbox>(policyBox).value, isFalse);
  });

  testWidgets('tapping Try Demo without the policy explains why',
      (tester) async {
    await pumpIntroPage(tester, onSetPageContent: (_, _) {});

    // Never reaches seedDemoData (which would need Hive); an unaccepted
    // policy routes the tap to the explanation instead.
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(
      find.text(l10nEn.onboardingBlockedDemoPolicySnack),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'no seeding should have started');
  });

  testWidgets('tapping the policy ListTile (not just the checkbox) also toggles',
      (tester) async {
    bool? lastPolicy;
    await pumpIntroPage(tester, onSetPageContent: (policy, _) {
      lastPolicy = policy;
    });

    // The policy ListTile has onTap wired to _togglePolicy, so tapping the
    // surrounding row (e.g., the policy text) should also flip the checkbox.
    final policyTile = find.ancestor(
      of: find.byType(Checkbox).first,
      matching: find.byType(ListTile),
    );
    await tester.tap(policyTile);
    await tester.pump();

    expect(lastPolicy, isTrue);
  });
}
