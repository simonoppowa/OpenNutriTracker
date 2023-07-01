import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:provider/provider.dart';

class GetUserUsecase {
  final UserRepository userRepository;

  GetUserUsecase(this.userRepository);

  Future<UserEntity> getUserData(BuildContext context) async {
    return await userRepository.getUserData();
  }

  Future<bool> hasUserData(BuildContext context) async {
    return await userRepository.hasUserData();
  }
}
