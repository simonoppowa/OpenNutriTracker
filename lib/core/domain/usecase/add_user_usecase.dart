import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';

class AddUserUsecase {
  final UserRepository _userRepository;

  AddUserUsecase(this._userRepository);

  Future<void> addUser(BuildContext context, UserEntity userEntity) async {
    return await _userRepository.updateUserData(userEntity);
  }
}
