import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:provider/provider.dart';

class DeleteUserActivityUsecase {
  Future<void> deleteUserActivity(
      BuildContext context, UserActivityEntity activityEntity) async {
    final intakeRepository =
        Provider.of<UserActivityRepository>(context, listen: false);
    await intakeRepository.deleteUserActivity(activityEntity);
  }
}
