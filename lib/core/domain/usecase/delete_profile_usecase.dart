import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/switch_profile_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

class DeleteProfileUsecase {
  final ProfileRepository _profileRepository;
  final HiveDBProvider _hiveDBProvider;
  final SwitchProfileUsecase _switchProfileUsecase;

  DeleteProfileUsecase(
    this._profileRepository,
    this._hiveDBProvider,
    this._switchProfileUsecase,
  );

  /// Removes [profile] and its entire box-set from disk.
  ///
  /// Refuses to delete the last remaining profile. If the profile being
  /// deleted is the active one, switches to another first so its boxes are
  /// closed before they are dropped — Hive cannot delete an open box.
  Future<void> deleteProfile(ProfileEntity profile) async {
    final all = _profileRepository.getAllProfiles();
    if (all.length <= 1) {
      throw StateError('Cannot delete the last remaining profile.');
    }

    if (_hiveDBProvider.activeProfileId == profile.id) {
      final fallback = all.firstWhere((p) => p.id != profile.id);
      await _switchProfileUsecase.switchProfile(fallback);
    }

    await _hiveDBProvider.deleteProfileBoxes(profile.boxSuffix);
    final imagePath = profile.imagePath;
    if (imagePath != null) {
      await UserImageStorage.delete(imagePath);
    }
    await _profileRepository.deleteProfile(profile.id);
  }
}
