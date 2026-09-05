import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/presentation/main_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/demo_mode_banner.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/main.dart' as app;
import 'package:path_provider/path_provider.dart';

/// Captures the six store screenshots decided in #1072, in one app boot, on
/// whatever device `flutter test -d ...` is pointed at.
///
/// This is the capture half of the pipeline. It produces **raw** PNGs at the
/// device's native pixel size; the caption layer is composited afterwards on
/// the host by `tools/screenshots/compose.py`, which is deliberately not part
/// of the app so the Play path can reuse it (#1072 requires captions on both
/// stores' sets, and the Play captures already exist uncaptioned).
///
/// ## Why this is an integration test rather than a `fastlane snapshot`
/// UI-test target
///
/// `snapshot` drives an XCUITest target, and there is no XCUITest target in
/// `ios/Runner.xcodeproj` — adding one means editing `project.pbxproj` across
/// six build configurations, on a machine nobody here has, for a test that
/// then has to find its way around a single opaque `FlutterView`. This file
/// navigates with the same widget finders the repo's other tests use, runs on
/// the runner image that `ios-integration-attempt.yml` has already proven can
/// boot a simulator and connect to the VM service, and runs unchanged on an
/// Android emulator.
///
/// ## Why it skips itself by default
///
/// Two jobs run `flutter test integration_test/` — the whole directory, not a
/// named file. `android-integration-tests` in `default_workflow.yml` runs it
/// on **every pull request**, and `ios-integration-attempt.yml` runs it on
/// every push to `develop` and `main` (it is excluded from pull requests,
/// which is map #1016's work). Without a gate, this file would join both,
/// seed a year of demo data into each, and make them slower and flakier for
/// no benefit. The screenshot lane passes
/// `--dart-define=STORE_SCREENSHOTS=true`; nothing else does, so everywhere
/// else this test is skipped at compile time.
const bool _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');

/// Which demo fixture stands behind the shots.
///
/// `dev` is a year of history with a 15-day guaranteed streak and ~10% missed
/// days; `onboarding` is three weeks where every day is on-track by
/// construction. `dev` is the default because shot 4 is Trends — a streak, a
/// calorie line and daily averages — and three weeks of perfect days makes a
/// chart with nothing in it to read. It is also what the Play set shipped
/// with in #1085, so both stores show the same account.
const String _fixture = String.fromEnvironment(
  'SCREENSHOT_FIXTURE',
  defaultValue: 'dev',
);

/// Preset index 07 in `lib/core/styles/accent_colors.dart` — `0xFF43A047`,
/// the brand green. Pinned rather than left to the device: on Android,
/// Material You seeds the whole palette from the wallpaper and rendered the
/// app blue for the Play re-shoot (#1075), which would have clashed with the
/// green icon and feature graphic. iOS has no wallpaper extraction, but the
/// pin costs nothing and this file is meant to run on both.
const int _brandAccentIndex = 7;

/// Written into the app's own documents directory rather than handed back
/// over a `flutter drive` channel. The host pulls them out of the simulator
/// with `xcrun simctl get_app_container <udid> <bundle-id> data`, which keeps
/// this a plain `flutter test` invocation — the exact command shape
/// `ios-integration-attempt.yml` already runs green — instead of introducing
/// `flutter_driver` and a second, unproven tool path.
const String _outDirName = 'store_screenshots';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'captures the six App Store / Play screenshots',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      final outDir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$_outDirName',
      );
      if (outDir.existsSync()) {
        outDir.deleteSync(recursive: true);
      }
      outDir.createSync(recursive: true);

      LoggerConfig.intiLogger();
      await initLocator();

      await seedDemoData(
        _fixture == 'onboarding'
            ? DemoSeedOptions.onboarding
            : DemoSeedOptions.dev,
      );

      // THE TRAP, and the reason this file exists rather than a shell script.
      //
      // `seedDemoData` ends with `setConfigIsDemoData(true)`
      // (`demo_seeder.dart:297`), which pins `DemoModeBanner` to the top of
      // every tab in `MainScreen`. Both seeding routes do it — `main_dev.dart`
      // and onboarding's "try it with sample data" — so there is no seeded
      // state anywhere in the app that does not carry the banner. The Play
      // re-shoot (#1075) got around it with an uncommitted local
      // `setIsDemoData(false)`, which is not a thing CI can run.
      //
      // Clearing it here is honest rather than a cheat: the flag means "this
      // profile holds sample data", the banner means "you are looking at
      // sample data", and a store screenshot is not the user's own device.
      // The assertion further down is what makes it enforceable — if a future
      // change reintroduces the banner, the run fails instead of quietly
      // shipping six banner-topped images.
      await locator<AddConfigUsecase>().setConfigIsDemoData(false);

      // Boot straight into the app with every presentation choice pinned,
      // rather than through `main()` — `main()` reads the theme, locale,
      // energy unit and accent back out of config, and a screenshot set must
      // not depend on what the runner's simulator happens to have persisted.
      // `userInitialized: true` skips onboarding, exactly as
      // `lib/dev/main_dev.dart` does.
      app.runAppWithChangeNotifiers(
        true,
        AppThemeEntity.light,
        const Locale('en'),
        false, // kcal, not kJ
        false, // Material You off — see _brandAccentIndex
        _brandAccentIndex,
      );
      // The first argument to pumpAndSettle is the interval *between* frames,
      // not a timeout, and under the live binding that interval is real
      // elapsed time — so this is "give boot 30 seconds, then settle". It is
      // the idiom `app_boot_test.dart` already uses against this app's boot,
      // which is the only reason to trust the number.
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Android renders Flutter into a SurfaceView that `takeScreenshot`
      // cannot read; this swaps it for an ImageView. It is a documented no-op
      // on iOS (`IntegrationTestPlugin.m`), so it is called unconditionally
      // rather than behind a platform check — and it is called *after* the
      // app is up, which is the order the package's own example uses and the
      // order that has something to convert.
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(
        find.byType(MainScreen),
        findsOneWidget,
        reason: 'the seeded profile should skip onboarding and land on '
            'MainScreen; a fresh-install onboarding screen here means the '
            'seed did not take',
      );
      expect(
        find.byType(DemoModeBanner),
        findsNothing,
        reason: 'setConfigIsDemoData(false) did not take — every capture '
            'would carry the demo banner (#1075)',
      );

      // --- 1. Home: the calorie ring, macros, real logged data -------------
      await _shoot(tester, binding, outDir, '01-home', find.byType(HomePage));

      // --- Diary: three of the six shots come off this one page ------------
      await _tapNav(tester, 'nav-diary');
      expect(
        find.byType(DiaryPage),
        findsOneWidget,
        reason: 'tapping the diary nav item should show DiaryPage',
      );

      // 5. The calendar sits at the top of the diary's list, so it is already
      //    in frame before any scrolling.
      await _shoot(
        tester,
        binding,
        outDir,
        '05-diary-calendar',
        find.byType(DiaryTableCalendar),
      );

      // 2. The day's logged meals with their photos and per-meal macros.
      await _scrollDiaryTo(tester, find.byType(IntakeVerticalList).first);
      await _shoot(
        tester,
        binding,
        outDir,
        '02-diary-meals',
        find.byType(IntakeVerticalList).first,
      );

      // 3. The micronutrient panel, expanded. It is an ExpansionTile that
      //    starts collapsed, so the shot needs the tap as well as the scroll.
      await _scrollDiaryTo(tester, find.byType(DailyNutrientPanel));
      await tester.tap(
        find.descendant(
          of: find.byType(DailyNutrientPanel),
          matching: find.byType(ExpansionTile),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollDiaryTo(tester, find.byType(DailyNutrientPanel));
      await _shoot(
        tester,
        binding,
        outDir,
        '03-micronutrients',
        find.byType(DailyNutrientPanel),
      );

      // --- 4. Trends: streak, calorie line, daily averages ------------------
      await _tapNav(tester, 'nav-trends');
      await _shoot(
        tester,
        binding,
        outDir,
        '04-trends',
        find.byType(TrendsPage),
      );

      // --- 6. Profile: goal, weight, BMI -----------------------------------
      await _tapNav(tester, 'nav-you');
      await _shoot(
        tester,
        binding,
        outDir,
        '06-profile',
        find.byType(ProfilePage),
      );

      final written = outDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .length;
      expect(
        written,
        6,
        reason: 'the shot list settled in #1072 is six screens; wrote $written',
      );
    },
    // See _enabled: this file shares integration_test/ with the boot smoke
    // that runs on every pull request, and must not join it there.
    skip: !_enabled,
  );
}

/// Taps one of `MainScreen`'s bottom-navigation items by its
/// `Semantics(identifier:)` — the same handles `tools/adb/adb-driver.sh`
/// drives the app with, so the two drivers agree on what a nav item is
/// called.
Future<void> _tapNav(WidgetTester tester, String identifier) async {
  final item = find.bySemanticsIdentifier(identifier);
  expect(
    item,
    findsOneWidget,
    reason: 'no bottom-nav item with semantics identifier "$identifier"',
  );
  await tester.tap(item);
  await tester.pumpAndSettle();
  // A bare pumpAndSettle returns as soon as no frame is scheduled, which
  // happens while a page's bloc is still awaiting its first load — so it can
  // return on an empty screen. The explicit pump gives that load real time to
  // land. `_shoot` refusing to capture over a spinner is the backstop.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Scrolls the diary's outer `ListView` until [target] is on screen.
///
/// The scrollable is addressed explicitly: `DiaryTableCalendar` contains a
/// `PageView` of its own, so a bare `find.byType(Scrollable)` is ambiguous.
/// The outer list is the first `Scrollable` under `DiaryPage` in depth-first
/// order because the calendar is one of its children.
Future<void> _scrollDiaryTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find
        .descendant(
          of: find.byType(DiaryPage),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 80,
  );
  await tester.pumpAndSettle();
}

/// Captures one screen, after checking that the screen it is supposed to be
/// capturing is actually on it.
///
/// The `mustBeVisible` check is the iOS counterpart of the focused-window
/// assertion the Android capture loop needs (#1075): there, a stray
/// back-press produced a full set of the launcher home screen that looked
/// plausible until someone opened the files. `capturePngScreenshot` on iOS
/// renders this app's own windows, so it cannot photograph SpringBoard — but
/// it will very happily photograph a spinner, an empty state, or a route that
/// never opened. Asserting the subject is present turns all of those into a
/// failed run instead of a bad asset.
Future<void> _shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Directory outDir,
  String name,
  Finder mustBeVisible,
) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  expect(
    mustBeVisible,
    findsWidgets,
    reason: 'refusing to capture "$name": its subject is not on screen',
  );
  expect(
    find.byType(DemoModeBanner),
    findsNothing,
    reason: 'refusing to capture "$name": the demo banner is showing',
  );
  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
    reason: 'refusing to capture "$name": something is still loading',
  );

  final bytes = await binding.takeScreenshot(name);
  await File('${outDir.path}/$name.png').writeAsBytes(bytes);
}
