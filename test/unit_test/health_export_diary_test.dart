import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
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
  Box<bool> get healthExportLedgerBox => Hive.box<bool>(
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

  late Directory dir;
  late _ProfilesProvider db;
  late HealthExportDiaryRepository repository;

  String boxName(String base, String profile) =>
      HiveDBProvider.boxNameFor(base, 'export_$profile');

  /// Stores [profile]'s opt-in, diary and ledger, leaving its boxes open.
  /// [exported] defaults to the whole diary when the profile has opted in.
  Future<void> seed(
    String profile, {
    required bool? optIn,
    List<IntakeDBO> intakes = const [],
    Set<String>? exported,
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
    final ledger = await Hive.openBox<bool>(
      boxName(HiveDBProvider.healthExportLedgerBoxName, profile),
    );
    final marked =
        exported ??
        (optIn == null ? const <String>{} : {for (final i in intakes) i.id});
    await ledger.putAll({for (final id in marked) id: true});
  }

  /// Closes [profile]'s boxes, as for any profile that is not active.
  Future<void> close(String profile) async {
    await Hive.box<ConfigDBO>(
      boxName(HiveDBProvider.configBoxName, profile),
    ).close();
    await Hive.box<IntakeDBO>(
      boxName(HiveDBProvider.intakeBoxName, profile),
    ).close();
    await Hive.box<bool>(
      boxName(HiveDBProvider.healthExportLedgerBoxName, profile),
    ).close();
  }

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
  // the rewrite has to know what every exporting profile holds there.
  test('a snapshot covers every exporting profile, in the window', () async {
    final snapshot = await repository.snapshotWindows(
      {at},
      const Duration(minutes: 1),
    );

    expect(snapshot.exported.map((entry) => entry.intake.id), {'a1', 'b1'});
    expect(snapshot.exported.map((entry) => entry.profileId), {'a', 'b'});
    // c never opted in, so nothing of it was ever exported.
    expect(snapshot.blocked, isEmpty);
  });

  test('an entry of a profile that opted out again is flagged', () async {
    await seed('d', optIn: false, intakes: [_intake('d1', inWindow)]);
    await close('d');

    final snapshot = await repository.snapshotWindows(
      {at},
      const Duration(minutes: 1),
    );

    expect(snapshot.blocked.map((intake) => intake.id), ['d1']);
  });

  // #1393 review: a wipe has to read the whole diary before it is cleared.
  test('a profile is read whole, active or not', () async {
    final active = await repository.readProfile('a');
    final inactive = await repository.readProfile('b');

    expect(active!.exportEnabled, isTrue);
    expect(active.exported.map((intake) => intake.id), ['a1', 'a2']);
    expect(inactive!.exported.map((intake) => intake.id), ['b1']);
    expect(await repository.readProfile('unknown'), isNull);
    expect(Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, 'b')), isFalse);
  });

  test('a profile being wiped is left out without opening it', () async {
    final snapshot = await repository.snapshotWindows(
      {at},
      const Duration(minutes: 1),
      exceptProfile: 'b',
    );

    expect(snapshot.exported.map((entry) => entry.intake.id), ['a1']);
  });

  test('other profiles\' boxes are closed, the active ones not', () async {
    await repository.snapshotWindows({at}, const Duration(minutes: 1));

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

    await repository.snapshotWindows({at}, const Duration(minutes: 1));

    expect(Hive.isBoxOpen(name), isTrue);
    await copying.add(_intake('b2', elsewhere));
    await db.releaseScopedBox<IntakeDBO>(
      HiveDBProvider.intakeBoxName,
      'export_b',
    );
    expect(Hive.isBoxOpen(name), isFalse);
  });

  test('two snapshots at once leave no box closed under the other', () async {
    await Future.wait([
      repository.snapshotWindows({at}, const Duration(minutes: 1)),
      repository.snapshotWindows({at}, const Duration(minutes: 1)),
    ]);

    expect(Hive.isBoxOpen(boxName(HiveDBProvider.intakeBoxName, 'b')), isFalse);
  });

  test('a profile switch landing mid-read fails the snapshot', () async {
    db.afterScopedOpen = () => db.activeProfileId = 'b';

    expect(
      () => repository.snapshotWindows({at}, const Duration(minutes: 1)),
      throwsStateError,
    );
  });

  test('a switch already under way fails the snapshot', () async {
    db.isSwitching = true;

    expect(
      () => repository.snapshotWindows({at}, const Duration(minutes: 1)),
      throwsStateError,
    );
  });

  test('consent is read from the named profile, active or not', () async {
    expect(await repository.isExportEnabled('a'), isTrue);
    expect(await repository.isExportEnabled('b'), isTrue);
    expect(await repository.isExportEnabled('c'), isFalse);
    expect(await repository.isExportEnabled('unknown'), isFalse);
  });

  // #1393 review: only entries the export wrote may be rewritten, or a
  // rewrite backfills what was logged before the opt-in.
  group('the export ledger', () {
    test('a snapshot leaves out entries the store never got', () async {
      await seed(
        'b',
        optIn: true,
        intakes: [_intake('b2', inWindow)],
        exported: {'b1'},
      );
      await close('b');

      final snapshot = await repository.snapshotWindows(
        {at},
        const Duration(minutes: 1),
      );

      expect(snapshot.exported.map((entry) => entry.intake.id), {'a1', 'b1'});
    });

    test('is read and written for an inactive profile too', () async {
      await repository.updateLedger('b', add: {'b9'}, remove: {'b1'});

      expect(await repository.exportedAmong('b', ['b1', 'b9']), {'b9'});
      expect(
        Hive.isBoxOpen(boxName(HiveDBProvider.healthExportLedgerBoxName, 'b')),
        isFalse,
      );

      await repository.clearLedger('b');
      expect(await repository.exportedAmong('b', ['b9']), isEmpty);
    });

    test('the active profile\'s ledger is its open box', () async {
      await repository.updateLedger('a', remove: {'a1'});

      expect(await repository.exportedAmong('a', ['a1', 'a2']), {'a2'});
      expect(
        Hive.isBoxOpen(boxName(HiveDBProvider.healthExportLedgerBoxName, 'a')),
        isTrue,
      );
    });
  });
}
