import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: const Scaffold(
        body: ShareQrDialog(
          title: 'Share meal',
          code: 'sample-payload-code',
          fileBaseName: 'sample_qr',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ShareQrDialog', () {
    testWidgets('renders the title, QR image, and both action buttons',
        (tester) async {
      await _pumpDialog(tester);

      expect(find.text('Share meal'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      // Copy and Share buttons each render an OutlinedButton.icon —
      // there are exactly two of them in the dialog.
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets(
        'share button reports a bounded, on-screen render rect '
        '(guards iPad popover anchor + iPhone presentation fix)',
        (tester) async {
      await _pumpDialog(tester);

      // Locate the share button by its icon — the dialog has only one
      // Icons.share_rounded, on the share OutlinedButton.icon.
      final shareIcon = find.byIcon(Icons.share_rounded);
      expect(shareIcon, findsOneWidget);

      final shareButton = find.ancestor(
        of: shareIcon,
        matching: find.byType(OutlinedButton),
      );
      expect(shareButton, findsOneWidget);

      // If a future refactor wraps the share button in an Expanded or
      // similarly layout-greedy ancestor without a Semantics(container:
      // true) escape hatch, this rect would balloon to the screen size
      // — which is exactly the failure mode we don't want feeding into
      // share_plus' sharePositionOrigin. Lock the button to something
      // sensibly small.
      final rect = tester.getRect(shareButton);
      expect(rect.width, lessThan(400));
      expect(rect.height, lessThan(100));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    });
  });
}
