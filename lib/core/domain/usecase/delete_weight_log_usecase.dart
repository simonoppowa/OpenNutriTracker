import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;

  DeleteWeightLogUsecase(this._weightLogRepository);

  /// Deletes the stored row [entry] was read from: the one filed under
  /// [WeightLogEntity.filedDay]. Its [WeightLogEntity.date] can show a
  /// neighbouring day after a time-zone change, and deleting by that would
  /// miss the row or remove the neighbour's (#1418). An entry not read from
  /// the log falls back to its date.
  Future<void> deleteEntry(WeightLogEntity entry) async {
    await _weightLogRepository.deleteEntry(entry.filedDay ?? entry.date);
  }
}
