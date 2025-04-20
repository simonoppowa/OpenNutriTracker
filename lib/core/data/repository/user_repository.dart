import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class UserRepository {
  final UserDataSource _userDataSource;

  UserRepository(this._userDataSource);

  Future<void> updateUserData(UserEntity userEntity) async {
    final userDBO = UserDBO.fromUserEntity(userEntity);
    _userDataSource.saveUserData(userDBO);
  }

  Future<bool> hasUserData() async => await _userDataSource.hasUserData();

  Future<UserEntity> getUserData() async {
    final userDBO = await _userDataSource.getUserData();
    return UserEntity.fromUserDBO(userDBO);
  }

  Future<UserDBO> getUserDBO() async {
    final userDBO = await _userDataSource.getUserData();
    return userDBO;
  }
}
