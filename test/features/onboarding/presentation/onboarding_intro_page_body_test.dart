import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/test_l10n.dart';

/// url_launcher's platform channel. `launchUrl` reaches it as a `launch` call
/// carrying the URL under `'url'`.
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

/// Records the URLs the widget asks the platform to open, and opens nothing.
///
/// Mocks the method channel rather than swapping `UrlLauncherPlatform.instance`.
/// The latter reads better, but the types it needs live in
/// `url_launcher_platform_interface`, which is only a transitive dependency —
/// importing it means declaring it, and this is not worth a dependency. The
/// channel name and its `launch`/`canLaunch` methods are the plugin's own
/// stable surface.
///
/// [succeeds] models a device with no browser — the launch reporting false
/// rather than throwing. [throwsPlatformException] models the other shape the
/// same failure takes, where no activity can handle the intent at all.
class _RecordingLauncher {
  _RecordingLauncher({
    this.succeeds = true,
    this.throwsPlatformException = false,
  });

  final bool succeeds;
  final bool throwsPlatformException;
  final launched = <String>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
      switch (call.method) {
        case 'canLaunch':
          return succeeds;
        case 'launch':
          launched.add(
            (call.arguments as Map<Object?, Object?>)['url'] as String,
          );
          if (throwsPlatformException) {
            throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
          }
          return succeeds;
      }
      return null;
    });
  }

  static void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
  }
}

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
    Locale? locale,
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      // Mirrors main.dart. Without the global delegates a non-English locale
      // warns that MaterialLocalizations is missing, and that warning is
      // thrown as an exception under test.
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
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

  /// Pumps the page for [locale] and fires the recognizer on the policy link.
  ///
  /// Driven through the recognizer the widget installed rather than through
  /// `tapOnText`, because the label is not unique on the page in every
  /// language — German renders "Datenschutzrichtlinie" twice, and `tapOnText`
  /// requires a single match.
  Future<void> tapPolicyLink(WidgetTester tester, Locale locale) async {
    await pumpIntroPage(tester, onSetPageContent: (_, _) {}, locale: locale);

    final policyTile = find.ancestor(
      of: find.byType(Checkbox).first,
      matching: find.byType(ListTile),
    );
    final richText = tester.widget<RichText>(
      find.descendant(of: policyTile, matching: find.byType(RichText)).first,
    );

    TapGestureRecognizer? link;
    richText.text.visitChildren((span) {
      if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
        link = span.recognizer as TapGestureRecognizer;
        return false;
      }
      return true;
    });

    expect(
      link?.onTap,
      isNotNull,
      reason: 'the policy label should carry a tappable link',
    );
    link!.onTap!();
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

  group('the privacy policy link follows the device language', () {
    late _RecordingLauncher launcher;

    setUp(() => launcher = _RecordingLauncher()..install());
    tearDown(_RecordingLauncher.remove);

    testWidgets('a German device opens the German document', (tester) async {
      await tapPolicyLink(tester, const Locale('de'));

      expect(launcher.launched, [URLConst.privacyPolicyURLDe]);
    });

    testWidgets('an English device opens the English document', (tester) async {
      await tapPolicyLink(tester, const Locale('en'));

      expect(launcher.launched, [URLConst.privacyPolicyURLEn]);
    });

    testWidgets('a locale with no document of its own gets English',
        (tester) async {
      // Czech ships as an app language but has no policy document, and
      // sending that reader to the German one would be worse than English.
      await tapPolicyLink(tester, const Locale('cs'));

      expect(launcher.launched, [URLConst.privacyPolicyURLEn]);
    });

    testWidgets('a link that opens says nothing', (tester) async {
      await tapPolicyLink(tester, const Locale('en'));

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason: 'the happy path must stay silent',
      );
    });
  });

  group('a policy link that cannot open says so', () {
    tearDown(_RecordingLauncher.remove);

    testWidgets('a device with no browser reports it', (tester) async {
      // This link is the only way to read the policy the checkbox below asks
      // you to accept, so a tap that does nothing reads as broken.
      _RecordingLauncher(succeeds: false).install();

      await tapPolicyLink(tester, const Locale('en'));

      expect(find.text(l10nEn.errorOpeningBrowser), findsOneWidget);
    });

    testWidgets('a platform exception is reported, not thrown', (tester) async {
      // The same failure arrives as a throw when no activity can handle the
      // intent at all. It must reach the user as the same message rather than
      // as an unhandled async error nobody sees.
      _RecordingLauncher(throwsPlatformException: true).install();

      await tapPolicyLink(tester, const Locale('en'));

      expect(find.text(l10nEn.errorOpeningBrowser), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the failure notice is localized', (tester) async {
      _RecordingLauncher(succeeds: false).install();

      await tapPolicyLink(tester, const Locale('de'));

      expect(
        find.text(lookupS(const Locale('de')).errorOpeningBrowser),
        findsOneWidget,
      );
    });
  });
}
