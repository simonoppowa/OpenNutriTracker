import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/switch_profile_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

class DeleteProfileUsecase {
  final ProfileRepository _profileRepository;
  final HiveDBProvider _hiveDBProvider;
  final SwitchProfileUsecase _switchProfileUsecase;
  final ExportMealIntakeUsecase? _exportMealIntakeUsecase;

  DeleteProfileUsecase(
    this._profileRepository,
    this._hiveDBProvider,
    this._switchProfileUsecase, [
    this._exportMealIntakeUsecase,
  ]);

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

    // Read before anything moves: the meals this profile exported are
    // addressed by the diary its box-set is about to take with it. Never
    // throws; the deletions are queued and finish in the background.
    //
    // Read under the diary writers' lock, and held through the switch away:
    // a write still under way finishes, and requests its export, before the
    // read accounts for it, and one queued behind is dropped by the switch
    // rather than writing to the profile after the read. Held until the
    // profile is gone, too: a copy into it from another profile has no
    // switch to drop it, and must not write to it between the read and the
    // deletion.
    await withTrackedDayLock(() async {
      await _exportMealIntakeUsecase?.forgetProfile(profile.id);
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
    });
  }
}
