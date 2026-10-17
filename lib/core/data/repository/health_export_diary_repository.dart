import 'package:opennutritracker/core/data/data_source/health/health_export_diary_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// What the diaries of every profile hold in a set of export windows.
class ExportWindowSnapshot {
  /// Entries of profiles that export meals: the records the windows should
  /// hold, each written under its own profile's opt-in.
  final List<IntakeEntity> exported;

  /// Whether an entry belongs to a profile that opted out again. Such an
  /// entry may still have a record in the window, and rewriting it would
  /// export without consent, so a window delete would lose it for good.
  final bool hasOptedOutEntries;

  const ExportWindowSnapshot({
    required this.exported,
    required this.hasOptedOutEntries,
  });
}

/// The diary side of the meal export: which profile is active, whether a
/// profile exports, and what every profile holds in a window.
class HealthExportDiaryRepository {
  final HealthExportDiaryDataSource _dataSource;

  HealthExportDiaryRepository(this._dataSource);

  String get activeProfileId => _dataSource.activeProfileId;

  Future<bool> isExportEnabled(String profileId) async =>
      await _dataSource.exportEnabledFor(profileId) ?? false;

  /// Reads every profile's entries starting in any window
  /// `[start, start + length)`. Throws when a profile switch interferes.
  Future<ExportWindowSnapshot> snapshotWindows(
    Set<DateTime> starts,
    Duration length,
  ) async {
    bool startsInside(DateTime time) => starts.any(
      (start) => !time.isBefore(start) && time.isBefore(start.add(length)),
    );
    final profiles = await _dataSource.readAllProfiles(startsInside);
    return ExportWindowSnapshot(
      exported: [
        for (final profile in profiles)
          if (profile.exportEnabled == true)
            ...profile.intakes.map(IntakeEntity.fromIntakeDBO),
      ],
      hasOptedOutEntries: profiles.any(
        (profile) =>
            profile.exportEnabled == false && profile.intakes.isNotEmpty,
      ),
    );
  }
}
