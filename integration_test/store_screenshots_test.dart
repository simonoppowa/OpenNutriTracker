import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opennutritracker/core/styles/accent_colors.dart';
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
/// no benefit. Only `--dart-define=STORE_SCREENSHOTS=true` enables it, and
/// nothing in CI passes that — the dispatch-only iOS lane that did so was
/// removed in #1076 — so everywhere else this test is skipped at compile
/// time.
///
/// ## Why it is kept, and what it cannot do
///
/// It is kept for what it encodes — the shot order, the finders, the demo
/// fixture, and the assertions that refuse a loading or banner-covered frame
/// — not as a working capture route. It cannot currently give you the files:
/// `takeScreenshot` writes into the app's Documents directory and
/// `flutter test` uninstalls the app on exit, taking the container with it.
/// That is the defect that defeated the lane, and it is a property of this
/// test rather than of CI, so a hand-run hits it too. Exporting means a
/// `flutter drive` + `onScreenshot` conversion, which writes host-side.
///
/// The shipped captures come from `xcrun simctl io booted screenshot`
/// instead; see `fastlane/metadata/ios/en-US/screenshots/README.md`.
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

/// The packed ARGB the app actually expects. `runAppWithChangeNotifiers`
/// hands this straight to `Color(accentColor)` in `lib/main.dart`, so passing
/// the *index* yields `Color(0x00000007)` — transparent near-black, not the
/// brand green, and every screenshot would have shipped with a broken accent.
/// Read from the app's own list so the constant and the palette cannot drift.
final int _brandAccentArgb =
    accentPresetColors[_brandAccentIndex].toARGB32();

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
      // Disposed at the end of the body, not via addTearDown. The first real
      // run (#1076) failed with "A SemanticsHandle was active at the end of
      // the test": `_endOfTestVerifications` runs inside `_runTestBody`,
      // *before* addTearDown callbacks fire, so registering the dispose there
      // is always too late. The test body had completed and all six captures
      // had been taken — the non-zero exit then aborted the step before the
      // simulator's container was copied out, so a clean run produced nothing.
      final semantics = tester.ensureSemantics();

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

      // THE SECOND TRAP, and the first real run is what found it (#1076).
      //
      // A fresh profile has `hasAcceptedDisclaimer` false, so
      // `home_bloc.dart:88` raises the disclaimer dialog over HomePage on the
      // very first frame. A modal barrier makes everything behind it
      // untouchable, so the capture guard refused the first shot with "Found
      // 0 widgets with type HomePage (considering only hit-testable widgets)"
      // — which is the guard working, not failing.
      //
      // Accepted here rather than tapped away: a tap is one more
      // timing-dependent step on a dialog whose button text is localised, and
      // the dialog is not part of what a store screenshot is meant to show.
      // The Play re-shoot (#1075) hit exactly this and dismissed it by hand.
      await locator<AddConfigUsecase>().setConfigDisclaimer(true);

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
        _brandAccentArgb,
      );
      // "Give boot up to 30 seconds, then settle" belongs in pumpAndSettle's
      // *third* argument. The first is the interval between pumps, and under
      // the live binding that interval is real elapsed time — so passing 30s
      // there spends at least 30 real seconds per settle iteration rather
      // than allowing 30 in total. `app_boot_test.dart:49` has the same
      // shape and the same cost; this file does not copy it, and that file is
      // worth revisiting separately.
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );

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
      //
      // Scoped to DiaryPage, not `find.byType(IntakeVerticalList).first`.
      // `HomePage` uses the same widget and is `_bodyPages[0]` in
      // `MainScreen`'s IndexedStack, which keeps every tab mounted — so the
      // global `.first` resolves to Home's copy, offstage behind the diary,
      // and the scroll would hunt the diary forever for a widget that is not
      // in it.
      final diaryMeals = find
          .descendant(
            of: find.byType(DiaryPage),
            matching: find.byType(IntakeVerticalList),
          )
          .first;
      await _scrollDiaryTo(tester, diaryMeals);
      await _shoot(tester, binding, outDir, '02-diary-meals', diaryMeals);

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

      // Last statement on purpose. If anything above throws, the body's own
      // failure is the one reported and this check never runs — which is what
      // happened on the first dispatch, where the disclaimer failure appeared
      // alone rather than behind a semantics complaint.
      semantics.dispose();
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
  final scrollable = find
      .descendant(
        of: find.byType(DiaryPage),
        matching: find.byType(Scrollable),
      )
      .first;

  // Back to the top before searching. `scrollUntilVisible` only ever scrolls
  // in the direction of its delta, so a positive one cannot find a target
  // that is now *above* the viewport — and that is the normal case here:
  // `DailyNutrientPanel` sits before the `IntakeVerticalList`s in
  // `day_info_widget.dart`, so capturing the meals first leaves the panel
  // behind us, and the next call would exhaust maxScrolls and throw.
  // Resetting makes each call independent of whatever the last one left
  // behind, rather than requiring the shot order to match the widget order.
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: scrollable,
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

  // hitTestable(), not the bare finder: `MainScreen` keeps every tab alive in
  // an IndexedStack, so an inactive tab's widgets are still in the tree and a
  // plain `findsWidgets` would pass for a screen that is not on screen —
  // defeating the whole point of this guard.
  expect(
    mustBeVisible.hitTestable(),
    findsWidgets,
    reason: 'refusing to capture "$name": its subject is not on screen',
  );
  expect(
    find.byType(DemoModeBanner),
    findsNothing,
    reason: 'refusing to capture "$name": the demo banner is showing',
  );
  // Also hitTestable: a spinner on an inactive tab is not in the shot, and
  // failing the run for it would be a false alarm.
  expect(
    find.byType(CircularProgressIndicator).hitTestable(),
    findsNothing,
    reason: 'refusing to capture "$name": something is still loading',
  );

  final bytes = await binding.takeScreenshot(name);
  await File('${outDir.path}/$name.png').writeAsBytes(bytes);
}
