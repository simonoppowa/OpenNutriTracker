import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// One profile's export opt-in and the ledger records it has in some export
/// windows, with the diary rows they belong to.
class ProfileLedgerRecords {
  final String profileId;

  /// The stored opt-in: null when the profile never opted in.
  final bool? exportEnabled;

  /// Ledger records in the windows: intake id to the start time, in
  /// milliseconds since the epoch, of the record the store holds for it.
  final Map<String, int> exportedAt;

  /// The diary rows of those records still in the diary, by intake id. A
  /// record without a row here is an orphan: its entry was deleted, and its
  /// record still has to go.
  final Map<String, IntakeDBO> rows;

  const ProfileLedgerRecords({
    required this.profileId,
    required this.exportEnabled,
    required this.exportedAt,
    required this.rows,
  });
}

/// Reads diaries and export ledgers across every profile for the meal
/// export.
///
/// The ledger ([HiveDBProvider.healthExportLedgerBoxName]) is the durable
/// account of what the health store holds: for each entry the export wrote,
/// the start time of its record. It is kept apart from the diary — a record
/// stays in it after its entry is edited while export is off, or deleted,
/// until the store no longer holds it — because HealthKit can only find a
/// record by that time.
///
/// HealthKit cannot tell one profile's meals from another's either, so an
/// iOS window delete removes every profile's records in that minute, and the
/// export has to know what each profile has there. The active profile is
/// read from its open boxes; any other profile's boxes are leased for the
/// read ([HiveDBProvider.leaseScopedBox]), as `SendIntakeToProfilesUsecase`
/// does, so neither closes them on the other.
class HealthExportDiaryDataSource {
  final HiveDBProvider _db;

  HealthExportDiaryDataSource(this._db);

  String get activeProfileId => _db.activeProfileId;

  /// [profileId]'s stored opt-in, or null when the profile is not registered.
  ///
  /// For the active profile the boxes are read before this first suspends,
  /// so the value is the one stored when it was called.
  Future<bool?> exportEnabledFor(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return null;
    return _read(profile, (config, _, _) => _exportFlag(config));
  }

  /// [profileId]'s whole ledger, or null when it is not registered.
  Future<Map<String, int>?> readLedger(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return null;
    return _read(profile, (_, _, ledger) => _entries(ledger));
  }

  /// The ledger records of [intakeIds] in [profileId]'s ledger.
  Future<Map<String, int>> ledgerRecordsOf(
    String profileId,
    Iterable<String> intakeIds,
  ) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return {};
    return _read(
      profile,
      (_, _, ledger) => {
        for (final id in intakeIds)
          if (ledger.get(id) case final int at) id: at,
      },
    );
  }

  /// Records [put] in [profileId]'s ledger and drops [remove] from it.
  Future<void> updateLedger(
    String profileId, {
    Map<String, int> put = const {},
    Set<String> remove = const {},
  }) async {
    if (put.isEmpty && remove.isEmpty) return;
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return;
    await _read(profile, (_, _, ledger) async {
      await ledger.putAll(put);
      await ledger.deleteAll(remove.difference(put.keys.toSet()));
    });
  }

  /// Empties [profileId]'s ledger.
  Future<void> clearLedger(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return;
    await _read(profile, (_, _, ledger) => ledger.clear());
  }

  /// Every registered profile's opt-in and the ledger records whose time
  /// satisfies [inside], with their diary rows. [exceptProfile] is skipped
  /// without opening its boxes, for a profile whose storage is being wiped
  /// or deleted.
  ///
  /// Throws a [StateError] when a profile switch is under way or lands while
  /// reading: the per-profile boxes move underneath it, so the result could
  /// file one profile's entries under another's consent.
  Future<List<ProfileLedgerRecords>> readWindowRecords(
    bool Function(DateTime time) inside, {
    String? exceptProfile,
  }) async {
    final activeAtStart = _db.activeProfileId;
    _ensureSettled(activeAtStart);
    final result = <ProfileLedgerRecords>[];
    for (final profile in _db.profileBox.values.toList()) {
      if (profile.id == exceptProfile) continue;
      result.add(
        await _read(profile, (config, intakes, ledger) {
          final exportedAt = {
            for (final MapEntry(:key, :value) in _entries(ledger).entries)
              if (inside(DateTime.fromMillisecondsSinceEpoch(value)))
                key: value,
          };
          return ProfileLedgerRecords(
            profileId: profile.id,
            exportEnabled: _exportFlag(config),
            exportedAt: exportedAt,
            rows: exportedAt.isEmpty
                ? const {}
                : {
                    for (final row in intakes.values)
                      if (exportedAt.containsKey(row.id)) row.id: row,
                  },
          );
        }),
      );
    }
    _ensureSettled(activeAtStart);
    return result;
  }

  void _ensureSettled(String expectedActive) {
    if (_db.isSwitching || _db.activeProfileId != expectedActive) {
      throw StateError('A profile switch happened while reading diaries');
    }
  }

  static Map<String, int> _entries(Box<int> ledger) => {
    for (final key in ledger.keys)
      if (ledger.get(key) case final int at) key as String: at,
  };

  static bool? _exportFlag(Box<ConfigDBO> config) =>
      config.get(ConfigDataSource.configKey)?.healthExportEnabled;

  /// Runs [read] against [profile]'s config, diary and ledger boxes. A
  /// future [read] returns is awaited before any scoped box is released.
  Future<T> _read<T>(
    ProfileDBO profile,
    T Function(
      Box<ConfigDBO> config,
      Box<IntakeDBO> intakes,
      Box<int> ledger,
    )
    read,
  ) async {
    if (profile.id == _db.activeProfileId) {
      // These getters throw while a switch is under way.
      return read(_db.configBox, _db.intakeBox, _db.healthExportLedgerBox);
    }

    // Leased, not opened: another flow may be working on this profile's
    // boxes at the same time, and only the last lease closes them.
    final suffix = profile.boxSuffix;
    final releases = <Future<void> Function()>[];
    Future<Box<E>> lease<E>(String base) async {
      final box = await _db.leaseScopedBox<E>(base, suffix);
      releases.add(() => _db.releaseScopedBox<E>(base, suffix));
      return box;
    }

    try {
      final config = await lease<ConfigDBO>(HiveDBProvider.configBoxName);
      final intakes = await lease<IntakeDBO>(HiveDBProvider.intakeBoxName);
      final ledger = await lease<int>(HiveDBProvider.healthExportLedgerBoxName);
      final result = read(config, intakes, ledger);
      // A write handed back as a future has to land before the release.
      if (result is Future) await result;
      return result;
    } finally {
      for (final release in releases.reversed) {
        await release();
      }
    }
  }
}
