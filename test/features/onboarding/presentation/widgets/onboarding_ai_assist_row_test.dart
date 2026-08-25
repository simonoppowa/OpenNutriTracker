import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/badged_title.dart';
import 'package:opennutritracker/core/presentation/widgets/section_group.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_other_options_page_body.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_assist_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

class _MemoryStorage implements FlutterSecureStorage {
  /// Starts with the agreement already given.
  ///
  /// A stored credential is only usable once the user has agreed to what
  /// leaves the device (#836), so a store holding a key and no agreement is a
  /// state the app cannot reach. These tests arrange a working feature, which
  /// now means configured *and* agreed to.
  final store = <String, String>{'AiTermsAcceptedTag': 'true'};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Reads land after a delay, which the in-memory store cannot reproduce: its
/// future resolves in the same microtask drain as the first `pump`, so the row
/// is already populated by the time a test can look at it. The real keystore
/// is a platform channel and takes frames.
class _DelayedStorage extends _MemoryStorage {
  static const delay = Duration(milliseconds: 50);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => Future.delayed(delay, () => store[key]);
}

/// The AI row on onboarding's Other options page. #728.
void main() {
  late AiCredentialStorage storage;

  setUp(() {
    storage = AiCredentialStorage(_MemoryStorage());
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    AiCredentialStorage? credentials,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Size size = const Size(411, 891),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeModeProvider>(
        create: (_) => ThemeModeProvider(appTheme: AppThemeEntity.system),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: OnboardingOtherOptionsPageBody(
                setPageContent: (_, _, _, _, _) {},
                initialTheme: AppThemeEntity.system,
                initialFoodSourceToggles: const {},
                initialDailyReminderEnabled: false,
                initialUseMaterialYou: true,
                initialAccentColor: null,
                aiCredentials: credentials,
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // One frame: the keystore read is still in flight, which is the state
      // the loading case needs to observe.
      await tester.pump();
    }
  }

  testWidgets('before the keystore read lands the row has no subtitle line', (
    tester,
  ) async {
    // `aiAssistSubtitle` returns null while `hasKey` is unread so the row says
    // nothing rather than something wrong. Rendering that null as `Text('')`
    // honours the letter and loses the point — an empty Text still occupies
    // its line, so the row resizes under the user as the read comes back.
    // Caught by review on #729.
    await pumpPage(
      tester,
      credentials: AiCredentialStorage(_DelayedStorage()),
      settle: false,
    );

    final tile = tester.widget<ListTile>(
      find.descendant(
        of: find.bySemanticsIdentifier('onboarding-ai-assist'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.subtitle, isNull);

    // Stepped rather than `pumpAndSettle`: the three keystore reads are
    // sequential delays and settling races them.
    await tester.pump(_DelayedStorage.delay * 10);
    await tester.pump();
    expect(
      find.text(l10nEn.settingsAiAssistNotConfiguredLabel),
      findsOneWidget,
      reason: 'and it arrives once the read completes',
    );
  });

  testWidgets('the row is absent when no storage is wired', (tester) async {
    // The dependency is injected rather than fetched from the locator, so a
    // caller that does not supply one gets the page as it was. That is what
    // keeps the eight tests written before this row from needing a locator.
    await pumpPage(tester);

    expect(find.byType(SectionHeader), findsNWidgets(3));
    expect(find.text(l10nEn.aiAssistExperimentalLabel), findsNothing);
  });

  testWidgets('the row is last, and marked experimental', (tester) async {
    await pumpPage(tester, credentials: storage);

    expect(find.byType(SectionHeader), findsNWidgets(4));
    expect(find.text(l10nEn.aiAssistExperimentalLabel), findsOneWidget);

    // Last on the page: it needs an account and a card at a model provider,
    // so it is the least likely of these to be usable at first run, and the
    // only one that changes what leaves the device.
    final headers = tester
        .widgetList<SectionHeader>(find.byType(SectionHeader))
        .map((h) => h.label)
        .toList();
    expect(headers.last, l10nEn.settingsAiAssistLabel);
  });

  testWidgets('with no key it says so, rather than saying nothing', (
    tester,
  ) async {
    await pumpPage(tester, credentials: storage);

    expect(
      find.text(l10nEn.settingsAiAssistNotConfiguredLabel),
      findsOneWidget,
    );
  });

  testWidgets('a key that survived a data wipe is reported, not hidden', (
    tester,
  ) async {
    // `DeleteAllUserDataUsecase.deleteAll()` clears Hive boxes only, and
    // these credentials live in the platform keystore — so "delete all my
    // data" returns the user to onboarding with a usable key still stored.
    // The row saying so is the only place that becomes visible, and it is one
    // tap from removing it.
    await storage.setActiveProvider(AiProvider.openai);
    await storage.writeApiKey('sk-test', provider: AiProvider.openai);
    await storage.setEnabled(true);

    await pumpPage(tester, credentials: storage);

    expect(find.textContaining(l10nEn.settingsAiAssistOnLabel), findsOneWidget);
    expect(find.textContaining('OpenAI'), findsOneWidget);
  });

  testWidgets('a paused key reads as paused, not as off', (tester) async {
    await storage.writeApiKey('sk-test', provider: AiProvider.anthropic);
    await storage.setEnabled(false);

    await pumpPage(tester, credentials: storage);

    expect(find.text(l10nEn.settingsAiAssistPausedLabel), findsOneWidget);
  });

  testWidgets('tapping the row opens the shared settings dialog', (
    tester,
  ) async {
    // The dialog rather than a restatement of it: the disclosure and the
    // per-provider retention text are the load-bearing part and exist once.
    await pumpPage(tester, credentials: storage);

    await tester.tap(find.bySemanticsIdentifier('onboarding-ai-assist'));
    await tester.pumpAndSettle();

    expect(find.byType(AiAssistDialog), findsOneWidget);
    expect(
      find.textContaining(l10nEn.aiAssistDisclosureCommon),
      findsOneWidget,
      reason: 'the disclosure comes with the dialog, not from a second copy',
    );
  });

  testWidgets('the row catches up with what the dialog changed', (
    tester,
  ) async {
    // The reason this row keeps live state at all. The dialog writes
    // immediately — pausing here is a keystore write, not a staged edit — so
    // a row that read once at initState would keep claiming the feature is on
    // after the user turned it off, which is the "stale subtitle
    // misdescribes what leaves the device" failure Settings refreshes
    // unconditionally to avoid.
    //
    // A mutation caught the absence of this test: deleting the refresh after
    // `AiAssistDialog.show` left every other test on this page green.
    await storage.writeApiKey('sk-test', provider: AiProvider.anthropic);
    await storage.setEnabled(true);

    await pumpPage(tester, credentials: storage);
    expect(find.textContaining(l10nEn.settingsAiAssistOnLabel), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('onboarding-ai-assist'));
    await tester.pumpAndSettle();

    // Scoped to the dialog: the page underneath has its own Switch for the
    // daily reminder, and an unscoped `.first` taps that one instead.
    final dialogSwitch = find.descendant(
      of: find.byType(AiAssistDialog),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(dialogSwitch);
    await tester.pumpAndSettle();
    await tester.tap(dialogSwitch);
    await tester.pumpAndSettle();
    expect(await storage.isEnabled(), isFalse);

    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.settingsAiAssistPausedLabel), findsOneWidget);
    expect(find.textContaining(l10nEn.settingsAiAssistOnLabel), findsNothing);
  });

  testWidgets('the badged title survives 2x German without overflowing', (
    tester,
  ) async {
    // Where the dialog's own 48px overflow was found, which is why its title
    // deliberately carries no marker. This row is inside a scroll view, so it
    // has room the dialog title did not — measured rather than assumed.
    await pumpPage(
      tester,
      credentials: storage,
      locale: const Locale('de'),
      textScale: 2.0,
      size: const Size(320, 800),
    );

    expect(find.byType(BadgedTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
