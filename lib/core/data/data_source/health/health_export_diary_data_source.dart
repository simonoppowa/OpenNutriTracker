import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// One profile's meal-export opt-in and some of its diary entries.
class ProfileDiaryEntries {
  final String profileId;

  /// The stored opt-in: null when the profile never opted in, so nothing of
  /// it was ever exported; false when it opted out again.
  final bool? exportEnabled;

  final List<IntakeDBO> intakes;

  /// The ids among [intakes] the profile's export ledger marks as being in
  /// the health store.
  final Set<String> exportedIds;

  const ProfileDiaryEntries({
    required this.profileId,
    required this.exportEnabled,
    required this.intakes,
    required this.exportedIds,
  });
}

/// Reads diaries and export ledgers across every profile for the meal
/// export.
///
/// HealthKit has no way to tell one profile's meals from another's, so an
/// iOS window delete removes every profile's meals in that minute, and the
/// export has to know what each profile still holds there. The ledger
/// ([HiveDBProvider.healthExportLedgerBoxName]) records which entries the
/// export has put in the store, so nothing logged before an opt-in is ever
/// written by a later rewrite. The active profile is read from its open
/// boxes; any other profile's boxes are leased for the read
/// ([HiveDBProvider.leaseScopedBox]), as `SendIntakeToProfilesUsecase` does,
/// so neither closes them on the other.
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

  /// [profileId]'s opt-in and its whole diary, or null when the profile is
  /// not registered.
  Future<ProfileDiaryEntries?> readProfile(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return null;
    return _read(
      profile,
      (config, intakes, ledger) => _entries(
        profile,
        config,
        intakes.values.toList(),
        ledger,
      ),
    );
  }

  /// Every registered profile's opt-in and the entries whose start time
  /// satisfies [startsInside]. [exceptProfile] is skipped without opening
  /// its boxes, for a profile whose storage is being wiped or deleted.
  ///
  /// Throws a [StateError] when a profile switch is under way or lands while
  /// reading: the per-profile boxes move underneath it, so the result could
  /// file one profile's entries under another's consent.
  Future<List<ProfileDiaryEntries>> readAllProfiles(
    bool Function(DateTime start) startsInside, {
    String? exceptProfile,
  }) async {
    final activeAtStart = _db.activeProfileId;
    _ensureSettled(activeAtStart);
    final result = <ProfileDiaryEntries>[];
    for (final profile in _db.profileBox.values.toList()) {
      if (profile.id == exceptProfile) continue;
      result.add(
        await _read(
          profile,
          (config, intakes, ledger) => _entries(
            profile,
            config,
            intakes.values
                .where((intake) => startsInside(intake.dateTime))
                .toList(),
            ledger,
          ),
        ),
      );
    }
    _ensureSettled(activeAtStart);
    return result;
  }

  /// The ids among [intakeIds] that [profileId]'s ledger marks as exported.
  Future<Set<String>> exportedAmong(
    String profileId,
    Iterable<String> intakeIds,
  ) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return {};
    return _read(
      profile,
      (_, _, ledger) => intakeIds.where(ledger.containsKey).toSet(),
    );
  }

  /// Marks [add] as exported in [profileId]'s ledger and [remove] as not.
  Future<void> updateLedger(
    String profileId, {
    Set<String> add = const {},
    Set<String> remove = const {},
  }) async {
    if (add.isEmpty && remove.isEmpty) return;
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return;
    await _read(profile, (_, _, ledger) async {
      await ledger.putAll({for (final id in add) id: true});
      await ledger.deleteAll(remove.difference(add));
    });
  }

  /// Empties [profileId]'s ledger.
  Future<void> clearLedger(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return;
    await _read(profile, (_, _, ledger) => ledger.clear());
  }

  void _ensureSettled(String expectedActive) {
    if (_db.isSwitching || _db.activeProfileId != expectedActive) {
      throw StateError('A profile switch happened while reading diaries');
    }
  }

  static ProfileDiaryEntries _entries(
    ProfileDBO profile,
    Box<ConfigDBO> config,
    List<IntakeDBO> intakes,
    Box<bool> ledger,
  ) => ProfileDiaryEntries(
    profileId: profile.id,
    exportEnabled: _exportFlag(config),
    intakes: intakes,
    exportedIds: {
      for (final intake in intakes)
        if (ledger.containsKey(intake.id)) intake.id,
    },
  );

  static bool? _exportFlag(Box<ConfigDBO> config) =>
      config.get(ConfigDataSource.configKey)?.healthExportEnabled;

  /// Runs [read] against [profile]'s config, diary and ledger boxes. A
  /// future [read] returns has to be awaited by the caller before a scoped
  /// box could close: [_read] releases its leases when [read] returns.
  Future<T> _read<T>(
    ProfileDBO profile,
    T Function(
      Box<ConfigDBO> config,
      Box<IntakeDBO> intakes,
      Box<bool> ledger,
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
      final ledger = await lease<bool>(
        HiveDBProvider.healthExportLedgerBoxName,
      );
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
