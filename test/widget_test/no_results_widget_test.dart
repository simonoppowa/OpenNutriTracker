import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
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
  group('NoResultsWidget', () {
    testWidgets('renders bare empty hint when no action callbacks are given', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const NoResultsWidget()));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Scan barcode'), findsNothing);
      expect(find.text('Create custom food'), findsNothing);
    });

    testWidgets('shows both action buttons when both callbacks are provided', (
      tester,
    ) async {
      var scanTaps = 0;
      var createTaps = 0;

      await tester.pumpWidget(
        _wrap(
          NoResultsWidget(
            onScanBarcode: () => scanTaps++,
            onCreateCustomFood: () => createTaps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan barcode'), findsOneWidget);
      expect(find.text('Create custom food'), findsOneWidget);

      await tester.tap(find.text('Scan barcode'));
      await tester.tap(find.text('Create custom food'));
      await tester.pump();

      expect(scanTaps, 1);
      expect(createTaps, 1);
    });

    testWidgets('shows only the scan button when the create callback is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(NoResultsWidget(onScanBarcode: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Scan barcode'), findsOneWidget);
      expect(find.text('Create custom food'), findsNothing);
    });
  });
}
