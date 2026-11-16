import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;

  DeleteWeightLogUsecase(this._weightLogRepository, this._userRepository);

  /// Deletes the stored row [entry] was read from: the one filed under
  /// [WeightLogEntity.filedDay]. Its [WeightLogEntity.date] can show a
  /// neighbouring day after a time-zone change, and deleting by that would
  /// miss the row or remove the neighbour's (#1418). An entry not read from
  /// the log falls back to its date.
  ///
  /// Adding today's reading sets the user's current weight (see
  /// `AddWeightLogUsecase`), so deleting it sets the weight back to the
  /// newest reading left; otherwise the kcal goal and BMI keep a reading
  /// the log no longer has. With no reading left, the weight stays.
  Future<void> deleteEntry(WeightLogEntity entry) async {
    await _weightLogRepository.deleteEntry(entry.filedDay ?? entry.date);

    if (entry.date.toParsedDay() != DateTime.now().toParsedDay()) return;
    final left = await _weightLogRepository.getAllEntries();
    if (left.isEmpty) return;
    final newest = left.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final user = await _userRepository.getUserData();
    user.weightKG = newest.weightKg;
    await _userRepository.updateUserData(user);
  }
}
