import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
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
  testWidgets('Retry carries the identifier the caller gives it', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _wrap(
        ErrorDialog(
          errorText: 'Something failed',
          onRefreshPressed: () => retries++,
          retryIdentifier: 'search-all-retry',
        ),
      ),
    );

    final retry = find.bySemanticsIdentifier('search-all-retry');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    expect(retries, 1);
  });
}
