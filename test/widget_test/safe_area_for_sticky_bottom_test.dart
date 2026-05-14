// Regression guard for issue #156 — "Add" button at the bottom is behind
// phone navigation bar.
//
// The fix for #156 wrapped four files in SafeArea so that persistent bottom
// UI (a Scaffold.bottomSheet, a BottomAppBar, a sticky Padding-wrapped
// button, or a list that runs all the way to the bottom edge of the body)
// doesn't render under the Android gesture-navigation strip on devices that
// don't reserve insets.
//
// This test reads each file in the curated list below and asserts that the
// file contains a `SafeArea` in its source. It is deliberately a source-
// level check rather than a widget-pump: these screens depend on the GetIt
// service locator, BLoCs, route arguments, and (for some) network or
// Supabase access, and standing up that surface inside a unit test costs
// more than the rule is worth. A source-level check is honest about what it
// actually verifies — the lexical pattern that the SafeArea fix landed in
// the right files, and that the next contributor who adds a sticky-bottom
// screen to this list can't quietly forget the wrap.
//
// The list is hand-maintained on purpose. If you add a new screen with a
// persistent bottom button or a body that reaches the bottom edge, add it
// here. A fully-automatic walk of `lib/features/` would flag screens that
// don't actually have sticky bottom UI, and a flaky guard is worse than no
// guard.
//
// Screens introduced by other in-flight branches that will need to be added
// to this list once they merge into develop:
//   - lib/features/profile/presentation/weight_history_screen.dart (#38)
//   - lib/features/settings/presentation/widgets/paste_json_meals_sheet.dart (#181)
//   - lib/features/recipes/presentation/screens/recipe_builder_screen.dart
//     image picker UI (#64)
//
// Those files are not on the branch this test was written against, so they
// aren't included here. Update the list (and remove this note) when the
// branches land.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that must contain a `SafeArea` because they introduce persistent
/// bottom UI or a body region that reaches the bottom edge of the screen.
/// Paths are relative to the package root (where `flutter test` runs).
///
/// All five entries here were touched by the #156 fix and are the load-
/// bearing rule the test exists to enforce.
const _screensWithStickyBottomUi = <String>[
  // Search screen — the list of MealItemCard rows (each row has its own
  // "Add" button) runs to the bottom edge. SafeArea(top: false) wraps the
  // body so the last row stays above the gesture-nav strip.
  'lib/features/add_meal/presentation/add_meal_screen.dart',

  // Scaffolds with a `bottomSheet:` — the bottom sheet sticks to the very
  // bottom of the screen with no scroll padding.
  'lib/features/activity_detail/activity_detail_screen.dart',
  'lib/features/meal_detail/meal_detail_screen.dart',

  // The bottom-sheet widgets themselves — these are the widgets actually
  // hosting the "Add" button. They wrap their content in
  // `SafeArea(top: false)` so the button clears the gesture-nav strip.
  'lib/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart',
  'lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart',
];

void main() {
  group('SafeArea guard for screens with persistent bottom UI (#156)', () {
    for (final relativePath in _screensWithStickyBottomUi) {
      test('$relativePath contains a SafeArea wrap', () {
        final file = File(relativePath);
        expect(
          file.existsSync(),
          isTrue,
          reason:
              '$relativePath is listed as a screen with persistent bottom '
              'UI but the file does not exist. If the screen was renamed or '
              'removed, update _screensWithStickyBottomUi in this test.',
        );

        final source = file.readAsStringSync();

        expect(
          source.contains('SafeArea'),
          isTrue,
          reason:
              '$relativePath has persistent bottom UI but is missing a '
              'SafeArea wrap. Bottom buttons will sit under the Android '
              'gesture-navigation strip on devices that do not reserve '
              'insets — see issue #156. Wrap the bottom region (or the '
              'whole Scaffold body) in SafeArea(bottom: true).',
        );
      });
    }

    test('every tracked path is unique', () {
      final unique = _screensWithStickyBottomUi.toSet();
      expect(
        unique.length,
        _screensWithStickyBottomUi.length,
        reason: 'Duplicate entries in _screensWithStickyBottomUi',
      );
    });
  });
}
