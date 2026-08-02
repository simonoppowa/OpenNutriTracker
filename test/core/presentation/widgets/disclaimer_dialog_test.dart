import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

/// Dismissing this dialog records an acknowledgement rather than merely
/// closing a message, so its action says so.
void main() {
  Future<bool?> showDisclaimer(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DisclaimerDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('the action reads as an acknowledgement, not a generic OK', (
    tester,
  ) async {
    await showDisclaimer(tester);

    expect(find.text(l10nEn.disclaimerAcknowledgeLabel), findsOneWidget);
    expect(
      find.text(l10nEn.dialogOKLabel),
      findsNothing,
      reason: 'the shared OK label belongs to dialogs that merely close',
    );
  });

  testWidgets('shows the disclaimer text under its title', (tester) async {
    await showDisclaimer(tester);

    expect(find.text(l10nEn.settingsDisclaimerLabel), findsOneWidget);
    expect(find.text(l10nEn.disclaimerText), findsOneWidget);
  });

  testWidgets('acknowledging closes the dialog and reports acceptance', (
    tester,
  ) async {
    await showDisclaimer(tester);

    await tester.tap(find.text(l10nEn.disclaimerAcknowledgeLabel));
    await tester.pumpAndSettle();

    // The callers persist this as ConfigEntity.hasAcceptedDisclaimer.
    expect(find.byType(AlertDialog), findsNothing);
  });
}
