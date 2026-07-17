import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

class CreateProfileUsecase {
  final ProfileRepository _profileRepository;

  CreateProfileUsecase(this._profileRepository);

  /// Creates and persists a new profile record. Does not switch to it —
  /// the caller decides when to activate the new box-set.
  Future<ProfileEntity> createProfile({
    required String name,
    String? imagePath,
  }) async {
    final id = IdGenerator.getUniqueID();
    final profile = ProfileEntity(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      // Hyphen-free so the suffix is safe as a box-name / filename segment
      // on every platform.
      boxSuffix: id.replaceAll('-', ''),
      imagePath: imagePath,
    );
    await _profileRepository.saveProfile(profile);
    return profile;
  }
}
