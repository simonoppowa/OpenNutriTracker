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
  /// it was ever exported; false when it opted out again, so records it
  /// exported earlier may still be in the health store.
  final bool? exportEnabled;

  final List<IntakeDBO> intakes;

  const ProfileDiaryEntries({
    required this.profileId,
    required this.exportEnabled,
    required this.intakes,
  });
}

/// Reads diaries across every profile for the meal export.
///
/// HealthKit has no way to tell one profile's meals from another's, so an
/// iOS window delete removes every profile's meals in that minute, and the
/// export has to know what each profile still holds there. The active
/// profile is read from its open boxes; any other profile's boxes are leased
/// for the read ([HiveDBProvider.leaseScopedBox]), as
/// `SendIntakeToProfilesUsecase` does, so neither closes them on the other.
class HealthExportDiaryDataSource {
  final HiveDBProvider _db;

  HealthExportDiaryDataSource(this._db);

  String get activeProfileId => _db.activeProfileId;

  /// [profileId]'s stored opt-in, or null when the profile is not registered.
  Future<bool?> exportEnabledFor(String profileId) async {
    final profile = _db.profileBox.get(profileId);
    if (profile == null) return null;
    return _read(profile, (config, _) => _exportFlag(config));
  }

  /// Every registered profile's opt-in and the entries whose start time
  /// satisfies [startsInside].
  ///
  /// Throws a [StateError] when a profile switch is under way or lands while
  /// reading: the per-profile boxes move underneath it, so the result could
  /// file one profile's entries under another's consent.
  Future<List<ProfileDiaryEntries>> readAllProfiles(
    bool Function(DateTime start) startsInside,
  ) async {
    final activeAtStart = _db.activeProfileId;
    _ensureSettled(activeAtStart);
    final result = <ProfileDiaryEntries>[];
    for (final profile in _db.profileBox.values.toList()) {
      result.add(
        await _read(
          profile,
          (config, intakes) => ProfileDiaryEntries(
            profileId: profile.id,
            exportEnabled: _exportFlag(config),
            intakes: intakes.values
                .where((intake) => startsInside(intake.dateTime))
                .toList(),
          ),
        ),
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

  static bool? _exportFlag(Box<ConfigDBO> config) =>
      config.get(ConfigDataSource.configKey)?.healthExportEnabled;

  Future<T> _read<T>(
    ProfileDBO profile,
    T Function(Box<ConfigDBO> config, Box<IntakeDBO> intakes) read,
  ) async {
    if (profile.id == _db.activeProfileId) {
      // These getters throw while a switch is under way.
      return read(_db.configBox, _db.intakeBox);
    }

    // Leased, not opened: another flow may be working on this profile's
    // boxes at the same time, and only the last lease closes them.
    final suffix = profile.boxSuffix;
    final config = await _db.leaseScopedBox<ConfigDBO>(
      HiveDBProvider.configBoxName,
      suffix,
    );
    try {
      final intakes = await _db.leaseScopedBox<IntakeDBO>(
        HiveDBProvider.intakeBoxName,
        suffix,
      );
      try {
        return read(config, intakes);
      } finally {
        await _db.releaseScopedBox<IntakeDBO>(
          HiveDBProvider.intakeBoxName,
          suffix,
        );
      }
    } finally {
      await _db.releaseScopedBox<ConfigDBO>(
        HiveDBProvider.configBoxName,
        suffix,
      );
    }
  }
}
