import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/health_export_diary_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/repository/health_export_diary_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

import '../helpers/hive_test_setup.dart';

/// A provider over plain, unencrypted boxes on disk: the registry, one
/// active profile's box-set, and scoped opens for every other profile.
class _ProfilesProvider extends HiveDBProvider {
  final Box<ProfileDBO> _profileBox;

  @override
  Box<ProfileDBO> get profileBox => _profileBox;

  @override
  String activeProfileId;

  @override
  bool isSwitching = false;

  /// Runs after each scoped open, to land a switch mid-read.
  void Function()? afterScopedOpen;

  final Map<String, String> _suffixes;

  _ProfilesProvider(this._profileBox, this.activeProfileId, this._suffixes);

  String get _activeSuffix => _suffixes[activeProfileId]!;

  @override
  Box<ConfigDBO> get configBox => Hive.box<ConfigDBO>(
    HiveDBProvider.boxNameFor(HiveDBProvider.configBoxName, _activeSuffix),
  );

  @override
  Box<IntakeDBO> get intakeBox => Hive.box<IntakeDBO>(
    HiveDBProvider.boxNameFor(HiveDBProvider.intakeBoxName, _activeSuffix),
  );

  @override
  Box<int> get healthExportLedgerBox => Hive.box<int>(
    HiveDBProvider.boxNameFor(
      HiveDBProvider.healthExportLedgerBoxName,
      _activeSuffix,
    ),
  );

  @override
  Future<Box<E>> openScopedBox<E>(String baseName, String boxSuffix) async {
    final box = await Hive.openBox<E>(
      HiveDBProvider.boxNameFor(baseName, boxSuffix),
    );
    afterScopedOpen?.call();
    return box;
  }
}

IntakeDBO _intake(String id, DateTime at) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: 100,
  type: IntakeTypeDBO.lunch,
  meal: MealDBO(
    code: id,
    name: id,
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: 'g',
    servingSize: null,
    nutriments: MealNutrimentsDBO(
      energyKcal100: 100,
      carbohydrates100: 10,
      fat100: 2,
      proteins100: 5,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: MealSourceDBO.custom,
  ),
  dateTime: at,
);

void main() {
  final at = DateTime(2026, 6, 15, 12, 30);
  final inWindow = at.add(const Duration(seconds: 20));
  final elsewhere = at.add(const Duration(hours: 1));
  const minute = Duration(minutes: 1);

  late Directory dir;
  late _ProfilesProvider db;
  late HealthExportDiaryRepository repository;

  String boxName(String base, String profile) =>
      HiveDBProvider.boxNameFor(base, 'export_$profile');

  /// Stores [profile]'s opt-in, diary and ledger, leaving its boxes open.
  /// [exported] defaults to the whole diary, at each entry's own time, when
  /// the profile has opted in.
  Future<void> seed(
    String profile, {
    required bool? optIn,
    List<IntakeDBO> intakes = const [],
    Map<String, DateTime>? exported,
  }) async {
    await db.profileBox.put(
      profile,
      ProfileDBO(
        id: profile,
        name: profile,
        createdAt: at,
        boxSuffix: 'export_$profile',
      ),
    );
    final config = await Hive.openBox<ConfigDBO>(
      boxName(HiveDBProvider.configBoxName, profile),
    );
    await config.put(
      ConfigDataSource.configKey,
      ConfigDBO.empty()..healthExportEnabled = optIn,
    );
    final diary = await Hive.openBox<IntakeDBO>(
      boxName(HiveDBProvider.intakeBoxName, profile),
    );
    await diary.addAll(intakes);
    final ledger = await Hive.openBox<int>(
      boxName(HiveDBProvider.healthExportLedgerBoxName, profile),
    );
    final records =
        exported ??
        (optIn == null
            ? const <String, DateTime>{}
            : {for (final intake in intakes) intake.id: intake.dateTime});
    await ledger.putAll({
      for (final MapEntry(:key, :value) in records.entries)
        key: value.millisecondsSinceEpoch,
    });
  }

  /// Closes [profile]'s boxes, as for any profile that is not active.
  Future<void> close(String profile) async {
    await Hive.box<ConfigDBO>(
      boxName(HiveDBProvider.configBoxName, profile),
    ).close();
    await Hive.box<IntakeDBO>(
      boxName(HiveDBProvider.intakeBoxName, profile),
    ).close();
    await Hive.box<int>(
      boxName(HiveDBProvider.healthExportLedgerBoxName, profile),
    ).close();
  }

  Set<String> ids(List<LedgerRecord> records) => {
    for (final record in records) '${record.profileId}/${record.intakeId}',
  };

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('health_export_diary');
    Hive.init(dir.path);
    db = _ProfilesProvider(await Hive.openBox<ProfileDBO>('profiles'), 'a', {
      'a': 'export_a',
      'b': 'export_b',
      'c': 'export_c',
      'd': 'export_d',
    });
    repository = HealthExportDiaryRepository(HealthExportDiaryDataSource(db));

    await seed(
      'a',
      optIn: true,
      intakes: [_intake('a1', at), _intake('a2', elsewhere)],
    );
    await seed('b', optIn: true, intakes: [_intake('b1', inWindow)]);
    await seed('c', optIn: null, intakes: [_intake('c1', inWindow)]);
    await seed('d', optIn: null);
    // Only the active profile's boxes stay open, as in the app.
    for (final profile in ['b', 'c', 'd']) {
      await close(profile);
    }
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  // #1393 review: a HealthKit window delete hits every profile's meals, so
  // the rewrite has to know what every profile has there.
  test('every profile\'s records in the window are read', () async {
    final records = await repository.recordsInWindows({at}, minute);

    expect(ids(records), {'a/a1', 'b/b1'});
    final b1 = records.singleWhere((record) => record.intakeId == 'b1');
    expect(b1.exportedAt, inWindow);
    expect(b1.current!.dateTime, inWindow);
    expect(b1.consenting, isTrue);
  });

  test('a record of a profile that opted out is not consenting', () async {
    await seed('d', optIn: false, intakes: [_intake('d1', inWindow)]);
    await close('d');

    final records = await repository.recordsInWindows({at}, minute);

    final d1 = records.singleWhere((record) => record.intakeId == 'd1');
    expect(d1.consenting, isFalse);
  });

  // Copilot review on #1393, round 4: where the store has a record is the
  // ledger's to say, not the diary's.
  test('a record is found by its ledger time, not its entry\'s', () async {
    await seed(
      'b',
      optIn: true,
      intakes: [_intake('moved', elsewhere)],
      exported: {'moved': inWindow},
    );
    await close('b');

    final records = await repository.recordsInWindows({at}, minute);
    final moved = records.singleWhere((record) => record.intakeId == 'moved');

    expect(moved.exportedAt, inWindow);
    expect(moved.current!.dateTime, elsewhere);
  });

  test('a deleted entry\'s record is an orphan until it goes', () async {
    await seed(
      'b',
      optIn: false,
      exported: {'gone': inWindow},
    );
    await close('b');

    final records = await repository.recordsInWindows({at}, minute);
    final gone = records.singleWhere((record) => record.intakeId == 'gone');

    expect(gone.current, isNull);
  });

  test('a profile\'s ledger is read whole, active or not', () async {
    expect(await repository.ledgerOf('a'), {'a1': at, 'a2': elsewhere});
    expect(await repository.ledgerOf('b'), {'b1': inWindow});
    expect(await repository.ledgerOf('unknown'), isEmpty);
    expect(Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, 'b')), isFalse);
  });

  test('a profile being wiped is left out without opening it', () async {
    final records = await repository.recordsInWindows(
      {at},
      minute,
      exceptProfile: 'b',
    );

    expect(ids(records), {'a/a1'});
  });

  test('other profiles\' boxes are closed, the active ones not', () async {
    await repository.recordsInWindows({at}, minute);

    expect(Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, 'a')), isTrue);
    expect(Hive.isBoxOpen(boxName(HiveDBProvider.configBoxName, 'a')), isTrue);
    for (final profile in ['b', 'c', 'd']) {
      expect(
        Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, profile)),
        isFalse,
      );
    }
  });

  // #1393 review: Hive hands both flows the same box instance, so a snapshot
  // closing it after its own read pulled it from under a profile copy that
  // was still writing to it.
  test('a box another flow has leased stays open until it lets go', () async {
    final name = boxName(HiveDBProvider.intakeBoxName, 'b');
    // What SendIntakeToProfilesUsecase holds while it copies into b.
    final copying = await db.leaseScopedBox<IntakeDBO>(
      HiveDBProvider.intakeBoxName,
      'export_b',
    );

    await repository.recordsInWindows({at}, minute);

    expect(Hive.isBoxOpen(name), isTrue);
    await copying.add(_intake('b2', elsewhere));
    await db.releaseScopedBox<IntakeDBO>(
      HiveDBProvider.intakeBoxName,
      'export_b',
    );
    expect(Hive.isBoxOpen(name), isFalse);
  });

  test('two reads at once leave no box closed under the other', () async {
    await Future.wait([
      repository.recordsInWindows({at}, minute),
      repository.recordsInWindows({at}, minute),
    ]);

    expect(Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, 'b')), isFalse);
  });

  test('a profile switch landing mid-read fails the read', () async {
    db.afterScopedOpen = () => db.activeProfileId = 'b';

    expect(
      () => repository.recordsInWindows({at}, minute),
      throwsStateError,
    );
  });

  test('a switch already under way fails the read', () async {
    db.isSwitching = true;

    expect(
      () => repository.recordsInWindows({at}, minute),
      throwsStateError,
    );
  });

  test('consent is read from the named profile, active or not', () async {
    expect(await repository.isExportEnabled('a'), isTrue);
    expect(await repository.isExportEnabled('b'), isTrue);
    expect(await repository.isExportEnabled('c'), isFalse);
    expect(await repository.isExportEnabled('unknown'), isFalse);
  });

  group('the export ledger', () {
    test('only entries the store got are records', () async {
      await seed(
        'b',
        optIn: true,
        intakes: [_intake('b2', inWindow)],
        exported: {'b1': inWindow},
      );
      await close('b');

      final records = await repository.recordsInWindows({at}, minute);

      expect(ids(records), {'a/a1', 'b/b1'});
    });

    test('is read and written for an inactive profile too', () async {
      await repository.updateLedger(
        'b',
        put: {'b9': elsewhere},
        remove: {'b1'},
      );

      expect(await repository.exportedAt('b', ['b1', 'b9']), {
        'b9': elsewhere,
      });
      expect(
        Hive.isBoxOpen(boxName(HiveDBProvider.healthExportLedgerBoxName, 'b')),
        isFalse,
      );

      await repository.clearLedger('b');
      expect(await repository.ledgerOf('b'), isEmpty);
    });

    test('the active profile\'s ledger is its open box', () async {
      await repository.updateLedger('a', remove: {'a1'});

      expect(await repository.exportedAt('a', ['a1', 'a2']), {
        'a2': elsewhere,
      });
      expect(
        Hive.isBoxOpen(boxName(HiveDBProvider.healthExportLedgerBoxName, 'a')),
        isTrue,
      );
    });

    // Review round 5 on #1393: the ledger keeps milliseconds, so a time
    // with microseconds is found in the window of its record start.
    test('a microsecond time is kept, and found, to the millisecond', () async {
      final now = DateTime(2026, 6, 15, 12, 30, 0, 123, 456);
      final start = ExternalMealIntake.recordStart(now);
      await repository.updateLedger('a', put: {'now': now});

      expect(start, DateTime(2026, 6, 15, 12, 30, 0, 123));
      expect(await repository.exportedAt('a', ['now']), {'now': start});
      final records = await repository.recordsInWindows({start}, minute);
      expect(ids(records), contains('a/now'));
    });

    // Codex, round 6: a delete that never ran leaves its record in the
    // ledger with no entry, which start-up recovery looks for.
    test('orphans are the records whose entry is gone', () async {
      await repository.updateLedger('b', put: {'gone': inWindow});

      expect(await repository.orphans(), {
        'a': isEmpty,
        'b': {'gone': inWindow},
        'c': isEmpty,
        'd': isEmpty,
      });
    });
  });
}
