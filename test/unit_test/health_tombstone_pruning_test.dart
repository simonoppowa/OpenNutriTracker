import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/import_workouts_usecase.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Bounding the deletion tombstone list (#768).
///
/// A tombstone exists so a deleted workout is not re-imported by the next
/// overlapping read. It stops being useful the moment its workout falls
/// outside any window a future import could ask for — and the risk in pruning
/// is dropping one that is still doing work, so the boundary is where the
/// tests are concentrated.
void main() {
  const overlap = ImportWorkoutsUsecase.overlapTolerance;
  final now = DateTime(2026, 8, 27, 12);

  group('the instant before which a tombstone is dead weight', () {
    test('with no watermark it is a full backfill plus the overlap', () {
      // What a first run asks for, so nothing inside it may be pruned.
      final cutoff = ConfigEntity.oldestUsefulTombstone(
        now: now,
        lastImportAt: null,
        overlapTolerance: overlap,
      );

      expect(
        cutoff,
        now
            .subtract(
              const Duration(days: ConfigEntity.healthImportBackfillDays),
            )
            .subtract(overlap),
      );
    });

    test('a recent watermark does not raise the cutoff above the floor', () {
      // The next run only needs 24 hours back, but a watermark that was lost
      // without its tombstones would send the run after that on a full
      // backfill. Keeping the floor costs a few stale entries; ignoring it
      // would resurrect deleted workouts.
      final cutoff = ConfigEntity.oldestUsefulTombstone(
        now: now,
        lastImportAt: now,
        overlapTolerance: overlap,
      );

      expect(cutoff, now.subtract(const Duration(days: 31)));
    });

    test('a watermark older than the floor lowers the cutoff to it', () {
      // Health import switched off for months, then back on: the next window
      // reaches back to that old watermark, and every tombstone inside it is
      // still protecting something.
      final stale = now.subtract(const Duration(days: 120));

      final cutoff = ConfigEntity.oldestUsefulTombstone(
        now: now,
        lastImportAt: stale,
        overlapTolerance: overlap,
      );

      expect(cutoff, stale.subtract(overlap));
    });

    test('the cutoff never sits after the start of the next window', () {
      // The property that matters, stated directly: whatever the watermark,
      // a workout the next run can still see must not have been pruned.
      for (final watermark in <DateTime?>[
        null,
        now,
        now.subtract(const Duration(hours: 1)),
        now.subtract(const Duration(days: 5)),
        now.subtract(const Duration(days: 31)),
        now.subtract(const Duration(days: 400)),
      ]) {
        final nextWindowStart =
            (watermark ??
                    now.subtract(
                      const Duration(
                        days: ConfigEntity.healthImportBackfillDays,
                      ),
                    ))
                .subtract(overlap);
        final cutoff = ConfigEntity.oldestUsefulTombstone(
          now: now,
          lastImportAt: watermark,
          overlapTolerance: overlap,
        );

        expect(
          cutoff.isAfter(nextWindowStart),
          isFalse,
          reason:
              'watermark $watermark: cutoff $cutoff would prune a tombstone '
              'the next window ($nextWindowStart onwards) still needs',
        );
      }
    });
  });

  group('pruning against a live config box', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileBox;
    late ConfigDataSource source;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      appBox = await Hive.openBox<ConfigDBO>('tombstone_app_test');
      profileBox = await Hive.openBox<ConfigDBO>('tombstone_profile_test');
      await appBox.clear();
      await profileBox.clear();
      source = ConfigDataSource(
        FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
      );
      await source.initializeConfig();
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    test('a tombstone older than the cutoff is dropped', () async {
      await source.addConfigHealthDeletedWorkout(
        'ancient',
        now.subtract(const Duration(days: 200)),
      );
      await source.addConfigHealthDeletedWorkout(
        'recent',
        now.subtract(const Duration(hours: 3)),
      );

      await source.pruneConfigHealthDeletedWorkouts(
        now.subtract(const Duration(days: 31)),
      );

      final config = await source.getConfig();
      expect(config.healthDeletedWorkouts?.keys, ['recent']);
    });

    test('a tombstone exactly on the cutoff is kept', () async {
      // The window is inclusive of its start, so an entry sitting on the
      // boundary can still be returned by the next read.
      final cutoff = now.subtract(const Duration(days: 31));
      await source.addConfigHealthDeletedWorkout('on-the-line', cutoff);

      await source.pruneConfigHealthDeletedWorkouts(cutoff);

      final config = await source.getConfig();
      expect(config.healthDeletedWorkouts?.keys, ['on-the-line']);
    });

    test('pruning with nothing stale leaves the map alone', () async {
      await source.addConfigHealthDeletedWorkout('a', now);
      await source.addConfigHealthDeletedWorkout('b', now);

      await source.pruneConfigHealthDeletedWorkouts(
        now.subtract(const Duration(days: 31)),
      );

      final config = await source.getConfig();
      expect(config.healthDeletedWorkouts, hasLength(2));
    });

    test('the same deletion recorded twice does not grow the map', () async {
      final started = DateTime(2026, 8, 1, 9);
      await source.addConfigHealthDeletedWorkout('dup', started);
      await source.addConfigHealthDeletedWorkout('dup', started);

      final config = await source.getConfig();
      expect(config.healthDeletedWorkouts, hasLength(1));
    });
  });

  group('the undated ids a pre-release install may carry', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileBox;
    late ConfigDataSource source;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      appBox = await Hive.openBox<ConfigDBO>('tombstone_legacy_app_test');
      profileBox = await Hive.openBox<ConfigDBO>('tombstone_legacy_test');
      await appBox.clear();
      await profileBox.clear();
      source = ConfigDataSource(
        FakeHiveDBProvider(configBox: profileBox, appConfigBox: appBox),
      );
    });

    tearDown(() async {
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    Future<void> seedLegacy(List<String> ids) async {
      final dbo = ConfigDBO(
        false,
        true,
        false,
        AppThemeDBO.system,
        healthDeletedExternalIds: ids,
      );
      await appBox.put('ConfigKey', ConfigDBO.fromJson(dbo.toJson()));
      await profileBox.put('ConfigKey', ConfigDBO.fromJson(dbo.toJson()));
    }

    test('an undated id survives the move to dated tombstones', () async {
      // Before #768 a tombstone was an id and nothing else. Dropping them on
      // upgrade would resurrect workouts the user had already deleted.
      await seedLegacy(['legacy-1', 'legacy-2']);

      await source.addConfigHealthDeletedWorkout('new-one', now);

      final config = await source.getConfig();
      expect(
        config.healthDeletedWorkouts?.keys,
        containsAll(<String>['legacy-1', 'legacy-2', 'new-one']),
      );
      expect(
        config.healthDeletedExternalIds,
        isNull,
        reason: 'the legacy list should be cleared once it has been folded in',
      );
    });

    test('an undated id is not pruned immediately', () async {
      // It is dated "now" because there is nothing to date it from, which
      // keeps it for one more full window and then lets it drain. Erring
      // toward honouring the deletion is the direction that cannot annoy.
      await seedLegacy(['legacy-1']);

      await source.pruneConfigHealthDeletedWorkouts(
        DateTime.now().subtract(const Duration(days: 31)),
      );

      final config = await source.getConfig();
      expect(config.healthDeletedWorkouts?.keys, ['legacy-1']);
    });

    test('the importer sees legacy ids before any write migrates them', () {
      // The migration happens on the next write, so a read that ignored the
      // undated list would let the importer re-file every workout the user had
      // already deleted — the exact bug the tombstones exist to prevent.
      final config = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          true,
          false,
          AppThemeDBO.system,
          healthDeletedExternalIds: ['legacy-1', 'legacy-2'],
        ),
      );

      // ImportWorkoutsUsecase reads exactly this.
      expect(
        config.healthDeletedExternalIds,
        containsAll(<String>['legacy-1', 'legacy-2']),
      );
    });

    test('dated and undated ids are both visible at once', () {
      final config = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          true,
          false,
          AppThemeDBO.system,
          healthDeletedExternalIds: ['legacy-1'],
          healthDeletedWorkouts: {'dated-1': now},
        ),
      );

      expect(config.healthDeletedExternalIds, {'legacy-1', 'dated-1'});
    });
  });
}
