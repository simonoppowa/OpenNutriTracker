import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.temporaryPath);

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final calls = <ShareParams>[];
  bool failFileShares = false;

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    if (failFileShares && params.files?.isNotEmpty == true) {
      throw StateError('file sharing unavailable');
    }
    return const ShareResult('success', ShareResultStatus.success);
  }
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  SharePlus? sharePlus,
  Future<List<int>> Function(String data)? qrImageRenderer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: ShareQrDialog(
          title: 'Share meal',
          code: 'sample-payload-code',
          fileBaseName: 'sample_qr',
          sharePlus: sharePlus,
          qrImageRenderer: qrImageRenderer,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapShareAndWait(
  WidgetTester tester,
  _FakeSharePlatform sharePlatform, {
  int expectedCalls = 1,
}) async {
  final shareButton = find.ancestor(
    of: find.byIcon(Icons.share_rounded),
    matching: find.byType(OutlinedButton),
  );
  final onPressed = tester.widget<OutlinedButton>(shareButton).onPressed!;
  await tester.runAsync(() async {
    onPressed();
    for (
      var attempt = 0;
      attempt < 50 && sharePlatform.calls.length < expectedCalls;
      attempt++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  final sharePlatform = _FakeSharePlatform();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_share_qr_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    sharePlatform.calls.clear();
    sharePlatform.failFileShares = false;
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('ShareQrDialog', () {
    testWidgets('renders the title, QR image, and both action buttons', (
      tester,
    ) async {
      await _pumpDialog(tester);

      expect(find.text('Share meal'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      // Copy and Share buttons each render an OutlinedButton.icon —
      // there are exactly two of them in the dialog.
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('share button reports a bounded, on-screen render rect '
        '(guards iPad popover anchor + iPhone presentation fix)', (
      tester,
    ) async {
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

    testWidgets('share button sends the QR image, code, and bounded origin', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        sharePlus: SharePlus.custom(sharePlatform),
        qrImageRenderer: (_) async => <int>[1, 2, 3],
      );

      await _tapShareAndWait(tester, sharePlatform);

      expect(sharePlatform.calls, hasLength(1));
      final params = sharePlatform.calls.single;
      expect(params.text, 'sample-payload-code');
      expect(params.files, hasLength(1));
      expect(params.sharePositionOrigin!.width, greaterThan(0));
      expect(params.sharePositionOrigin!.height, greaterThan(0));
    });

    testWidgets('falls back to text sharing when QR file sharing fails', (
      tester,
    ) async {
      sharePlatform.failFileShares = true;
      await _pumpDialog(
        tester,
        sharePlus: SharePlus.custom(sharePlatform),
        qrImageRenderer: (_) async => <int>[1, 2, 3],
      );

      await _tapShareAndWait(tester, sharePlatform, expectedCalls: 2);

      expect(sharePlatform.calls, hasLength(2));
      expect(sharePlatform.calls.first.files, hasLength(1));
      final fallback = sharePlatform.calls.last;
      expect(fallback.text, 'sample-payload-code');
      expect(fallback.files, isNull);
      expect(fallback.sharePositionOrigin!.width, greaterThan(0));
      expect(fallback.sharePositionOrigin!.height, greaterThan(0));
    });
  });
}
