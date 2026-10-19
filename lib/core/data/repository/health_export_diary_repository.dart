import 'package:opennutritracker/core/data/data_source/health/health_export_diary_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// A diary entry and the profile whose diary it is in.
class ProfileIntake {
  final String profileId;
  final IntakeEntity intake;

  const ProfileIntake(this.profileId, this.intake);
}

/// What the diaries of every profile hold in a set of export windows, as far
/// as the health store is concerned: only entries the export ledgers mark as
/// exported count. An entry logged before its profile opted in was never
/// written, and a rewrite must not write it now either.
class ExportWindowSnapshot {
  /// Exported entries of profiles that still export: what the windows
  /// should hold, each written under its own profile's opt-in.
  final List<ProfileIntake> exported;

  /// Exported entries of profiles that have stopped. Their records may be in
  /// the window, and rewriting them would export without consent, so
  /// deleting that window would lose them.
  final List<IntakeEntity> blocked;

  const ExportWindowSnapshot({required this.exported, required this.blocked});
}

/// One profile's opt-in and the diary entries it has exported.
class ProfileDiary {
  /// Null when the profile never opted in.
  final bool? exportEnabled;
  final List<IntakeEntity> exported;

  const ProfileDiary({required this.exportEnabled, required this.exported});
}

/// The diary side of the meal export: which profile is active, whether a
/// profile exports, what it has exported, and what every profile holds in a
/// window.
class HealthExportDiaryRepository {
  final HealthExportDiaryDataSource _dataSource;

  HealthExportDiaryRepository(this._dataSource);

  String get activeProfileId => _dataSource.activeProfileId;

  /// For the active profile the stored value is read when this is called,
  /// before the returned future completes.
  Future<bool> isExportEnabled(String profileId) async =>
      await _dataSource.exportEnabledFor(profileId) ?? false;

  /// [profileId]'s opt-in and exported entries, or null when it is not
  /// registered.
  Future<ProfileDiary?> readProfile(String profileId) async {
    final profile = await _dataSource.readProfile(profileId);
    if (profile == null) return null;
    return ProfileDiary(
      exportEnabled: profile.exportEnabled,
      exported: [
        for (final intake in profile.intakes)
          if (profile.exportedIds.contains(intake.id))
            IntakeEntity.fromIntakeDBO(intake),
      ],
    );
  }

  Future<Set<String>> exportedAmong(
    String profileId,
    Iterable<String> intakeIds,
  ) => _dataSource.exportedAmong(profileId, intakeIds);

  Future<void> updateLedger(
    String profileId, {
    Set<String> add = const {},
    Set<String> remove = const {},
  }) => _dataSource.updateLedger(profileId, add: add, remove: remove);

  Future<void> clearLedger(String profileId) =>
      _dataSource.clearLedger(profileId);

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
    final exported = <ProfileIntake>[];
    final blocked = <IntakeEntity>[];
    for (final profile in profiles) {
      for (final intake in profile.intakes) {
        if (!profile.exportedIds.contains(intake.id)) continue;
        final entity = IntakeEntity.fromIntakeDBO(intake);
        if (profile.exportEnabled == true) {
          exported.add(ProfileIntake(profile.profileId, entity));
        } else {
          blocked.add(entity);
        }
      }
    }
    return ExportWindowSnapshot(exported: exported, blocked: blocked);
  }
}
