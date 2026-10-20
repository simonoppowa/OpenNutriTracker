import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/health/noop_health_service.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_weights_usecase.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

import '../fixture/user_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Stands in for the platform health store, which cannot run under
/// `flutter test`.
class _FakeHealthService extends Fake implements HealthService {
  List<ExternalWeight> weights = const [];
  bool throwOnRead = false;
  Completer<void>? readGate;

  int readWeightsCalls = 0;
  DateTime? lastFrom;

  @override
  Future<List<ExternalWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async {
    readWeightsCalls++;
    lastFrom = from;
    final gate = readGate;
    if (gate != null) await gate.future;
    if (throwOnRead) throw StateError('Health Connect permission revoked');
    return weights;
  }
}

/// Moves the active profile away the moment the use case reads the user, the
/// last read before the current weight is written.
class _SwitchingUserRepository extends UserRepository {
  final FakeHiveDBProvider provider;

  _SwitchingUserRepository(super.userDataSource, this.provider);

  @override
  Future<UserEntity> getUserData() async {
    final user = await super.getUserData();
    provider.activeProfileId = 'profile-b';
    return user;
  }
}

/// Runs [onGetConfig] once, the first time the use case reads the config
/// inside its filing loop, to land a write between its reads.
class _HookedConfigRepository extends ConfigRepository {
  Future<void> Function()? onGetConfig;
  int _calls = 0;

  _HookedConfigRepository(super.configDataSource);

  @override
  Future<ConfigEntity> getConfig() async {
    final config = await super.getConfig();
    // The first read is the run's own snapshot; the second is the loop's.
    if (++_calls == 2) await onGetConfig?.call();
    return config;
  }
}

/// Saves a profile edit (a new height) while the use case runs its last
/// guard before saving the current weight.
class _EditingUserRepository extends UserRepository {
  int _hasUserDataCalls = 0;

  /// The edit; defaults to a new height.
  Future<void> Function(UserRepository users)? edit;

  _EditingUserRepository(super.userDataSource, {this.edit});

  @override
  Future<bool> hasUserData() async {
    final has = await super.hasUserData();
    if (++_hasUserDataCalls == 2) {
      final edit = this.edit;
      if (edit != null) {
        await edit(this);
      } else {
        final user = await super.getUserData();
        user.heightCM = 192;
        await super.updateUserData(user);
      }
    }
    return has;
  }
}

/// Runs [afterWrite] once each filed entry has been stored, to land a change
/// while the import's write is still being awaited.
class _HookedWeightLogRepository extends WeightLogRepository {
  Future<void> Function()? afterWrite;

  _HookedWeightLogRepository(super.weightLogDataSource);

  @override
  Future<void> addEntry(WeightLogEntity entry) async {
    await super.addEntry(entry);
    await afterWrite?.call();
  }
}

/// Holds the first [getUserData] call made after [pause] until [release]
/// completes, with the user it read before the pause — a stale copy if
/// another operation saves the user in that gap.
class _PausingUserRepository extends UserRepository {
  Completer<void>? _reached;
  Completer<void>? _release;

  _PausingUserRepository(super.userDataSource);

  /// Completes once the paused call is waiting.
  Future<void> pause(Completer<void> release) {
    _release = release;
    return (_reached = Completer<void>()).future;
  }

  @override
  Future<UserEntity> getUserData() async {
    final user = await super.getUserData();
    final release = _release;
    if (release != null) {
      _release = null;
      _reached!.complete();
      await release.future;
    }
    return user;
  }
}

/// Holds the first [getEntry] call made after [pause] until [release]
/// completes, then reads the row as it is by then.
class _PausingWeightLogRepository extends WeightLogRepository {
  Completer<void>? _reached;
  Completer<void>? _release;

  _PausingWeightLogRepository(super.weightLogDataSource);

  Future<void> pause(Completer<void> release) {
    _release = release;
    return (_reached = Completer<void>()).future;
  }

  @override
  Future<WeightLogEntity?> getEntry(DateTime date) async {
    final release = _release;
    if (release != null) {
      _release = null;
      _reached!.complete();
      await release.future;
    }
    return super.getEntry(date);
  }
}

/// Waits until [other] has finished, or long enough that it evidently
/// cannot while the paused operation holds the lock it waits for.
Future<void> _finishedOrBlocked(Future<Object?> other) => Future.any([
  other.then((_) {}),
  Future<void>.delayed(const Duration(milliseconds: 200)),
]);

ExternalWeight _reading(String id, DateTime at, double kg) => ExternalWeight(
  id: id,
  measuredAt: at,
  weightKg: kg,
  sourceAppName: 'Scale',
);

void main() {
  final now = DateTime(2026, 5, 23, 12, 0);
  final today = DateTime(2026, 5, 23);
  final yesterday = DateTime(2026, 5, 22);

  late Box<ConfigDBO> configBox;
  late Box<WeightLogDBO> weightLogBox;
  late Box<UserDBO> userBox;
  late Box<ProfileDBO> profileBox;

  late FakeHiveDBProvider provider;
  late ConfigDataSource configDataSource;
  late ConfigRepository configRepository;
  late WeightLogRepository weightLogRepository;
  late UserRepository userRepository;
  late _FakeHealthService healthService;
  late ImportWeightsUsecase usecase;
  late DeleteWeightLogUsecase deleteUsecase;

  Future<void> setProfileCreatedAt(DateTime createdAt) => profileBox.put(
    'profile-a',
    ProfileDBO(
      id: 'profile-a',
      name: '',
      createdAt: createdAt,
      boxSuffix: '',
    ),
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    configBox = await Hive.openBox<ConfigDBO>('weight_import_config_test');
    weightLogBox = await Hive.openBox<WeightLogDBO>('weight_import_log_test');
    userBox = await Hive.openBox<UserDBO>('weight_import_user_test');
    profileBox = await Hive.openBox<ProfileDBO>('weight_import_profile_test');
    await configBox.clear();
    await weightLogBox.clear();
    await userBox.clear();
    await profileBox.clear();
    // Created long before the readings, so the onboarding weight is older
    // than all of them unless a test says otherwise.
    await setProfileCreatedAt(DateTime(2026, 1, 1));

    provider = FakeHiveDBProvider(
      activeProfileId: 'profile-a',
      configBox: configBox,
      weightLogBox: weightLogBox,
      userBox: userBox,
      profileBox: profileBox,
    );
    configDataSource = ConfigDataSource(provider);
    await configDataSource.initializeConfig();
    configRepository = ConfigRepository(configDataSource);
    weightLogRepository = WeightLogRepository(WeightLogDataSource(provider));
    userRepository = UserRepository(UserDataSource(provider));
    await userRepository.updateUserData(
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
    );

    healthService = _FakeHealthService();
    usecase = ImportWeightsUsecase(
      HealthImportRepository(healthService),
      configRepository,
      weightLogRepository,
      userRepository,
      provider,
    );
    deleteUsecase = DeleteWeightLogUsecase(
      weightLogRepository,
      configRepository,
      userRepository,
    );

    ImportWeightsUsecase.clock = () => now;
    await configDataSource.setConfigHealthWeightImportEnabled(true);
  });

  tearDown(() async {
    ImportWeightsUsecase.clock = DateTime.now;
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  group('ImportWeightsUsecase filing', () {
    test(
      'two readings of one instant keep the same row whichever comes first',
      () async {
        final at = DateTime(2026, 5, 23, 7);
        final scale = _reading('scale-1', at, 80.2);
        final copy = _reading('sync-9', at, 80.25);
        healthService.weights = [scale, copy];
        expect(await usecase.importNow(), equals(1));

        healthService.weights = [copy, scale];
        ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));
        expect(await usecase.importNow(), equals(0));

        healthService.weights = [scale, copy];
        ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 2));
        expect(await usecase.importNow(), equals(0));
        final entry = await weightLogRepository.getEntry(today);
        expect(entry!.externalId, 'sync-9');
        expect(entry.weightKg, 80.25);
      },
    );

    test('files each day once, keeping its latest reading', () async {
      healthService.weights = [
        _reading('a', DateTime(2026, 5, 22, 7), 80.4),
        _reading('b', DateTime(2026, 5, 22, 21), 81.0),
        _reading('c', DateTime(2026, 5, 23, 7), 80.2),
      ];

      expect(await usecase.importNow(), equals(2));

      final yesterdayEntry = await weightLogRepository.getEntry(yesterday);
      expect(yesterdayEntry!.weightKg, equals(81.0));
      expect(yesterdayEntry.externalId, equals('b'));
      expect(yesterdayEntry.date, equals(yesterday));
      final todayEntry = await weightLogRepository.getEntry(today);
      expect(todayEntry!.weightKg, equals(80.2));
      expect(todayEntry.externalId, equals('c'));
    });

    test('never replaces a weight the user entered', () async {
      await weightLogRepository.addEntry(
        WeightLogEntity(date: today, weightKg: 79.0, note: 'after gym'),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];

      expect(await usecase.importNow(), equals(0));

      final entry = await weightLogRepository.getEntry(today);
      expect(entry!.weightKg, equals(79.0));
      expect(entry.isImported, isFalse);
    });

    test('a later reading replaces an earlier imported one', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();

      healthService.weights = [
        _reading('c', DateTime(2026, 5, 23, 7), 80.2),
        _reading('d', DateTime(2026, 5, 23, 11), 79.8),
      ];
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(1));
      final entry = await weightLogRepository.getEntry(today);
      expect(entry!.externalId, equals('d'));
      expect(entry.weightKg, equals(79.8));
    });

    test('a stored later reading is not replaced by an earlier one', () async {
      healthService.weights = [
        _reading('c', DateTime(2026, 5, 23, 7), 80.2),
        _reading('d', DateTime(2026, 5, 23, 11), 79.8),
      ];
      await usecase.importNow();

      // 'd' left the health store; the overlapping read returns 'c' alone.
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(0));
      expect((await weightLogRepository.getEntry(today))!.externalId, 'd');
      expect((await userRepository.getUserData()).weightKG, equals(79.8));
    });

    test('re-reading the same readings writes nothing', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(0));
    });

    test('a weight logged by hand during the run is not overwritten', () async {
      final hooked = _HookedConfigRepository(configDataSource);
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        hooked,
        weightLogRepository,
        userRepository,
        provider,
      );
      hooked.onGetConfig = () => weightLogRepository.addEntry(
        WeightLogEntity(date: today, weightKg: 79.0),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];

      expect(await usecase.importNow(), equals(0));

      final entry = await weightLogRepository.getEntry(today);
      expect(entry!.weightKg, equals(79.0));
      expect(entry.isImported, isFalse);
    });

    test('a record already filed on another day is not filed again', () async {
      // As after a time-zone change: the same instant now falls on today,
      // but an earlier run filed it under yesterday.
      await weightLogRepository.addEntry(
        WeightLogEntity(date: yesterday, weightKg: 80.2, externalId: 'c'),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];

      expect(await usecase.importNow(), equals(0));

      expect(await weightLogRepository.getEntry(today), isNull);
      expect(await weightLogRepository.getAllEntries(), hasLength(1));
    });

    test('a wipe during the platform read leaves nothing behind', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];
      healthService.readGate = Completer<void>();

      final run = usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      // What "Delete all my data" does to the profile's boxes; the profile
      // id stays the same.
      await Future.wait([
        configBox.clear(),
        weightLogBox.clear(),
        userBox.clear(),
      ]);
      healthService.readGate!.complete();

      expect(await run, equals(0));
      expect(weightLogBox.isEmpty, isTrue);
      expect(configBox.isEmpty, isTrue);
      expect(userBox.isEmpty, isTrue);
    });

    test('reads nothing while weight import is off', () async {
      await configDataSource.setConfigHealthWeightImportEnabled(false);
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];

      expect(await usecase.importNow(), equals(0));
      expect(healthService.readWeightsCalls, equals(0));
      expect(await weightLogRepository.getAllEntries(), isEmpty);
    });
  });

  group('ImportWeightsUsecase current weight', () {
    test('the newest reading becomes the current weight', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];

      await usecase.importNow();

      expect((await userRepository.getUserData()).weightKG, equals(78.5));
    });

    test('a retry finishes a run killed before the current weight', () async {
      // The earlier run filed today's reading and died before the update.
      await weightLogRepository.addEntry(
        WeightLogEntity(date: today, weightKg: 78.5, externalId: 'c'),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];

      expect(await usecase.importNow(), equals(0));

      expect((await userRepository.getUserData()).weightKG, equals(78.5));
    });

    test('a profile edit saved during the guards is kept', () async {
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        weightLogRepository,
        _EditingUserRepository(UserDataSource(provider)),
        provider,
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];

      await usecase.importNow();

      final user = await userRepository.getUserData();
      expect(user.weightKG, equals(78.5));
      expect(user.heightCM, equals(192));
    });

    test('a weight entered by hand during the guards stays current', () async {
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        weightLogRepository,
        _EditingUserRepository(
          UserDataSource(provider),
          // What AddWeightLogUsecase does for today: the row, then the user.
          edit: (users) async {
            await weightLogRepository.addEntry(
              WeightLogEntity(date: today, weightKg: 79.0),
            );
            final user = await users.getUserData();
            user.weightKG = 79.0;
            await users.updateUserData(user);
          },
        ),
        provider,
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];

      await usecase.importNow();

      expect((await userRepository.getUserData()).weightKG, equals(79.0));
      expect((await weightLogRepository.getEntry(today))!.isImported, isFalse);
    });

    test('a filed reading outside the read window still reconciles', () async {
      // Filed by a run that died before the update, and the app was not
      // opened again until long after the backfill window.
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: DateTime(2026, 4, 10),
          weightKg: 77.9,
          externalId: 'old',
          measuredAt: DateTime(2026, 4, 10, 7),
        ),
      );

      expect(await usecase.importNow(), equals(0));

      expect((await userRepository.getUserData()).weightKG, equals(77.9));
    });

    test('a reconciliation-only change still signals', () async {
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: today,
          weightKg: 78.5,
          externalId: 'c',
          measuredAt: DateTime(2026, 5, 23, 7),
        ),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];
      var events = 0;
      final subscription = usecase.weightsImported.listen((_) => events++);
      addTearDown(subscription.cancel);

      expect(await usecase.importNow(), equals(0));
      await Future<void>.delayed(Duration.zero);

      expect(events, equals(1));
    });

    test('imported entries are ordered by when they were taken', () async {
      // After a move west: 'old' kept the day it was filed on, and the
      // later reading landed on the now-earlier local date.
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: today,
          weightKg: 81.0,
          externalId: 'old',
          measuredAt: DateTime(2026, 5, 23, 7),
        ),
      );
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: yesterday,
          weightKg: 79.5,
          externalId: 'new',
          measuredAt: DateTime(2026, 5, 23, 12),
        ),
      );

      await usecase.importNow();

      expect((await userRepository.getUserData()).weightKG, equals(79.5));
    });

    test('turning import off during the last write still settles it', () async {
      final hookedLog = _HookedWeightLogRepository(
        WeightLogDataSource(provider),
      );
      hookedLog.afterWrite = () =>
          configDataSource.setConfigHealthWeightImportEnabled(false);
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        hookedLog,
        userRepository,
        provider,
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];
      var events = 0;
      final subscription = usecase.weightsImported.listen((_) => events++);
      addTearDown(subscription.cancel);

      expect(await usecase.importNow(), equals(1));
      await Future<void>.delayed(Duration.zero);

      expect((await weightLogRepository.getEntry(today))!.externalId, 'c');
      expect((await userRepository.getUserData()).weightKG, equals(78.5));
      expect(events, equals(1));
      // Turned off, so no watermark is recorded for the run.
      expect(
        (await configRepository.getConfig()).healthWeightLastImportAt,
        isNull,
      );
    });

    test(
      'a late-synced older reading leaves the current weight alone',
      () async {
        await weightLogRepository.addEntry(
          WeightLogEntity(date: today, weightKg: 79.0),
        );
        healthService.weights = [_reading('a', DateTime(2026, 5, 22, 7), 81.0)];

        expect(await usecase.importNow(), equals(1));

        expect((await userRepository.getUserData()).weightKG, equals(80.0));
      },
    );
  });

  group('ImportWeightsUsecase onboarding weight', () {
    // Onboarding stores the weight on the user alone; nothing reaches the
    // log, so these profiles have no manual entry to compare against.
    test('a reading older than the profile keeps the onboarding weight', () async {
      await setProfileCreatedAt(DateTime(2026, 5, 23, 9));
      healthService.weights = [
        _reading('a', DateTime(2026, 5, 3, 7), 84.0),
        _reading('b', DateTime(2026, 5, 23, 7), 83.0),
      ];

      expect(await usecase.importNow(), equals(2));

      expect((await userRepository.getUserData()).weightKG, equals(80.0));
    });

    test('a reading taken after the profile was created replaces it', () async {
      await setProfileCreatedAt(DateTime(2026, 5, 23, 9));
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 11), 79.4)];

      await usecase.importNow();

      expect((await userRepository.getUserData()).weightKG, equals(79.4));
    });
  });

  group('ImportWeightsUsecase deletion', () {
    test('a day deleted while the platform read runs stays deleted', () async {
      healthService.weights = [_reading('b', DateTime(2026, 5, 22, 7), 80.9)];
      await usecase.importNow();

      healthService.readGate = Completer<void>();
      final run = usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      await deleteUsecase.deleteEntry(yesterday);
      healthService.readGate!.complete();

      expect(await run, equals(0));
      expect(await weightLogRepository.getEntry(yesterday), isNull);
    });

    test('a deleted imported day stays deleted on the next read', () async {
      healthService.weights = [
        _reading('b', DateTime(2026, 5, 22, 7), 80.9),
        _reading('c', DateTime(2026, 5, 22, 21), 81.0),
      ];
      await usecase.importNow();

      await deleteUsecase.deleteEntry(yesterday);
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(0));
      expect(await weightLogRepository.getEntry(yesterday), isNull);
    });

    test(
      'an earlier reading from a deleted day stays out once the deleted one '
      'leaves the health store',
      () async {
        healthService.weights = [
          _reading('c', DateTime(2026, 5, 22, 7), 80.9),
          _reading('d', DateTime(2026, 5, 22, 11), 81.0),
        ];
        await usecase.importNow();
        await deleteUsecase.deleteEntry(yesterday);

        final afterDelete = await configRepository.getConfig();
        expect(
          afterDelete.isDeletedWeightReading(
            day: yesterday,
            measuredAt: DateTime(2026, 5, 22, 11),
          ),
          isTrue,
        );
        expect(
          afterDelete.isDeletedWeightReading(
            day: yesterday,
            measuredAt: DateTime(2026, 5, 22, 11, 1),
          ),
          isFalse,
        );

        // The user also removed 'd' from the health store.
        healthService.weights = [
          _reading('c', DateTime(2026, 5, 22, 7), 80.9),
        ];
        ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

        expect(await usecase.importNow(), equals(0));
        expect(await weightLogRepository.getEntry(yesterday), isNull);

        // A reading taken after the deleted one is still welcome.
        healthService.weights = [
          _reading('c', DateTime(2026, 5, 22, 7), 80.9),
          _reading('e', DateTime(2026, 5, 22, 20), 80.7),
        ];
        ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 2));

        expect(await usecase.importNow(), equals(1));
        expect((await weightLogRepository.getEntry(yesterday))!.externalId, 'e');
      },
    );

    test('a day cutoff is pruned like a tombstone', () async {
      await configDataSource.setConfigHealthLastImportAt(now);
      final longAgo = DateTime(2026, 4, 1);
      await configDataSource.addConfigHealthDeletedWorkout(
        ConfigEntity.deletedWeightDayKey(longAgo),
        DateTime(2026, 4, 1, 7),
      );

      await usecase.importNow();

      final config = await configRepository.getConfig();
      expect(
        config.isDeletedWeightReading(
          day: longAgo,
          measuredAt: DateTime(2026, 4, 1, 6),
        ),
        isFalse,
      );
      expect(config.healthDeletedWorkouts, isEmpty);
    });

    // A time zone cannot be changed under `flutter test`, so the deletion is
    // stored as one made in a zone three hours behind this one: there, the
    // deleted day 22 May ran from 03:00 on the 22nd to 03:00 on the 23rd of
    // this zone's clock, and its deleted reading at 23:00 is 02:00 on the
    // 23rd here.
    test('an earlier reading from a deleted day stays out after a time-zone '
        'change moves it onto another date', () async {
      await configDataSource.addConfigHealthDeletedWorkout(
        ConfigEntity.deletedWeightDayKey(
          yesterday,
          dayStart: DateTime(2026, 5, 22, 3),
        ),
        DateTime(2026, 5, 23, 2),
      );
      // 22:00 on the deleted day where it was deleted; 01:00 on the 23rd
      // here, a date with no cutoff of its own.
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 1), 80.9)];

      expect(await usecase.importNow(), equals(0));
      expect(await weightLogRepository.getEntry(today), isNull);

      // A reading taken after the deleted one is still welcome.
      healthService.weights = [
        _reading('c', DateTime(2026, 5, 23, 1), 80.9),
        _reading('d', DateTime(2026, 5, 23, 2, 30), 80.6),
      ];
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(1));
      expect((await weightLogRepository.getEntry(today))!.externalId, 'd');
    });

    test('a deleted day does not hold back the day before it', () async {
      await configDataSource.addConfigHealthDeletedWorkout(
        ConfigEntity.deletedWeightDayKey(yesterday),
        DateTime(2026, 5, 22, 7),
      );
      final config = await configRepository.getConfig();

      expect(
        config.isDeletedWeightReading(
          day: DateTime(2026, 5, 21),
          measuredAt: DateTime(2026, 5, 21, 23),
        ),
        isFalse,
      );
      expect(
        config.isDeletedWeightReading(
          day: yesterday,
          measuredAt: DateTime(2026, 5, 22, 6),
        ),
        isTrue,
      );
    });

    test('a newer reading on a deleted day is still filed', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      await deleteUsecase.deleteEntry(today);

      healthService.weights = [
        _reading('c', DateTime(2026, 5, 23, 7), 80.2),
        _reading('d', DateTime(2026, 5, 23, 11), 79.8),
      ];
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(1));
      expect((await weightLogRepository.getEntry(today))!.externalId, 'd');
    });

    test(
      'keeps workout tombstones the stale workout watermark still needs',
      () async {
        // Workout import last ran two months ago; a workout from 45 days ago
        // was deleted. Re-enabling it reads back from that old watermark, so
        // the tombstone must survive weight imports in the meantime.
        final deletedWorkoutStart = now.subtract(const Duration(days: 45));
        await configDataSource.setConfigHealthLastImportAt(
          now.subtract(const Duration(days: 60)),
        );
        await configDataSource.addConfigHealthDeletedWorkout(
          'workout-1',
          deletedWorkoutStart,
        );

        await usecase.importNow();

        expect(
          (await configRepository.getConfig()).healthDeletedWorkouts,
          containsPair('workout-1', deletedWorkoutStart),
        );
      },
    );

    test('still prunes tombstones no import can ask about', () async {
      await configDataSource.setConfigHealthLastImportAt(now);
      await configDataSource.addConfigHealthDeletedWorkout(
        'workout-1',
        now.subtract(const Duration(days: 45)),
      );

      await usecase.importNow();

      expect(
        (await configRepository.getConfig()).healthDeletedWorkouts,
        isEmpty,
      );
    });

    test('a profile switch waits for a deletion under way', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      bool? deletedBeforeSwitch;

      final deletion = deleteUsecase.deleteEntry(today);
      final switching = withProfileSwitchLock(() async {
        deletedBeforeSwitch = await weightLogRepository.getEntry(today) == null;
        provider.activeProfileId = 'profile-b';
      });
      await Future.wait([deletion, switching]);

      expect(deletedBeforeSwitch, isTrue);
      expect(await weightLogRepository.getEntry(today), isNull);
      expect(
        (await configRepository.getConfig()).healthDeletedExternalIds,
        contains('c'),
      );
    });

    test('a deletion queued behind a profile switch is dropped', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      final release = Completer<void>();

      final switching = withProfileSwitchLock(() => release.future);
      final deletion = deleteUsecase.deleteEntry(today);
      release.complete();
      await Future.wait([switching, deletion]);

      expect(await weightLogRepository.getEntry(today), isNotNull);
      expect(
        (await configRepository.getConfig()).healthDeletedExternalIds,
        isEmpty,
      );
    });

    test('deleting the entry that set the current weight restores the newest '
        'remaining one', () async {
      await weightLogRepository.addEntry(
        WeightLogEntity(date: DateTime(2026, 5, 20), weightKg: 82.0),
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];
      await usecase.importNow();
      expect((await userRepository.getUserData()).weightKG, equals(78.5));

      expect(await deleteUsecase.deleteEntry(today), isTrue);

      expect((await userRepository.getUserData()).weightKG, equals(82.0));
    });

    test('deleting the current reading after a time-zone change restores the '
        'one before it', () async {
      // After a move west: 'old' kept the day it was filed on, and the
      // later reading — the current weight — sits on the earlier date.
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: today,
          weightKg: 81.0,
          externalId: 'old',
          measuredAt: DateTime(2026, 5, 23, 7),
        ),
      );
      await weightLogRepository.addEntry(
        WeightLogEntity(
          date: yesterday,
          weightKg: 79.5,
          externalId: 'new',
          measuredAt: DateTime(2026, 5, 23, 12),
        ),
      );
      await usecase.importNow();
      expect((await userRepository.getUserData()).weightKG, equals(79.5));

      expect(await deleteUsecase.deleteEntry(yesterday), isTrue);

      expect((await userRepository.getUserData()).weightKG, equals(81.0));
    });

    test('deleting an older imported entry leaves the current weight', () async {
      healthService.weights = [
        _reading('b', DateTime(2026, 5, 22, 7), 80.9),
        _reading('c', DateTime(2026, 5, 23, 7), 78.5),
      ];
      await usecase.importNow();

      expect(await deleteUsecase.deleteEntry(yesterday), isFalse);

      expect((await userRepository.getUserData()).weightKG, equals(78.5));
    });

    test('deleting a manual entry leaves no tombstone', () async {
      await weightLogRepository.addEntry(
        WeightLogEntity(date: today, weightKg: 79.0),
      );
      await deleteUsecase.deleteEntry(today);

      expect(
        (await configRepository.getConfig()).healthDeletedExternalIds,
        isEmpty,
      );
    });
  });

  group('ImportWeightsUsecase window and scheduling', () {
    test('the first run backfills, later runs overlap the watermark', () async {
      await usecase.importNow();
      expect(
        healthService.lastFrom,
        equals(
          ImportWeightsUsecase.readWindowStart(now: now, lastImportAt: null),
        ),
      );
      expect(
        (await configRepository.getConfig()).healthWeightLastImportAt,
        equals(now),
      );

      final later = now.add(const Duration(hours: 2));
      ImportWeightsUsecase.clock = () => later;
      await usecase.importNow();
      expect(
        healthService.lastFrom,
        equals(now.subtract(ImportWeightsUsecase.overlapTolerance)),
      );
    });

    test('a long absence reads back no further than a backfill', () {
      final start = ImportWeightsUsecase.readWindowStart(
        now: now,
        lastImportAt: now.subtract(const Duration(days: 90)),
      );
      expect(
        start,
        equals(
          ImportWeightsUsecase.readWindowStart(now: now, lastImportAt: null),
        ),
      );
    });

    test('importIfDue is debounced by the watermark', () async {
      await usecase.importIfDue();
      ImportWeightsUsecase.clock = () => now.add(const Duration(minutes: 5));
      await usecase.importIfDue();

      expect(healthService.readWeightsCalls, equals(1));
    });

    test(
      'importIfDue swallows a refused read and keeps the watermark',
      () async {
        healthService.throwOnRead = true;

        expect(await usecase.importIfDue(), equals(0));
        expect(
          (await configRepository.getConfig()).healthWeightLastImportAt,
          isNull,
        );
      },
    );

    test('importNow surfaces a refused read', () async {
      healthService.throwOnRead = true;

      expect(usecase.importNow(), throwsStateError);
    });

    test(
      'with no health store, a resume keeps the watermark where it was',
      () async {
        final watermark = now.subtract(const Duration(hours: 1));
        await configDataSource.setConfigHealthWeightLastImportAt(watermark);
        final unavailable = ImportWeightsUsecase(
          HealthImportRepository(const NoopHealthService()),
          configRepository,
          weightLogRepository,
          userRepository,
          provider,
        );

        expect(await unavailable.importIfDue(), equals(0));
        expect(unavailable.importNow(), throwsStateError);
        await Future<void>.delayed(Duration.zero);
        expect(
          (await configRepository.getConfig()).healthWeightLastImportAt,
          equals(watermark),
        );
      },
    );

    test('switching away and back joins the run still in flight', () async {
      healthService.readGate = Completer<void>();

      final first = usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      provider.activeProfileId = 'profile-b';
      final other = usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      provider.activeProfileId = 'profile-a';
      final again = usecase.importNow();
      await Future<void>.delayed(Duration.zero);

      // One read for profile A, one for B — not a second one for A.
      expect(healthService.readWeightsCalls, equals(2));
      healthService.readGate!.complete();
      await Future.wait([first, other, again]);
    });

    test('a profile switch during the read files nothing', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      healthService.readGate = Completer<void>();

      final run = usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      provider.activeProfileId = 'profile-b';
      healthService.readGate!.complete();

      expect(await run, equals(0));
      expect(await weightLogRepository.getAllEntries(), isEmpty);
    });
  });

  group('ImportWeightsUsecase profile switch after filing', () {
    test('writes neither current weight nor watermark to the new profile', () async {
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        weightLogRepository,
        _SwitchingUserRepository(UserDataSource(provider), provider),
        provider,
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 78.5)];

      await usecase.importNow();

      expect((await userRepository.getUserData()).weightKG, equals(80.0));
      expect(
        (await configRepository.getConfig()).healthWeightLastImportAt,
        isNull,
      );
    });
  });

  group('ImportWeightsUsecase.weightsImported', () {
    test('fires after a run that filed readings, not after an empty one', () async {
      var events = 0;
      final subscription = usecase.weightsImported.listen((_) => events++);
      addTearDown(subscription.cancel);

      await usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      expect(events, equals(0));

      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      await Future<void>.delayed(Duration.zero);
      expect(events, equals(1));
    });
  });

  group('ImportWeightsUsecase alongside other weight writes', () {
    test('a wipe while the current weight is saved is not undone', () async {
      final users = _PausingUserRepository(UserDataSource(provider));
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        weightLogRepository,
        users,
        provider,
      );
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 79.4)];
      final release = Completer<void>();
      final reached = users.pause(release);

      final run = usecase.importNow();
      await reached;
      // What "Delete all my data" does to these boxes, under the same lock.
      final wipe = withTrackedDayLock(
        () => Future.wait([
          configBox.clear(),
          userBox.clear(),
          weightLogBox.clear(),
        ]),
      );
      await _finishedOrBlocked(wipe);
      release.complete();
      await run;
      await wipe;

      expect(await userRepository.hasUserData(), isFalse);
      expect(weightLogBox.isEmpty, isTrue);
    });

    test('a day deleted while its row is checked stays deleted', () async {
      final logs = _PausingWeightLogRepository(WeightLogDataSource(provider));
      usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        configRepository,
        logs,
        userRepository,
        provider,
      );
      healthService.weights = [_reading('b', DateTime(2026, 5, 22, 7), 80.9)];
      await usecase.importNow();

      final release = Completer<void>();
      final reached = logs.pause(release);
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));
      final run = usecase.importNow();
      await reached;
      final deletion = deleteUsecase.deleteEntry(yesterday);
      await _finishedOrBlocked(deletion);
      release.complete();
      await run;
      await deletion;

      expect(await weightLogRepository.getEntry(yesterday), isNull);
    });

    test(
      'a weight saved while a deletion restores the previous one stays',
      () async {
        final realToday = DateTime.now();
        await weightLogRepository.addEntry(
          WeightLogEntity(date: yesterday, weightKg: 81.0),
        );
        healthService.weights = [
          _reading('c', DateTime(2026, 5, 23, 7), 79.4),
        ];
        await usecase.importNow();
        expect((await userRepository.getUserData()).weightKG, equals(79.4));

        final users = _PausingUserRepository(UserDataSource(provider));
        final deleting = DeleteWeightLogUsecase(
          weightLogRepository,
          configRepository,
          users,
        );
        final release = Completer<void>();
        final reached = users.pause(release);
        final deletion = deleting.deleteEntry(today);
        await reached;
        final save = AddWeightLogUsecase(
          weightLogRepository,
          userRepository,
        ).addEntry(
          WeightLogEntity(
            date: DateTime(realToday.year, realToday.month, realToday.day),
            weightKg: 78.0,
          ),
        );
        await _finishedOrBlocked(save);
        release.complete();
        await deletion;
        await save;

        expect((await userRepository.getUserData()).weightKG, equals(78.0));
      },
    );

    test(
      'correcting the imported entry the weight came from corrects the weight',
      () async {
        healthService.weights = [
          _reading('b', DateTime(2026, 5, 22, 7), 80.9),
        ];
        await usecase.importNow();
        expect((await userRepository.getUserData()).weightKG, equals(80.9));

        final add = AddWeightLogUsecase(weightLogRepository, userRepository);
        // A backdated entry on another day leaves the weight alone.
        await add.addEntry(
          WeightLogEntity(date: DateTime(2026, 5, 20), weightKg: 82.0),
        );
        expect((await userRepository.getUserData()).weightKG, equals(80.9));

        await add.addEntry(WeightLogEntity(date: yesterday, weightKg: 80.2));
        expect((await userRepository.getUserData()).weightKG, equals(80.2));
      },
    );

    test('a row filed before a time-zone change is not filed twice', () async {
      // Stored under its day's key, with its date read back in a zone an
      // hour behind the one it was filed in: 23:00 on the day before.
      await weightLogBox.put(
        '2026-05-22',
        WeightLogDBO(
          date: DateTime(2026, 5, 21, 23),
          weightKg: 80.9,
          externalId: 'b',
          measuredAt: DateTime(2026, 5, 22, 7),
        ),
      );
      healthService.weights = [_reading('b', DateTime(2026, 5, 22, 7), 80.9)];

      expect(await usecase.importNow(), equals(0));
      expect(weightLogBox.keys, ['2026-05-22']);
    });
  });

  group('ImportWeightsUsecase.latestReadingPerDay', () {
    test('groups by local calendar day', () {
      final grouped = ImportWeightsUsecase.latestReadingPerDay([
        _reading('a', DateTime(2026, 5, 22, 23, 59), 80),
        _reading('b', DateTime(2026, 5, 23, 0, 1), 81),
      ]);
      expect(grouped.keys, containsAll([yesterday, today]));
      expect(grouped[yesterday]!.id, 'a');
      expect(grouped[today]!.id, 'b');
    });

    test('breaks a tie on the instant the same way in any order', () {
      final at = DateTime(2026, 5, 23, 7);
      final scale = _reading('scale-1', at, 80.2);
      final copy = _reading('sync-9', at, 80.25);

      expect(
        ImportWeightsUsecase.latestReadingPerDay([scale, copy])[today]!.id,
        'sync-9',
      );
      expect(
        ImportWeightsUsecase.latestReadingPerDay([copy, scale])[today]!.id,
        'sync-9',
      );
    });

    test('keeps a filed record on the day it was filed on', () {
      final grouped = ImportWeightsUsecase.latestReadingPerDay(
        [_reading('b', DateTime(2026, 5, 23, 0, 1), 81)],
        filedDays: {'b': yesterday},
      );
      expect(grouped.keys, [yesterday]);
    });
  });
}
