import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/widgets/backup_reminder_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/fake_backup_reminder.dart';

void main() {
  final now = DateTime(2026, 10, 20, 9);

  Future<void> pumpCard(
    WidgetTester tester,
    FakeBackupReminder reminder,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: BackupReminderCard(reminder: reminder, clock: () => now),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card() => find.bySemanticsIdentifier('home-backup-reminder');

  testWidgets('says there is no backup yet', (tester) async {
    await pumpCard(tester, FakeBackupReminder());

    expect(card(), findsOneWidget);
    expect(find.text('Time for a backup'), findsOneWidget);
    expect(find.textContaining('There is no backup yet'), findsOneWidget);
  });

  testWidgets('names the age of an old backup', (tester) async {
    await pumpCard(
      tester,
      FakeBackupReminder(lastBackupAt: now.subtract(const Duration(days: 9))),
    );

    expect(find.text('Your last backup is 9 days old.'), findsOneWidget);
  });

  testWidgets('stays hidden while a backup is recent', (tester) async {
    await pumpCard(
      tester,
      FakeBackupReminder(
        lastBackupAt: now.subtract(const Duration(days: 1)),
        due: false,
      ),
    );

    expect(card(), findsNothing);
  });

  testWidgets('disappears once a backup is saved elsewhere', (tester) async {
    final reminder = FakeBackupReminder();
    await pumpCard(tester, reminder);
    expect(card(), findsOneWidget);

    reminder
      ..due = false
      ..lastBackupAt = now;
    reminder.notifier.value++;
    await tester.pumpAndSettle();

    expect(card(), findsNothing);
  });

  testWidgets('can be dismissed for the session', (tester) async {
    await pumpCard(tester, FakeBackupReminder());

    await tester.tap(
      find.bySemanticsIdentifier('home-backup-reminder-dismiss'),
    );
    await tester.pump();

    expect(card(), findsNothing);
  });
}
