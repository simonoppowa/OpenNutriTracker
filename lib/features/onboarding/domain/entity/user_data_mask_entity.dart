import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';

class UserDataMaskEntity {
  UserGenderSelectionEntity? gender;
  DateTime? birthday;
  double? height;
  double? weight;
  UserActivitySelectionEntity? activity;
  UserGoalSelectionEntity? goal;

  UserDataMaskEntity(
      {this.gender,
      this.birthday,
      this.height,
      this.weight,
      this.activity,
      this.goal});

  bool checkUserData() {
    if (gender != null &&
        birthday != null &&
        height != null &&
        weight != null &&
        activity != null &&
        goal != null) {
      return true;
    } else {
      return false;
    }
  }
}
