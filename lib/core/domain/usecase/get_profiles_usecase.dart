import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class GetProfilesUsecase {
  final ProfileRepository _profileRepository;
  final HiveDBProvider _hiveDBProvider;

  GetProfilesUsecase(this._profileRepository, this._hiveDBProvider);

  List<ProfileEntity> getProfiles() => _profileRepository.getAllProfiles();

  String get activeProfileId => _hiveDBProvider.activeProfileId;

  ProfileEntity? getActiveProfile() =>
      _profileRepository.getProfile(_hiveDBProvider.activeProfileId);
}
