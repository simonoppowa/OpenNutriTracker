import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

/// Called with the user after the profile weight followed the weight log,
/// to recompute the goals and refresh the screens.
typedef ProfileWeightChanged = Future<void> Function(UserEntity user);

/// Keeps the profile weight on the latest entry of the weight log (#42),
/// which the kcal goal is calculated from. Without entries it stays as it
/// is.
Future<void> syncProfileWeightWithLog(
  WeightLogRepository weightLogRepository,
  UserRepository userRepository,
  ProfileWeightChanged? onChanged,
) async {
  final entries = await weightLogRepository.getAllEntries();
  if (entries.isEmpty) return;
  final latest = entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  final user = await userRepository.getUserData();
  if (user.weightKG == latest.weightKg) return;
  user.weightKG = latest.weightKg;
  await userRepository.updateUserData(user);
  await onChanged?.call(user);
}
