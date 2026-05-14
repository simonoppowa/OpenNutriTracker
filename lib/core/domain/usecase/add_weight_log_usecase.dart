import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

/// Records a weight reading for a particular day in the historical log.
///
/// When the entry is for today, the user's current weight on [UserDBO]
/// is updated in the same operation so the rest of the app (BMI on the
/// profile, the kcal goal calculator) stays in sync. Backdated entries
/// are stored without touching the current weight — adding "what I
/// weighed last Tuesday" should not rewrite today's value.
class AddWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;

  AddWeightLogUsecase(this._weightLogRepository, this._userRepository);

  Future<void> addEntry(WeightLogEntity entry) async {
    await _weightLogRepository.addEntry(entry);

    final today = DateTime.now().toParsedDay();
    if (entry.date.toParsedDay() == today) {
      final user = await _userRepository.getUserData();
      user.weightKG = entry.weightKg;
      await _userRepository.updateUserData(user);
    }
  }
}
