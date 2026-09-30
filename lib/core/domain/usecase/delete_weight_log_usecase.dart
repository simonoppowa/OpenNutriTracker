import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final ConfigRepository _configRepository;

  DeleteWeightLogUsecase(this._weightLogRepository, this._configRepository);

  Future<void> deleteEntry(DateTime date) async {
    final entry = await _weightLogRepository.getEntry(date);
    await _weightLogRepository.deleteEntry(date);
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
      final day = entry!.date;
      await _configRepository.addConfigHealthDeletedWorkout(
        externalId,
        DateTime(day.year, day.month, day.day + 1),
      );
    }
  }
}
