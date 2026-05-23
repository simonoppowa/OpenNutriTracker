import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

// #277: the Show Activity Tracking toggle in Settings has been wired to
// hide every activity-related surface in the app. AddItemBottomSheet is
// the FAB's add-something menu — when the toggle is off, the Activity
// row at the top should disappear so the meal options are all that's on
// offer. Locking the behaviour in here so a future refactor that drops
// the conditional or its default trips the test instead of slipping past
// review.

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'shows the Activity tile when showActivityTracking is true',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          showActivityTracking: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(S.current.activityLabel), findsOneWidget);
      expect(find.text(S.current.breakfastLabel), findsOneWidget);
    },
  );

  testWidgets(
    'hides the Activity tile when showActivityTracking is false',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(
          day: DateTime(2026, 1, 1),
          showActivityTracking: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(S.current.activityLabel), findsNothing);
      // Meal tiles still render so the sheet stays useful for food logging.
      expect(find.text(S.current.breakfastLabel), findsOneWidget);
      expect(find.text(S.current.lunchLabel), findsOneWidget);
      expect(find.text(S.current.dinnerLabel), findsOneWidget);
      expect(find.text(S.current.snackLabel), findsOneWidget);
    },
  );

  testWidgets(
    'defaults to showing the Activity tile when the flag is omitted',
    (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(
        AddItemBottomSheet(day: DateTime(2026, 1, 1)),
      ));
      await tester.pumpAndSettle();

      expect(find.text(S.current.activityLabel), findsOneWidget);
    },
  );
}
