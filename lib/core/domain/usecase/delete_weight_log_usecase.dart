import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final ConfigRepository _configRepository;
  final UserRepository _userRepository;

  DeleteWeightLogUsecase(
    this._weightLogRepository,
    this._configRepository,
    this._userRepository,
  );

  /// Deletes the stored row [entry] was read from, in the profile active at
  /// the call: the one filed under [WeightLogEntity.filedDay]. Its
  /// [WeightLogEntity.date] can show a neighbouring day after a time-zone
  /// change, and deleting by that would miss the row or remove the
  /// neighbour's (#1418). An entry not read from the log falls back to its
  /// date.
  ///
  /// Every repository below resolves its box from whichever profile is
  /// active when it is called, so the whole deletion runs under the lock a
  /// profile switch takes: a switch requested meanwhile waits for it, and a
  /// deletion queued behind a switch is dropped rather than applied to the
  /// profile switched to — its row, and the other profile's tombstones.
  ///
  /// Returns whether the user's current weight changed, in which case the
  /// caller runs the refresh a weight change sets off.
  Future<bool> deleteEntry(WeightLogEntity entry) async {
    final filedDay = entry.filedDay ?? entry.date;
    final changed = await withTrackedDayLockOnProfile(
      () => _deleteEntry(filedDay),
      startedOn: ProfileStamp.now(),
    );
    return changed ?? false;
  }

  /// Reads the row filed under [filedDay] again under the lock, so the
  /// tombstones and the current-weight hand-over follow what is stored, not
  /// the copy the caller showed.
  Future<bool> _deleteEntry(DateTime filedDay) async {
    final entry = await _weightLogRepository.getEntry(filedDay);
    final externalId = entry?.externalId;
    if (externalId != null) {
      // The weight import re-reads the day before its watermark, so a
      // deleted imported reading would come straight back. It shares the
      // workout import's tombstones: both are keyed by platform record id,
      // and both are pruned against the same backfill floor.
      //
      // Dated at the end of the entry's day. The entry only keeps the day,
      // and the reading happened somewhere inside it, so the day's end is
      // the latest the reading could be — the date that keeps the tombstone
      // for at least as long as the reading can still be returned.
      //
      // Stored before the row is removed: an import running at the same
      // time checks the tombstones right before it writes, and must not
      // find the day empty while the tombstone is still missing.
      final day = entry!.date;
      final endOfDay = DateTime(day.year, day.month, day.day + 1);
      await _configRepository.addConfigHealthDeletedWorkout(
        externalId,
        endOfDay,
      );
      // The id alone is not enough: the entry holds only the day's newest
      // reading, and if that one also leaves the health store, the next read
      // returns an earlier one from the same day. The day's cutoff keeps
      // every reading up to the deleted one out, and lets a newer one in.
      // An entry filed before readings carried their time blocks the whole
      // day instead, which errs toward keeping the deletion.
      await _configRepository.addConfigHealthDeletedWorkout(
        ConfigEntity.deletedWeightDayKey(day),
        entry.measuredAt ?? endOfDay,
      );
    }
    await _weightLogRepository.deleteEntry(filedDay);
    if (entry == null || !entry.isImported) return false;
    return _replaceDeletedCurrentWeight(entry);
  }

  /// The health weight import makes its newest entry the current weight.
  /// Deleting that entry has to take its weight back with it, or BMI and the
  /// calorie goal keep using a reading the user removed — and with no other
  /// imported entry left, no later import would correct them. The newest
  /// remaining entry, manual or imported, takes its place; with none left
  /// the current weight stays as it is.
  ///
  /// Only an imported entry that [WeightLogEntity.newestOf] picks — the
  /// ordering the import promotes by — and whose weight is the current one
  /// counts as having set it. Deleting a manual entry leaves the current
  /// weight alone, as it always has.
  Future<bool> _replaceDeletedCurrentWeight(WeightLogEntity deleted) async {
    if (!await _userRepository.hasUserData()) return false;
    final remaining = await _weightLogRepository.getAllEntries();
    if (WeightLogEntity.newestOf([...remaining, deleted]) != deleted) {
      return false;
    }
    final user = await _userRepository.getUserData();
    if (user.weightKG != deleted.weightKg) return false;
    final newest = WeightLogEntity.newestOf(remaining);
    if (newest == null || newest.weightKg == user.weightKG) return false;
    user.weightKG = newest.weightKg;
    await _userRepository.updateUserData(user);
    return true;
  }
}
