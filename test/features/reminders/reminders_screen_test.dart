import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/reminders/data/reminder_scheduler.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/presentation/reminders_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _Store implements ReminderStore {
  List<Reminder> reminders;
  _Store(this.reminders);

  @override
  Future<List<Reminder>> load() async => reminders;

  @override
  Future<void> save(List<Reminder> reminders) async =>
      this.reminders = reminders;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Scheduler implements ReminderScheduler {
  var syncs = 0;

  @override
  Future<void> sync(S s) async => syncs++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _breakfast = Reminder(
  id: 'b',
  type: ReminderType.breakfast,
  hour: 7,
  minute: 30,
  weekdays: Reminder.everyDay,
  enabled: true,
);

void main() {
  late _Store store;
  late _Scheduler scheduler;
  late bool permission;

  Future<void> pump(WidgetTester tester, List<Reminder> reminders) async {
    store = _Store(reminders);
    scheduler = _Scheduler();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: RemindersScreen(
          store: store,
          scheduler: scheduler,
          requestPermission: () async => permission,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => permission = true);

  testWidgets('without reminders it invites to add one', (tester) async {
    await pump(tester, const []);

    expect(find.text(l10nEn.remindersEmpty), findsOneWidget);
  });

  testWidgets('lists a reminder with its time and days', (tester) async {
    await pump(tester, const [_breakfast]);

    expect(find.text(l10nEn.reminderBreakfastTitle), findsOneWidget);
    expect(find.textContaining('07:30'), findsOneWidget);
    expect(find.textContaining(l10nEn.reminderEveryDay), findsOneWidget);
  });

  testWidgets('adding a water reminder on two days saves and schedules', (
    tester,
  ) async {
    await pump(tester, const []);

    await tester.tap(find.bySemanticsIdentifier('reminders-add'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('reminder-type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.reminderWaterTitle).last);
    await tester.pumpAndSettle();
    for (final day in [2, 3, 4, 6, 7]) {
      await tester.tap(find.bySemanticsIdentifier('reminder-weekday-$day'));
      await tester.pump();
    }
    await tester.tap(find.bySemanticsIdentifier('reminder-dialog-save'));
    await tester.pumpAndSettle();

    final saved = store.reminders.single;
    expect(saved.type, ReminderType.water);
    expect(saved.weekdays, {1, 5});
    expect(saved.enabled, isTrue);
    expect(scheduler.syncs, 1);
  });

  testWidgets('switching a reminder off saves and reschedules', (tester) async {
    await pump(tester, const [_breakfast]);

    await tester.tap(find.bySemanticsIdentifier('reminder-switch-b'));
    await tester.pumpAndSettle();

    expect(store.reminders.single.enabled, isFalse);
    expect(scheduler.syncs, 1);
  });

  testWidgets('deleting removes it', (tester) async {
    await pump(tester, const [_breakfast]);

    await tester.tap(find.text(l10nEn.reminderBreakfastTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('reminder-dialog-delete'));
    await tester.pumpAndSettle();

    expect(store.reminders, isEmpty);
    expect(scheduler.syncs, 1);
  });

  testWidgets('a denied permission keeps the reminder off and says so', (
    tester,
  ) async {
    permission = false;
    await pump(tester, [_breakfast.copyWith(enabled: false)]);

    await tester.tap(find.bySemanticsIdentifier('reminder-switch-b'));
    await tester.pumpAndSettle();

    expect(store.reminders.single.enabled, isFalse);
    expect(
      find.text(l10nEn.notificationsPermissionDeniedSnack),
      findsOneWidget,
    );
  });

  testWidgets('too many reminders say only part is scheduled', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 9; i++)
        Reminder(
          id: 'r$i',
          type: ReminderType.water,
          hour: 8 + i,
          minute: 0,
          weekdays: Reminder.everyDay,
          enabled: true,
        ),
    ]);

    expect(find.text(l10nEn.remindersOverBudget(60)), findsOneWidget);
  });
}
