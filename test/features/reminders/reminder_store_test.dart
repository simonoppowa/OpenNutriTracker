import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';

import '../../helpers/fake_hive_db_provider.dart';
import '../../helpers/hive_test_setup.dart';

void main() {
  late Box<ConfigDBO> appBox;
  late Box<ConfigDBO> profileBox;
  late ConfigDataSource config;
  late ReminderStore store;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    appBox = await Hive.openBox<ConfigDBO>('reminder_store_app');
    profileBox = await Hive.openBox<ConfigDBO>('reminder_store_profile');
    config = ConfigDataSource(
      FakeHiveDBProvider(appConfigBox: appBox, configBox: profileBox),
    );
    await config.initializeConfig();
    store = ReminderStore(config);
  });

  tearDown(() => Hive.deleteFromDisk());

  test('a new install has no reminders', () async {
    expect(await store.load(), isEmpty);
  });

  test('the daily reminder of earlier versions is taken over', () async {
    await config.setNotificationsEnabled(true);
    await config.setNotificationTime(19, 45);

    final reminders = await store.load();

    expect(reminders, hasLength(1));
    expect(reminders.single.type, ReminderType.logMeals);
    expect(reminders.single.hour, 19);
    expect(reminders.single.minute, 45);
    expect(reminders.single.weekdays, Reminder.everyDay);
    expect(reminders.single.enabled, isTrue);
  });

  test('a switched off daily reminder is not taken over', () async {
    await config.setNotificationsEnabled(false);

    expect(await store.load(), isEmpty);
  });

  test('saved reminders are read back and win over the old setting', () async {
    await config.setNotificationsEnabled(true);
    final water = Reminder(
      id: 'w',
      type: ReminderType.water,
      hour: 10,
      minute: 0,
      weekdays: const {1, 2, 3, 4, 5},
      enabled: true,
    );

    await store.save([water]);

    expect(await store.load(), [water]);
  });

  test('an emptied list stays empty', () async {
    await config.setNotificationsEnabled(true);
    await store.save(const []);

    expect(await store.load(), isEmpty);
  });

  test('saving notifies the listeners', () async {
    var changes = 0;
    store.changes.addListener(() => changes++);

    await store.save(const []);

    expect(changes, 1);
  });

  test('a broken stored list reads as empty instead of failing', () async {
    await config.setRemindersJson('{not json');

    expect(await store.load(), isEmpty);
  });

  test('the onboarding reminder joins the existing ones', () async {
    const water = Reminder(
      id: 'w',
      type: ReminderType.water,
      hour: 10,
      minute: 0,
      weekdays: Reminder.everyDay,
      enabled: true,
    );
    await store.save(const [water]);

    await store.addDailyReminder();
    await store.addDailyReminder();

    final reminders = await store.load();
    expect(reminders.first, water);
    expect(
      reminders.where((r) => r.type == ReminderType.logMeals),
      hasLength(1),
    );
    expect(reminders.last.hour, 8);
    expect(reminders.last.enabled, isTrue);
  });

  test('the onboarding reminder switches a stored one back on', () async {
    await store.save([
      (await (() async {
        await store.addDailyReminder();
        return (await store.load()).single;
      })()).copyWith(enabled: false, hour: 20),
    ]);

    await store.addDailyReminder();

    final daily = (await store.load()).single;
    expect(daily.enabled, isTrue);
    expect(daily.hour, 20);
  });
}
