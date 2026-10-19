import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/backup_status_row.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_backup_reminder.dart';

void main() {
  Future<void> pumpRow(WidgetTester tester, FakeBackupReminder reminder) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: BackupStatusRow(reminder: reminder)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows that there is no backup yet', (tester) async {
    await pumpRow(tester, FakeBackupReminder());

    expect(find.text('No backup yet'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
  });

  testWidgets('shows when the last backup was saved', (tester) async {
    await pumpRow(
      tester,
      FakeBackupReminder(lastBackupAt: DateTime(2026, 10, 18, 21, 5)),
    );

    expect(find.textContaining('Last backup: 10/18/2026'), findsOneWidget);
  });

  testWidgets('stores a new reminder period', (tester) async {
    final reminder = FakeBackupReminder();
    await pumpRow(tester, reminder);

    await tester.tap(find.bySemanticsIdentifier('export-import-reminder-days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14 days').last);
    await tester.pumpAndSettle();

    expect(reminder.setDays, [14]);
    expect(find.text('14 days'), findsOneWidget);
  });
}
