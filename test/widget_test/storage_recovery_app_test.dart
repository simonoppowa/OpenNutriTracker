import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/storage_recovery_app.dart';

void main() {
  testWidgets('preserves the error code and retries bootstrap safely', (
    tester,
  ) async {
    final retryCompleter = Completer<void>();
    var retryCount = 0;

    await tester.pumpWidget(
      StorageRecoveryApp(
        errorCode: 'hive_wrong_key_or_corrupted',
        onRetry: () {
          retryCount++;
          return retryCompleter.future;
        },
      ),
    );

    expect(
      find.text('Your local data could not be opened safely'),
      findsOneWidget,
    );
    expect(
      find.text('Error code: hive_wrong_key_or_corrupted'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retryCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    retryCompleter.complete();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
