import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/data_source/health/health_export_diary_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

/// A record the health store holds for one profile's diary entry, as the
/// export ledger tells it.
class LedgerRecord {
  final String profileId;
  final String intakeId;

  /// When the stored record starts: where HealthKit finds it.
  final DateTime exportedAt;

  /// The entry as the diary has it now, or null once it was deleted and
  /// only the record is left.
  final IntakeEntity? current;

  /// Whether [profileId] exports meals now.
  final bool consenting;

  const LedgerRecord({
    required this.profileId,
    required this.intakeId,
    required this.exportedAt,
    required this.current,
    required this.consenting,
  });

  /// Where the entry's record starts when written now: its time, to the
  /// millisecond the store and the ledger keep.
  DateTime get currentStart =>
      ExternalMealIntake.recordStart(current!.dateTime);

  /// The record with its entry written again at the entry's own time.
  LedgerRecord rewritten() => LedgerRecord(
    profileId: profileId,
    intakeId: intakeId,
    exportedAt: currentStart,
    current: current,
    consenting: consenting,
  );
}

/// The diary side of the meal export: which profile is active, whether a
/// profile exports, and the export ledger — what the store holds, and where.
class HealthExportDiaryRepository {
  final HealthExportDiaryDataSource _dataSource;

  HealthExportDiaryRepository(this._dataSource);

  String get activeProfileId => _dataSource.activeProfileId;

  /// For the active profile the stored value is read when this is called,
  /// before the returned future completes.
  Future<bool> isExportEnabled(String profileId) async =>
      await _dataSource.exportEnabledFor(profileId) ?? false;

  /// [profileId]'s whole ledger: intake id to record start. Empty when the
  /// profile is not registered.
  Future<Map<String, DateTime>> ledgerOf(String profileId) async =>
      _times(await _dataSource.readLedger(profileId) ?? const {});

  /// Where the store holds [intakeIds]' records, for those it holds.
  Future<Map<String, DateTime>> exportedAt(
    String profileId,
    Iterable<String> intakeIds,
  ) async => _times(await _dataSource.ledgerRecordsOf(profileId, intakeIds));

  Future<void> updateLedger(
    String profileId, {
    Map<String, DateTime> put = const {},
    Set<String> remove = const {},
  }) => _dataSource.updateLedger(
    profileId,
    put: {
      for (final MapEntry(:key, :value) in put.entries)
        key: value.millisecondsSinceEpoch,
    },
    remove: remove,
  );

  Future<void> clearLedger(String profileId) =>
      _dataSource.clearLedger(profileId);

  /// [profileId]'s diary entry [intakeId], or null when it is gone.
  Future<IntakeEntity?> intakeOf(String profileId, String intakeId) async {
    final row = await _dataSource.readIntake(profileId, intakeId);
    return row == null ? null : IntakeEntity.fromIntakeDBO(row);
  }

  /// Every profile's ledger records starting in any window
  /// `[start, start + length)`, skipping [exceptProfile]. Throws when a
  /// profile switch interferes.
  Future<List<LedgerRecord>> recordsInWindows(
    Set<DateTime> starts,
    Duration length, {
    String? exceptProfile,
  }) async {
    bool inside(DateTime time) => starts.any(
      (start) => !time.isBefore(start) && time.isBefore(start.add(length)),
    );
    final profiles = await _dataSource.readWindowRecords(
      inside,
      exceptProfile: exceptProfile,
    );
    return [
      for (final profile in profiles)
        for (final MapEntry(key: id, value: at) in profile.exportedAt.entries)
          LedgerRecord(
            profileId: profile.profileId,
            intakeId: id,
            exportedAt: DateTime.fromMillisecondsSinceEpoch(at),
            current: switch (profile.rows[id]) {
              final row? => IntakeEntity.fromIntakeDBO(row),
              null => null,
            },
            consenting: profile.exportEnabled == true,
          ),
    ];
  }

  static Map<String, DateTime> _times(Map<String, int> millis) => {
    for (final MapEntry(:key, :value) in millis.entries)
      key: DateTime.fromMillisecondsSinceEpoch(value),
  };
}
