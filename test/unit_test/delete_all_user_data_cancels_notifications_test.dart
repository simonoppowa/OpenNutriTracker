import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/delete_all_user_data_usecase.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Stands in for the OS. Records whether the user's data was still on file
/// when it was told to drop the alarm — which, rather than call order for its
/// own sake, is the property #764 turns on.
///
/// It watches the *user* box rather than the config box on purpose. Config is
/// written through a read-modify-write, so a cancel step that runs after the
/// wipe puts a config row straight back into the box it was just cleared
/// from; a probe pointed at config would read that rewrite as "still on file"
/// and pass in exactly the arrangement it exists to reject. Nothing
/// repopulates the user box.
class _RecordingNotificationService extends NotificationService {
  _RecordingNotificationService(this._userBox, {this.throws = false});

  final Box<UserDBO> _userBox;
  final bool throws;

  int cancels = 0;
  bool? userDataStillOnFileWhenCancelled;

  @override
  Future<void> cancelAllScheduled() async {
    cancels++;
    userDataStillOnFileWhenCancelled = _userBox.isNotEmpty;
    if (throws) throw StateError('notification plugin unavailable');
  }
}

void main() {
  group('delete-all and the alarm the OS is holding', () {
    late Box<ConfigDBO> appConfigBox;
    late Box<ConfigDBO> configBox;
    late Box<UserDBO> userBox;
    late FakeHiveDBProvider provider;
    late ConfigRepository configRepository;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();

      appConfigBox = await Hive.openBox<ConfigDBO>('delete_all_app_config');
      configBox = await Hive.openBox<ConfigDBO>('delete_all_config');
      provider = FakeHiveDBProvider(
        appConfigBox: appConfigBox,
        configBox: configBox,
        intakeBox: await Hive.openBox<IntakeDBO>('delete_all_intake'),
        userActivityBox: await Hive.openBox<UserActivityDBO>('delete_all_act'),
        userBox: userBox = await Hive.openBox<UserDBO>('delete_all_user'),
        trackedDayBox: await Hive.openBox<TrackedDayDBO>('delete_all_days'),
        weightLogBox: await Hive.openBox<WeightLogDBO>('delete_all_weight'),
        waterIntakeBox: await Hive.openBox<WaterIntakeDBO>('delete_all_water'),
        fastingBox: await Hive.openBox<FastingSessionDBO>('delete_all_fast'),
      );
      final configDataSource = ConfigDataSource(provider);
      configRepository = ConfigRepository(configDataSource);

      // The state #764 was reported from: the 08:00 reminder switched on,
      // alongside the device-wide preferences a wipe is meant to leave alone.
      await configDataSource.addConfig(
        ConfigDBO(
          true,
          true,
          false,
          AppThemeDBO.dark,
          usesImperialUnits: true,
          notificationsEnabled: true,
          notificationHour: 8,
          notificationMinute: 0,
        ),
      );
      // The probe above reads this box, so it has to hold something: an empty
      // box is indistinguishable from a wiped one, and the ordering assertion
      // would pass for the wrong reason.
      await userBox.put(
        'user',
        UserDBO(
          birthday: DateTime(1990, 6, 15),
          heightCM: 165,
          weightKG: 70,
          gender: UserGenderDBO.female,
          goal: UserWeightGoalDBO.loseWeight,
          pal: UserPALDBO.sedentary,
        ),
      );
    });

    tearDown(() async => Hive.deleteFromDisk());

    DeleteAllUserDataUsecase subject(NotificationService notifications) =>
        DeleteAllUserDataUsecase(provider, notifications, configRepository);

    test('the alarm the OS holds is cancelled, not merely forgotten', () async {
      final notifications = _RecordingNotificationService(userBox);

      await subject(notifications).deleteAll();

      expect(
        notifications.cancels,
        1,
        reason: 'nothing told the OS to drop the alarm, so it still fires at '
            '08:00 for a profile that no longer exists',
      );
      expect(configBox.isEmpty, isTrue, reason: 'the wipe must still happen');
    });

    test('cancelled before the data it belongs to is wiped', () async {
      final notifications = _RecordingNotificationService(userBox);

      await subject(notifications).deleteAll();

      // Order is half the defect. Cancel after the clear and the cancel runs
      // with nothing left to say an alarm was ever set.
      expect(
        notifications.userDataStillOnFileWhenCancelled,
        isTrue,
        reason: 'the alarm was cancelled after the data it belonged to was '
            'already gone',
      );
    });

    test('the next launch cannot schedule it again', () async {
      await subject(_RecordingNotificationService(userBox)).deleteAll();

      // The other half, and the easier one to miss. `notificationsEnabled` is
      // a *shared* preference living in the app box, which this wipe
      // deliberately leaves alone — so cancelling without switching it off
      // holds only until the user next quits the app, and `main.dart` puts
      // the reminder straight back on the following cold start.
      final afterWipe = await configRepository.getConfig();
      expect(
        afterWipe.notificationsEnabled,
        isFalse,
        reason: 'a cold start would read this and reschedule the reminder the '
            'user just deleted everything to be rid of',
      );
    });

    test('the device-wide preferences a wipe keeps are untouched', () async {
      await subject(_RecordingNotificationService(userBox)).deleteAll();

      // The counterweight to the test above: switching the reminder off must
      // not turn into wiping the shared app box, which is where theme,
      // language and units live for every profile on the device.
      final afterWipe = await configRepository.getConfig();
      expect(afterWipe.usesImperialUnits, isTrue);
      expect(afterWipe.appTheme.name, 'dark');
    });

    test('a notification failure does not block the wipe', () async {
      final notifications = _RecordingNotificationService(
        userBox,
        throws: true,
      );

      await subject(notifications).deleteAll();

      // The user asked for their data to be gone. Keeping it because a plugin
      // was unavailable is the worse of the two failures: a surviving alarm
      // can still be uninstalled, data kept against an explicit request
      // cannot be un-kept.
      expect(
        configBox.isEmpty,
        isTrue,
        reason: 'the data survived because cancelling an alarm failed',
      );
    });
  });
}
