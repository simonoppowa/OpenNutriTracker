import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/partial_results_notice.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('PartialResultsNotice', () {
    testWidgets('shows the notice text and a retry action', (tester) async {
      await tester.pumpWidget(_wrap(PartialResultsNotice(onRetry: () {})));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "One food source didn't respond. Some results might be missing.",
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('fires onRetry when the retry action is tapped', (
      tester,
    ) async {
      var retries = 0;

      await tester.pumpWidget(
        _wrap(PartialResultsNotice(onRetry: () => retries++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retries, 1);
    });
  });
}
