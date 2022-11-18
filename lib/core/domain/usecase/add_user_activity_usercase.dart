import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:provider/provider.dart';

class AddUserActivityUsecase {
  Future<void> addUserActivity(
      BuildContext context, UserActivityEntity userActivityEntity) async {
    final userActivityRepository = Provider.of<UserActivityRepository>(context, listen: false);
    return await userActivityRepository.addUserActivity(userActivityEntity);
  }
}
