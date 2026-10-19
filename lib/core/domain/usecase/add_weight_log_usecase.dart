import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/weight_log_profile_sync.dart';

/// Records a weight reading for a particular day in the historical log.
///
/// The user's current weight on [UserDBO] (BMI on the profile, the kcal
/// goal calculator) follows the latest entry of the log (#42): a new or
/// edited latest entry, backdated or not, sets it; an older one leaves it
/// alone. [onProfileWeightChanged] runs when it changed.
class AddWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;
  final ProfileWeightChanged? _onProfileWeightChanged;

  AddWeightLogUsecase(
    this._weightLogRepository,
    this._userRepository, {
    ProfileWeightChanged? onProfileWeightChanged,
  }) : _onProfileWeightChanged = onProfileWeightChanged;

  Future<void> addEntry(WeightLogEntity entry) async {
    await _weightLogRepository.addEntry(entry);
    await syncProfileWeightWithLog(
      _weightLogRepository,
      _userRepository,
      _onProfileWeightChanged,
    );
  }
}
