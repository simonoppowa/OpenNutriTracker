import 'package:opennutritracker/core/data/data_source/profile_data_source.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';

class ProfileRepository {
  final ProfileDataSource _profileDataSource;

  ProfileRepository(this._profileDataSource);

  List<ProfileEntity> getAllProfiles() => _profileDataSource
      .getAllProfiles()
      .map(ProfileEntity.fromProfileDBO)
      .toList();

  ProfileEntity? getProfile(String id) {
    final dbo = _profileDataSource.getProfile(id);
    return dbo == null ? null : ProfileEntity.fromProfileDBO(dbo);
  }

  Future<void> saveProfile(ProfileEntity profile) async {
    await _profileDataSource.saveProfile(ProfileDBO.fromProfileEntity(profile));
  }

  Future<void> deleteProfile(String id) async {
    await _profileDataSource.deleteProfile(id);
  }
}
