import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final ConfigRepository _configRepository;

  DeleteWeightLogUsecase(this._weightLogRepository, this._configRepository);

  Future<void> deleteEntry(DateTime date) async {
    final entry = await _weightLogRepository.getEntry(date);
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
    await _weightLogRepository.deleteEntry(date);
  }
}
