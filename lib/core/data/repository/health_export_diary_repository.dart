import 'package:opennutritracker/core/data/data_source/health/health_export_diary_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// What the diaries of every profile hold in a set of export windows.
class ExportWindowSnapshot {
  /// Entries of profiles that export meals: the records the windows should
  /// hold, each written under its own profile's opt-in.
  final List<IntakeEntity> exported;

  /// Entries of profiles that opted out again. Such an entry may still have
  /// a record in its window, and rewriting it would export without consent,
  /// so deleting that window would lose the record for good. Entries of
  /// profiles that never opted in have no records and are left out.
  final List<IntakeEntity> optedOut;

  const ExportWindowSnapshot({required this.exported, required this.optedOut});
}

/// One profile's opt-in and its whole diary.
class ProfileDiary {
  /// Null when the profile never opted in, so nothing of it was exported.
  final bool? exportEnabled;
  final List<IntakeEntity> intakes;

  const ProfileDiary({required this.exportEnabled, required this.intakes});
}

/// The diary side of the meal export: which profile is active, whether a
/// profile exports, and what every profile holds in a window.
class HealthExportDiaryRepository {
  final HealthExportDiaryDataSource _dataSource;

  HealthExportDiaryRepository(this._dataSource);

  String get activeProfileId => _dataSource.activeProfileId;

  Future<bool> isExportEnabled(String profileId) async =>
      await _dataSource.exportEnabledFor(profileId) ?? false;

  /// [profileId]'s opt-in and diary, or null when it is not registered.
  Future<ProfileDiary?> readProfile(String profileId) async {
    final profile = await _dataSource.readProfile(profileId);
    if (profile == null) return null;
    return ProfileDiary(
      exportEnabled: profile.exportEnabled,
      intakes: profile.intakes.map(IntakeEntity.fromIntakeDBO).toList(),
    );
  }

  /// Reads every profile's entries starting in any window
  /// `[start, start + length)`, skipping [exceptProfile]. Throws when a
  /// profile switch interferes.
  Future<ExportWindowSnapshot> snapshotWindows(
    Set<DateTime> starts,
    Duration length, {
    String? exceptProfile,
  }) async {
    bool startsInside(DateTime time) => starts.any(
      (start) => !time.isBefore(start) && time.isBefore(start.add(length)),
    );
    final profiles = await _dataSource.readAllProfiles(
      startsInside,
      exceptProfile: exceptProfile,
    );
    List<IntakeEntity> entriesWhere(bool? exportEnabled) => [
      for (final profile in profiles)
        if (profile.exportEnabled == exportEnabled)
          ...profile.intakes.map(IntakeEntity.fromIntakeDBO),
    ];
    return ExportWindowSnapshot(
      exported: entriesWhere(true),
      optedOut: entriesWhere(false),
    );
  }
}
