import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:opennutritracker/features/onboarding/onboarding_screen.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/main.dart' as app;

/// Single-boot smoke for the whole first-run path. Everything here shares
/// one `app.main()` deliberately: `initLocator()` registers its GetIt
/// singletons without a re-registration guard, so a second `app.main()` in
/// the same process would throw. Keeping the checks in one boot (rather than
/// several test files) is what lets the suite run unsharded — a single
/// `flutter test integration_test/` per platform that pays the build and
/// simulator cost once.
///
/// The assertions cover three failure surfaces that cascade from that boot:
///   - boot health: `main()` finishes and lands a MaterialApp, and nothing
///     trips `FlutterError.onError` along the way. The first catches loud
///     failures (Hive can't open, secure storage can't derive its AES key,
///     Supabase init throws, a missing GetIt dependency); the second catches
///     quiet ones (a Hive type-id collision, a dropped `await` in plugin
///     init, a half-broken notification re-register) that leave something
///     half-initialised without crashing the visible screen.
///   - routing: a fresh install has no user data, so `hasUserData()` returns
///     false and the router lands on OnboardingScreen with IntroductionScreen
///     mounted (which only happens once OnboardingBloc reaches its loaded
///     state).
///   - localisation: the intl delegates load and the `appDescription` ARB
///     entry reaches the intro page body and renders, in whichever locale
///     the device is set to. On an English device the copy itself is pinned,
///     so a wording change forces this test to be updated alongside it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'fresh install boots cleanly into a fully-rendered onboarding intro',
    (WidgetTester tester) async {
      final caught = <FlutterErrorDetails>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        caught.add(details);
        original?.call(details);
      };
      addTearDown(() => FlutterError.onError = original);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Boot health.
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: 'app should reach a MaterialApp');
      expect(
        caught,
        isEmpty,
        reason: 'no Flutter errors should fire during boot, got: '
            '${caught.map((e) => e.exception).toList()}',
      );

      // Routing: with no user data, the first screen is onboarding.
      expect(find.byType(OnboardingScreen), findsOneWidget,
          reason: 'with no user data, the first screen should be onboarding');

      // Bloc state: IntroductionScreen mounts only after the bloc reaches
      // OnboardingLoadedState.
      expect(find.byType(IntroductionScreen), findsOneWidget,
          reason: 'OnboardingBloc should transition into loaded state');

      // Localisation: the delegates resolved and the appDescription ARB entry
      // reached the intro page body. Looked up for whichever locale the app
      // resolved to, so the test passes on a device set to any supported
      // language; asserting a hardcoded English string here failed on, say,
      // a German phone even though nothing was wrong.
      final introContext = tester.element(find.byType(OnboardingIntroPageBody));
      final localizedDescription = S.of(introContext).appDescription;
      expect(localizedDescription, isNotEmpty,
          reason: 'appDescription should be translated for '
              '${S.of(introContext).localeName}');
      expect(find.text(localizedDescription), findsOneWidget,
          reason: 'the localised appDescription should render on the intro page');

      // On an English device, also pin the copy itself: a verbatim copy of the
      // English ARB entry, so a wording change has to be made here too. CI
      // runs English, which is where this half earns its keep.
      if (S.of(introContext).localeName.startsWith('en')) {
        const appDescriptionEn =
            'OpenNutriTracker is a free and open-source calorie and '
            'nutrient tracker that respects your privacy.';
        expect(localizedDescription, appDescriptionEn,
            reason: 'the English appDescription copy changed');
      }
    },
  );
}
