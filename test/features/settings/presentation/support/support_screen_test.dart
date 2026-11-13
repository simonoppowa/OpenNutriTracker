import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/tip_jar_cubit.dart';
import 'package:opennutritracker/features/settings/presentation/support/support_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../../../../helpers/fake_tip_store.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSharePlatform extends SharePlatform with MockPlatformInterfaceMixin {
  final calls = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  late FakeTipStore store;
  late FakeTipConfig config;
  late TipJarCubit jar;
  late List<String> opened;
  late bool openResult;
  late _FakeSharePlatform sharePlatform;

  setUp(() async {
    store = FakeTipStore();
    config = FakeTipConfig();
    jar = TipJarCubit(store, config);
    opened = [];
    openResult = true;
    sharePlatform = _FakeSharePlatform();
  });

  tearDown(() async {
    await jar.close();
    await store.dispose();
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    // Inside the test's zone, so purchase updates run under its fake clock.
    await jar.start();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: SupportScreen(
          tipJar: jar,
          sharePlus: SharePlus.custom(sharePlatform),
          openUrl: (url) async {
            opened.add(url);
            return openResult;
          },
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Finder byId(String id) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.identifier == id,
  );

  Future<void> tapRow(WidgetTester tester, String id) async {
    await tester.scrollUntilVisible(byId(id), 200);
    await tester.tap(byId(id));
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('shows the header, three groups and seven ways in order', (
      tester,
    ) async {
      final labels = [
        l10nEn.supportGroupSpreadWord,
        l10nEn.supportRateTitle,
        l10nEn.supportShareTitle,
        l10nEn.supportStarTitle,
        l10nEn.supportGroupSkills,
        l10nEn.supportTranslateTitle,
        l10nEn.supportReportTitle,
        l10nEn.supportCodeTitle,
        l10nEn.supportGroupMoney,
        l10nEn.supportTipTitle,
      ];
      // Tall enough that the whole page is laid out at once.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpPage(tester);

      final icons = [
        Icons.star_rate_rounded,
        Icons.ios_share_rounded,
        Icons.star_outline_rounded,
        Icons.translate_rounded,
        Icons.lightbulb_outline_rounded,
        Icons.code_rounded,
        Icons.volunteer_activism_rounded,
      ];
      double top(Finder f) => tester.getTopLeft(f).dy;
      for (var i = 1; i < labels.length; i++) {
        expect(
          top(find.text(labels[i])),
          greaterThan(top(find.text(labels[i - 1]))),
          reason: '${labels[i]} should come after ${labels[i - 1]}',
        );
      }
      for (var i = 1; i < icons.length; i++) {
        expect(
          top(find.byIcon(icons[i])),
          greaterThan(top(find.byIcon(icons[i - 1]))),
          reason: '${icons[i]} should come after ${icons[i - 1]}',
        );
      }
      expect(find.text(l10nEn.settingsSupportLabel), findsOneWidget);
      expect(find.text(l10nEn.supportHeader), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(6));
      for (final subtitle in [
        l10nEn.supportRateSubtitle,
        l10nEn.supportShareSubtitle,
        l10nEn.supportStarSubtitle,
        l10nEn.supportTranslateSubtitle,
        l10nEn.supportReportSubtitle,
        l10nEn.supportCodeSubtitle,
        l10nEn.supportTipSubtitle,
      ]) {
        expect(find.text(subtitle), findsOneWidget, reason: subtitle);
      }

      for (final id in [
        'support-way-rate',
        'support-way-share',
        'support-way-star',
        'support-way-translate',
        'support-way-report',
        'support-way-code',
      ]) {
        expect(byId(id), findsOneWidget, reason: id);
      }
    });
  });

  group('links', () {
    testWidgets('each row opens its target', (tester) async {
      await pumpPage(tester);

      await tapRow(tester, 'support-way-star');
      await tapRow(tester, 'support-way-translate');
      await tapRow(tester, 'support-way-report');
      await tapRow(tester, 'support-way-code');

      expect(opened, [
        'https://github.com/simonoppowa/OpenNutriTracker',
        'https://hosted.weblate.org/engage/opennutritracker/',
        'https://github.com/simonoppowa/OpenNutriTracker/issues/new/choose',
        'https://github.com/simonoppowa/OpenNutriTracker/blob/main/CONTRIBUTING.md',
      ]);
    });

    testWidgets('Rate opens the Play listing on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pumpPage(tester);

      await tapRow(tester, 'support-way-rate');

      expect(opened, [
        'https://play.google.com/store/apps/details?id=com.opennutritracker.ont.opennutritracker',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Rate opens the write-a-review form on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpPage(tester);

      await tapRow(tester, 'support-way-rate');

      expect(opened, [
        'https://apps.apple.com/app/id6451490901?action=write-review',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a link that cannot open says so', (tester) async {
      openResult = false;
      await pumpPage(tester);

      await tapRow(tester, 'support-way-star');

      expect(find.text(l10nEn.errorOpeningBrowser), findsOneWidget);
    });

    testWidgets('Share sends the description and both store links', (
      tester,
    ) async {
      await pumpPage(tester);

      await tapRow(tester, 'support-way-share');

      final params = sharePlatform.calls.single;
      expect(params.text, startsWith(l10nEn.appDescription));
      expect(params.text, contains(AppConst.appStoreUrl));
      expect(params.text, contains(AppConst.playStoreUrl));
      expect(params.sharePositionOrigin, isNotNull);
      expect(opened, isEmpty);
    });
  });

  group('tip states', () {
    Future<void> scrollToTips(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.text(l10nEn.supportTipTitle), 200);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    testWidgets('loading shows a spinner and no chips', (tester) async {
      store.queryGate = Completer<void>();
      // The spinner never settles, so the page is laid out whole instead of
      // scrolled to.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpPage(tester, settle: false);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(byId('support-tip-small'), findsNothing);
      expect(byId('support-tip-retry'), findsNothing);

      store.queryGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('loaded shows three chips, cheapest first, with store prices', (
      tester,
    ) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      for (final id in [
        'support-tip-small',
        'support-tip-medium',
        'support-tip-large',
      ]) {
        expect(byId(id), findsOneWidget, reason: id);
      }
      final small = tester.getCenter(byId('support-tip-small'));
      final medium = tester.getCenter(byId('support-tip-medium'));
      final large = tester.getCenter(byId('support-tip-large'));
      expect(small.dx, lessThan(medium.dx));
      expect(medium.dx, lessThan(large.dx));
      expect(find.text(l10nEn.supportTipSmall), findsOneWidget);
      expect(find.text('€1.99'), findsOneWidget);
      expect(find.text('€4.99'), findsOneWidget);
      expect(find.text('€9.99'), findsOneWidget);
      expect(find.text(l10nEn.supportTipLeft), findsNothing);
    });

    testWidgets('a partial load shows only the tips that loaded', (
      tester,
    ) async {
      store.products = tipProducts(only: {'tip_small', 'tip_large'});
      await pumpPage(tester);
      await scrollToTips(tester);

      expect(byId('support-tip-small'), findsOneWidget);
      expect(byId('support-tip-medium'), findsNothing);
      expect(byId('support-tip-large'), findsOneWidget);
    });

    testWidgets('failed replaces the chips with the notice and Retry', (
      tester,
    ) async {
      store.available = false;
      await pumpPage(tester);
      await scrollToTips(tester);

      expect(find.text(l10nEn.supportTipLoadFailed), findsOneWidget);
      expect(byId('support-tip-retry'), findsOneWidget);
      expect(byId('support-tip-small'), findsNothing);
      // The other ways are unaffected.
      expect(byId('support-way-code'), findsOneWidget);
    });

    testWidgets('Retry loads the tips again', (tester) async {
      store.products = [];
      await pumpPage(tester);
      await scrollToTips(tester);
      expect(byId('support-tip-retry'), findsOneWidget);

      store.products = tipProducts();
      await tester.tap(find.text(l10nEn.retryLabel));
      await tester.pumpAndSettle();

      expect(byId('support-tip-retry'), findsNothing);
      expect(byId('support-tip-medium'), findsOneWidget);
      expect(store.queryCalls, 2);
    });

    testWidgets('a chip opens the store sheet for its tip', (tester) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      await tester.tap(byId('support-tip-large'));
      await tester.pumpAndSettle();

      expect(store.bought.single.id, 'tip_large');
    });

    testWidgets('purchased thanks, then shows the line under the chips', (
      tester,
    ) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      store.emit([tipPurchase('tip_small', PurchaseStatus.purchased)]);
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.supportTipThanksTitle), findsOneWidget);
      expect(
        find.text(l10nEn.supportTipThanksBody(l10nEn.supportTipSmall, '€1.99')),
        findsOneWidget,
      );

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.supportTipThanksTitle), findsNothing);
      expect(find.text(l10nEn.supportTipLeft), findsOneWidget);
      // The chips stay.
      expect(byId('support-tip-small'), findsOneWidget);
      // Text only: no icon beside the line.
      final line = find.text(l10nEn.supportTipLeft);
      expect(
        find.descendant(
          of: find.ancestor(of: line, matching: find.byType(Column)).first,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNothing,
      );
      expect(config.hasLeftTip, isTrue);
    });

    testWidgets('a tip left earlier shows the line on opening', (tester) async {
      config.hasLeftTip = true;
      await pumpPage(tester);
      await scrollToTips(tester);

      expect(find.text(l10nEn.supportTipLeft), findsOneWidget);
    });

    testWidgets('pending says the payment is waiting and does not thank', (
      tester,
    ) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      store.emit([tipPurchase('tip_small', PurchaseStatus.pending)]);
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.supportTipPending), findsOneWidget);
      expect(find.text(l10nEn.supportTipThanksTitle), findsNothing);
      expect(find.text(l10nEn.supportTipLeft), findsNothing);
    });

    testWidgets('an error says the tip did not go through', (tester) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      store.emit([tipPurchase('tip_small', PurchaseStatus.error)]);
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.supportTipFailed), findsOneWidget);
      expect(find.text(l10nEn.supportTipLeft), findsNothing);
    });

    testWidgets('a cancel shows nothing', (tester) async {
      await pumpPage(tester);
      await scrollToTips(tester);

      store.emit([
        tipPurchase(
          'tip_small',
          PurchaseStatus.canceled,
          pendingComplete: false,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(l10nEn.supportTipLeft), findsNothing);
    });
  });
}
