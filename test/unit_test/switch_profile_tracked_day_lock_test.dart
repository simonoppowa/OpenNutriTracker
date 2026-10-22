import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/switch_profile_usecase.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// #1317 review: a profile switch waits for a tracked-day writer.
///
/// Data sources resolve their box through the provider on every call, so a
/// writer paused between storing an entry and adding it to its row would
/// add the outgoing profile's entry to the incoming profile's row if the
/// swap landed in between.
class _RecordingDBProvider extends FakeHiveDBProvider {
  final List<String> log;

  _RecordingDBProvider(
    this.log, {
    required super.configBox,
    required super.intakeBox,
    required super.userActivityBox,
    required super.trackedDayBox,
    required super.customMealBox,
    required super.cachedOffMealBox,
    required super.recipeBox,
  });

  @override
  Future<void> switchProfile(String profileId, String boxSuffix) async {
    log.add('box swap');
  }
}

class _FakeSecureStorage extends Fake implements SecureAppStorageProvider {
  @override
  Future<void> setActiveProfileId(String profileId) async {}
}

void main() {
  setUpAll(registerHiveAdaptersOnce);

  test('the box swap waits for a writer holding the tracked-day lock', () async {
    Future<Box<T>> open<T>(String name) =>
        Hive.openBox<T>('switch_lock_$name', bytes: Uint8List(0));
    final log = <String>[];
    final db = _RecordingDBProvider(
      log,
      configBox: await open<ConfigDBO>('config'),
      intakeBox: await open<IntakeDBO>('intake'),
      userActivityBox: await open<UserActivityDBO>('activity'),
      trackedDayBox: await open<TrackedDayDBO>('day'),
      customMealBox: await open<MealDBO>('custom'),
      cachedOffMealBox: await open<MealDBO>('cached'),
      recipeBox: await open<RecipeDBO>('recipe'),
    );
    final configDataSource = ConfigDataSource(db);
    await configDataSource.initializeConfig();
    final usecase = SwitchProfileUsecase(
      db,
      _FakeSecureStorage(),
      configDataSource,
    );

    // A writer has stored its entry and is about to add it to the row.
    final resume = Completer<void>();
    final writer = withTrackedDayLock(() async {
      log.add('entry stored');
      await resume.future;
      log.add('row updated');
    });
    await pumpEventQueue();

    final switched = usecase.switchProfile(
      ProfileEntity(
        id: 'other',
        name: 'Other',
        createdAt: DateTime(2026, 1, 1),
        boxSuffix: '_other',
      ),
    );
    await pumpEventQueue();
    expect(log, ['entry stored'], reason: 'the swap must not land mid-write');

    resume.complete();
    await writer;
    await switched;
    expect(log, ['entry stored', 'row updated', 'box swap']);
  });

  test('a UI write queued behind a profile switch is abandoned', () async {
    final startedOn = ProfileStamp.now();
    final switching = Completer<void>();
    final releaseSwitch = Completer<void>();
    final switchFuture = withProfileSwitchLock(() async {
      switching.complete();
      await releaseSwitch.future;
    });
    await switching.future;

    var wrote = false;
    final write = withTrackedDayLockOnProfile(() async {
      wrote = true;
    }, startedOn: startedOn);
    await pumpEventQueue();
    expect(wrote, isFalse);

    releaseSwitch.complete();
    await switchFuture;
    expect(await write, isNull);
    expect(wrote, isFalse);
  });
}
