import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';

/// Records a weight reading for a particular day in the historical log.
///
/// When the entry is for today, the user's current weight on [UserDBO]
/// is updated in the same operation so the rest of the app (BMI on the
/// profile, the kcal goal calculator) stays in sync. Backdated entries
/// are stored without touching the current weight — adding "what I
/// weighed last Tuesday" should not rewrite today's value — with one
/// exception: a correction of the imported entry the current weight was
/// taken from carries the correction into the current weight.
class AddWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;

  AddWeightLogUsecase(this._weightLogRepository, this._userRepository);

  /// Runs under the tracked-day lock, which the weight import and
  /// `DeleteWeightLogUsecase` also hold while they move the current weight,
  /// so neither can restore an older weight over this one half-way through.
  Future<void> addEntry(WeightLogEntity entry) =>
      withTrackedDayLock(() => _addEntry(entry));

  Future<void> _addEntry(WeightLogEntity entry) async {
    final replaced = await _weightLogRepository.getEntry(entry.date);
    final before = await _weightLogRepository.getAllEntries();
    await _weightLogRepository.addEntry(entry);

    final today = DateTime.now().toParsedDay();
    if (entry.date.toParsedDay() == today) {
      final user = await _userRepository.getUserData();
      user.weightKG = entry.weightKg;
      await _userRepository.updateUserData(user);
      return;
    }

    // The weight import makes its newest entry the current weight, whatever
    // its day. Overwriting that entry from the weight history leaves nothing
    // that would move the current weight off the overwritten reading — the
    // import only promotes imported entries — so the correction does.
    if (replaced == null || !replaced.isImported) return;
    if (WeightLogEntity.newestOf(before) != replaced) return;
    final after = [
      for (final other in before)
        if (other != replaced) other,
      entry,
    ];
    if (WeightLogEntity.newestOf(after) != entry) return;
    if (!await _userRepository.hasUserData()) return;
    final user = await _userRepository.getUserData();
    if (user.weightKG != replaced.weightKg) return;
    if (user.weightKG == entry.weightKg) return;
    user.weightKG = entry.weightKg;
    await _userRepository.updateUserData(user);
  }
}
