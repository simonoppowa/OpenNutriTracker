import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';

class UpdateProfileUsecase {
  final ProfileRepository _profileRepository;

  UpdateProfileUsecase(this._profileRepository);

  Future<void> updateProfile(ProfileEntity profile) async {
    await _profileRepository.saveProfile(profile);
  }
}
