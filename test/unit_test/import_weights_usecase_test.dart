import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_weights_usecase.dart';

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

  late FakeHiveDBProvider provider;
  late ConfigDataSource configDataSource;
  late ConfigRepository configRepository;
  late WeightLogRepository weightLogRepository;
  late UserRepository userRepository;
  late _FakeHealthService healthService;
  late ImportWeightsUsecase usecase;
  late DeleteWeightLogUsecase deleteUsecase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    configBox = await Hive.openBox<ConfigDBO>('weight_import_config_test');
    weightLogBox = await Hive.openBox<WeightLogDBO>('weight_import_log_test');
    userBox = await Hive.openBox<UserDBO>('weight_import_user_test');
    await configBox.clear();
    await weightLogBox.clear();
    await userBox.clear();

    provider = FakeHiveDBProvider(
      activeProfileId: 'profile-a',
      configBox: configBox,
      weightLogBox: weightLogBox,
      userBox: userBox,
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

    test('re-reading the same readings writes nothing', () async {
      healthService.weights = [_reading('c', DateTime(2026, 5, 23, 7), 80.2)];
      await usecase.importNow();
      ImportWeightsUsecase.clock = () => now.add(const Duration(hours: 1));

      expect(await usecase.importNow(), equals(0));
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

  group('ImportWeightsUsecase deletion', () {
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
  });
}
