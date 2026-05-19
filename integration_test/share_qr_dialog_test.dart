import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// On a real iPhone simulator running on the `macos-latest` runner, verify
/// that tapping the share button in [ShareQrDialog] invokes share_plus with
/// a non-null `sharePositionOrigin` — the missing-anchor case is precisely
/// what kept the iOS share sheet from presenting in the original bug. We
/// intercept the platform channel so the activity view controller never
/// actually presents, keeping the test unattended.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tapping share dispatches an origin rect to share_plus',
    (WidgetTester tester) async {
      const channel = MethodChannel('dev.fluttercommunity.plus/share');

      MethodCall? lastCall;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          lastCall = call;
          // share_plus expects a String back; a real channel returns the
          // chosen activity identifier. Anything non-null short-circuits
          // the "unavailable" branch in the platform interface.
          return 'dev.fluttercommunity.plus/share/test';
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

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
              fileBaseName: 'integration_share_qr',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.share));
      // Encoding the QR + writing the temp file is async — give it room
      // to finish before asserting on the channel call.
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(lastCall, isNotNull,
          reason: 'Share tap never reached the share_plus platform channel');
      expect(
        lastCall!.method,
        anyOf('shareFiles', 'shareXFiles', 'share', 'shareUri'),
      );

      final args = lastCall!.arguments as Map;
      expect(args['originX'], isNotNull,
          reason: 'sharePositionOrigin missing — iOS share sheet would '
              'fail to present from inside an AlertDialog');
      expect(args['originY'], isNotNull);
      expect(args['originWidth'], isNotNull);
      expect(args['originHeight'], isNotNull);

      // The rect should describe the share button's on-screen position,
      // not the whole screen or a zero rect at (0,0). Reasonable bounds:
      // a touch target, somewhere in the dialog's visible area.
      final width = args['originWidth'] as num;
      final height = args['originHeight'] as num;
      expect(width, greaterThan(0));
      expect(height, greaterThan(0));
      expect(width, lessThan(400));
      expect(height, lessThan(100));
    },
  );
}
