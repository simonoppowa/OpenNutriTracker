import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/usecase/weight_log_profile_sync.dart';

/// Deletes a weight reading; when it was the latest, the profile weight
/// moves to the one before (#42, [syncProfileWeightWithLog]).
class DeleteWeightLogUsecase {
  final WeightLogRepository _weightLogRepository;
  final UserRepository _userRepository;
  final ProfileWeightChanged? _onProfileWeightChanged;

  DeleteWeightLogUsecase(
    this._weightLogRepository,
    this._userRepository, {
    ProfileWeightChanged? onProfileWeightChanged,
  }) : _onProfileWeightChanged = onProfileWeightChanged;

  Future<void> deleteEntry(DateTime date) async {
    await _weightLogRepository.deleteEntry(date);
    await syncProfileWeightWithLog(
      _weightLogRepository,
      _userRepository,
      _onProfileWeightChanged,
    );
  }
}
