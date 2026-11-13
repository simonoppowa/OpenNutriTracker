import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/share_qr_dialog.dart';
import 'package:opennutritracker/features/home/domain/entity/shared_meal_payload.dart';
import 'package:opennutritracker/features/recipes/domain/entity/shared_recipe_payload.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../helpers/test_l10n.dart';

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
  bool failTextShares = false;
  ShareResultStatus resultStatus = ShareResultStatus.success;
  Completer<void>? _callsCompleter;
  int _expectedCalls = 0;

  Future<void> waitForCalls(int expectedCalls) {
    if (calls.length >= expectedCalls) return Future<void>.value();
    _expectedCalls = expectedCalls;
    _callsCompleter = Completer<void>();
    return _callsCompleter!.future;
  }

  void reset() {
    calls.clear();
    failFileShares = false;
    failTextShares = false;
    resultStatus = ShareResultStatus.success;
    _callsCompleter = null;
    _expectedCalls = 0;
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    if (calls.length >= _expectedCalls &&
        _callsCompleter?.isCompleted == false) {
      _callsCompleter!.complete();
    }
    if (failFileShares && params.files?.isNotEmpty == true) {
      throw StateError('file sharing unavailable');
    }
    if (failTextShares && params.files == null) {
      throw StateError('text sharing unavailable');
    }
    return ShareResult('result', resultStatus);
  }
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  String code = 'sample-payload-code',
  double textScale = 1,
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ShareQrDialog(
          title: 'Share meal',
          code: code,
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
    final callsCompleted = sharePlatform.waitForCalls(expectedCalls);
    onPressed();
    await callsCompleted.timeout(const Duration(seconds: 1));
  });
}

// Incompressible metadata exercises real meal/recipe text, not a new protocol.
String _payloadCode(String kind, int metadataLength) {
  final random = Random(42);
  final metadata = String.fromCharCodes(
    List.generate(metadataLength, (_) => 33 + random.nextInt(90)),
  );
  if (kind == 'meal') {
    return SharedMealPayload.fromJsonString(
      jsonEncode([
        2,
        [
          ['4001724039143', 90, 'g'],
        ],
        [
          [
            metadata,
            'Brand',
            'ml',
            125.5,
            210.2,
            10,
            3,
            4,
            null,
            null,
            null,
            null,
            null,
            'fdc',
            'fdc-42',
          ],
        ],
        [],
      ]),
    ).toJsonString();
  }
  return SharedRecipePayload.fromJsonString(
    jsonEncode([
      1,
      'Soup',
      metadata,
      4,
      240,
      [210.2, 10, 3, 4, null, null, null],
      [
        [
          'Ingredient',
          'Brand',
          300,
          'g',
          300,
          210.2,
          10,
          3,
          4,
          null,
          null,
          null,
          null,
        ],
      ],
      1,
    ]),
  ).toJsonString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late PathProviderPlatform originalPathProvider;
  final sharePlatform = _FakeSharePlatform();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_share_qr_test_');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
    sharePlatform.reset();
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('ShareQrDialog', () {
    for (final kind in ['meal', 'recipe']) {
      testWidgets(
        'oversized $kind codes show feedback and copy/share exact text',
        (tester) async {
          final code = _payloadCode(kind, 3500);
          expect(code.length, greaterThan(2331));
          var rendered = false;
          String? copied;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          await _pumpDialog(
            tester,
            code: code,
            sharePlus: SharePlus.custom(sharePlatform),
            qrImageRenderer: (_) async {
              rendered = true;
              return [1, 2, 3];
            },
          );

          expect(find.text(l10nEn.shareQrTooLargeLabel), findsOneWidget);
          expect(find.byType(QrImageView), findsNothing);
          await tester.tap(
            find.widgetWithIcon(OutlinedButton, Icons.copy_rounded),
          );
          await tester.pump();
          expect(copied, code);
          await _tapShareAndWait(tester, sharePlatform);
          expect(rendered, isFalse);
          expect(sharePlatform.calls.single.text, code);
          expect(sharePlatform.calls.single.files, isNull);
          if (kind == 'meal') {
            final payload = SharedMealPayload.fromJsonString(copied!);
            expect(payload.offRefs.single.amount, 90);
            expect(payload.items.single.amount, 125.5);
            expect(payload.items.single.unit, 'ml');
            expect(payload.items.single.energyKcal100, 210.2);
            expect(payload.items.single.code, 'fdc-42');
          } else {
            final payload = SharedRecipePayload.fromJsonString(copied!);
            expect(payload.name, 'Soup');
            expect(payload.totalWeightG, 240);
            expect(payload.totalWeightOverridden, isTrue);
            expect(payload.ingredients.single.amount, 300);
            expect(payload.ingredients.single.energyKcal100, 210.2);
          }
        },
      );

      testWidgets('dense valid $kind QR grows with a four-module quiet zone', (
        tester,
      ) async {
        final code = _payloadCode(kind, 1500);
        expect(code.length, inInclusiveRange(1500, 2331));
        await _pumpDialog(tester, code: code);
        final qr = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qr.size, greaterThan(260));
        final modules = QrCode.fromData(
          data: code,
          errorCorrectLevel: QrErrorCorrectLevel.M,
        ).moduleCount;
        final moduleSize = (qr.size! - qr.padding.horizontal) / modules;
        expect(qr.padding.left, closeTo(4 * moduleSize, 0.001));
        final bounds = tester.getRect(find.byType(QrImageView));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(800));
        expect(bounds.bottom, lessThanOrEqualTo(600));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('maximum byte-mode QR exports a sharp PNG with quiet zone', (
      tester,
    ) async {
      // Version 40 at correction M holds 2331 bytes, not 2332 (ISO capacity).
      final code = 'x' * 2331;
      await _pumpDialog(
        tester,
        code: code,
        sharePlus: SharePlus.custom(sharePlatform),
      );
      await _tapShareAndWait(tester, sharePlatform);
      final params = sharePlatform.calls.single;
      expect(params.text, code);
      expect(params.files, hasLength(1));
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(
          await params.files!.single.readAsBytes(),
        );
        final image = (await codec.getNextFrame()).image;
        try {
          expect(image.width, 740);
          expect(image.height, 740);
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          // Four white modules, each four pixels wide, on every edge.
          for (var y = 0; y < 740; y++) {
            for (var x = 0; x < 740; x++) {
              if (x < 16 || y < 16 || x >= 724 || y >= 724) {
                expect(pixels.getUint32((y * 740 + x) * 4), 0xffffffff);
              }
            }
          }
          expect(pixels.getUint32((16 * 740 + 16) * 4), 0x000000ff);
          expect(pixels.getUint32((19 * 740 + 19) * 4), 0x000000ff);
          expect(pixels.getUint32((20 * 740 + 20) * 4), 0xffffffff);
        } finally {
          image.dispose();
          codec.dispose();
        }
      });
    });

    testWidgets('one byte over QR capacity and multibyte overflow stay text', (
      tester,
    ) async {
      await _pumpDialog(tester);
      expect(find.byType(QrImageView), findsOneWidget);
      for (final code in ['x' * 2332, '🍲' * 600]) {
        await _pumpDialog(
          tester,
          code: code,
          sharePlus: SharePlus.custom(sharePlatform),
        );
        expect(find.byType(QrImageView), findsNothing);
        await _tapShareAndWait(tester, sharePlatform);
        expect(sharePlatform.calls.single.text, code);
        expect(sharePlatform.calls.single.files, isNull);
        sharePlatform.reset();
      }
      await _pumpDialog(tester);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    // A short screen (a phone in landscape) must not shrink the code below
    // the old fixed size, past which a dense code stops scanning; the
    // dialog scrolls instead.
    testWidgets('short landscape screen keeps a dense QR at least 260 pt', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpDialog(tester, code: 'x' * 2000);
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, greaterThanOrEqualTo(260));
      await tester.ensureVisible(find.bySemanticsIdentifier('share-code'));
      expect(
        find.bySemanticsIdentifier('share-code').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final code in ['x' * 2331, 'x' * 2332]) {
      testWidgets('narrow screen with large text keeps actions reachable '
          '(${code.length} bytes)', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpDialog(tester, code: code, textScale: 2);
        await tester.ensureVisible(find.bySemanticsIdentifier('share-code'));
        expect(
          find.bySemanticsIdentifier('share-code').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final emptyImage in [false, true]) {
      testWidgets('renderer ${emptyImage ? 'returns empty bytes' : 'throws'} '
          'and shares the exact text', (tester) async {
        await _pumpDialog(
          tester,
          sharePlus: SharePlus.custom(sharePlatform),
          qrImageRenderer: (_) async {
            if (emptyImage) return [];
            throw StateError('render unavailable');
          },
        );
        await _tapShareAndWait(tester, sharePlatform);
        expect(sharePlatform.calls.single.text, 'sample-payload-code');
        expect(sharePlatform.calls.single.files, isNull);
      });
    }

    testWidgets('failed image file write shares the exact text', (
      tester,
    ) async {
      PathProviderPlatform.instance = _FakePathProvider(
        '${tempRoot.path}/missing',
      );
      await _pumpDialog(
        tester,
        sharePlus: SharePlus.custom(sharePlatform),
        qrImageRenderer: (_) async => [1, 2, 3],
      );
      await _tapShareAndWait(tester, sharePlatform);
      expect(sharePlatform.calls.single.text, 'sample-payload-code');
      expect(sharePlatform.calls.single.files, isNull);
    });

    testWidgets('cancelling image sharing does not launch text sharing', (
      tester,
    ) async {
      sharePlatform.resultStatus = ShareResultStatus.dismissed;
      await _pumpDialog(
        tester,
        sharePlus: SharePlus.custom(sharePlatform),
        qrImageRenderer: (_) async => [1, 2, 3],
      );
      await _tapShareAndWait(tester, sharePlatform);
      await tester.pumpAndSettle();
      expect(sharePlatform.calls, hasLength(1));
      expect(sharePlatform.calls.single.files, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed text fallback shows feedback and allows retry', (
      tester,
    ) async {
      sharePlatform.failTextShares = true;
      await _pumpDialog(
        tester,
        sharePlus: SharePlus.custom(sharePlatform),
        qrImageRenderer: (_) async => throw StateError('render unavailable'),
      );
      await _tapShareAndWait(tester, sharePlatform);
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.shareCodeErrorLabel), findsOneWidget);
      sharePlatform.failTextShares = false;
      await _tapShareAndWait(tester, sharePlatform, expectedCalls: 2);
      expect(sharePlatform.calls.last.text, 'sample-payload-code');
      expect(tester.takeException(), isNull);
    });

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
