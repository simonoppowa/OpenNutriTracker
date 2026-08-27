import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/policy_change_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

/// This dialog informs; it must never collect. #874 established that the
/// onboarding tick is an acknowledgement with no legal basis resting on it, and
/// a notice that grew a checkbox would rebuild the consent-shaped gate that
/// finding removed — while looking like a privacy improvement.
///
/// That is the kind of regression a reviewer waves through, so it is asserted
/// here rather than left to the widget's doc comment.
void main() {
  Future<void> showNotice(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const PolicyChangeDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers no way to consent to anything', (tester) async {
    await showNotice(tester);

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Radio<Object?>), findsNothing);
  });

  testWidgets('can always be dismissed, and dismissing costs nothing', (
    tester,
  ) async {
    await showNotice(tester);

    await tester.tap(find.text(l10nEn.policyChangeNoticeDismissAction));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('says what changed, rather than only linking to it', (
    tester,
  ) async {
    // A user should not have to leave the app to learn whether something
    // started happening to them. The answer is no, and it is in the body.
    await showNotice(tester);

    expect(find.text(l10nEn.policyChangeNoticeTitle), findsOneWidget);
    expect(find.text(l10nEn.policyChangeNoticeBody), findsOneWidget);
  });

  testWidgets('offers the policy itself as well', (tester) async {
    await showNotice(tester);

    expect(find.text(l10nEn.policyChangeNoticeReadAction), findsOneWidget);
  });

  testWidgets('a long body scrolls rather than overflowing a small screen', (
    tester,
  ) async {
    // The body is several sentences in nine languages, and German runs
    // longest. On a 320 dp-tall viewport an unscrollable dialog throws.
    tester.view.physicalSize = const Size(360, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await showNotice(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
