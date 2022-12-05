import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:provider/provider.dart';

class GetUserUsecase {
  Future<UserEntity> getUserData(BuildContext context) async {
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    return await userRepository.getUserData();
  }

  Future<bool> hasUserData(BuildContext context) async {
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    return await userRepository.hasUserData();
  }
}
