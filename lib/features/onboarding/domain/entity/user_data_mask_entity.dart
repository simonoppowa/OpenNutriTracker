import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';

class UserDataMaskEntity {
  UserGenderSelectionEntity? gender;
  CaloriesProfileEntity? caloriesProfile;
  DateTime? birthday;
  double? height;
  double? weight;
  UserActivitySelectionEntity? activity;
  UserGoalSelectionEntity? goal;

  /// Optional weight the user is working towards. Captured on the same
  /// onboarding screen as the current weight so new users don't have to
  /// dig into Profile after first-run to set it. Stored in kilograms
  /// regardless of the display unit the user picked.
  double? targetWeight;

  bool acceptDataCollection = false;

  bool usesImperialUnits = false;

  UserDataMaskEntity({
    this.gender,
    this.caloriesProfile,
    this.birthday,
    this.height,
    this.weight,
    this.activity,
    this.goal,
    this.targetWeight,
    this.acceptDataCollection = false,
    this.usesImperialUnits = false,
  });

  bool checkDataProvided() {
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

  UserEntity? toUserEntity() {
    if (!checkDataProvided()) {
      return null;
    }
    final userBirthday = birthday ?? DateTime.now(); // TODO
    final userHeight = height ?? 180;
    final userWeight = weight ?? 70;
    UserGenderEntity userGender;
    switch (gender) {
      case UserGenderSelectionEntity.genderMale:
        userGender = UserGenderEntity.male;
        break;
      case UserGenderSelectionEntity.genderFemale:
        userGender = UserGenderEntity.female;
        break;
      case UserGenderSelectionEntity.genderNonBinary:
        userGender = UserGenderEntity.nonBinary;
        break;
      case null:
        userGender = UserGenderEntity.female;
        break;
    }
    UserWeightGoalEntity userGoal;
    switch (goal) {
      case UserGoalSelectionEntity.loseWeight:
        userGoal = UserWeightGoalEntity.loseWeight;
        break;
      case UserGoalSelectionEntity.maintainWeight:
        userGoal = UserWeightGoalEntity.maintainWeight;
        break;
      case UserGoalSelectionEntity.gainWeigh:
        userGoal = UserWeightGoalEntity.gainWeight;
        break;
      case null:
        userGoal = UserWeightGoalEntity.maintainWeight;
    }
    UserPALEntity userPal;
    switch (activity) {
      case UserActivitySelectionEntity.sedentary:
        userPal = UserPALEntity.sedentary;
        break;
      case UserActivitySelectionEntity.lowActive:
        userPal = UserPALEntity.lowActive;
        break;
      case UserActivitySelectionEntity.active:
        userPal = UserPALEntity.active;
        break;
      case UserActivitySelectionEntity.veryActive:
        userPal = UserPALEntity.veryActive;
        break;
      case null:
        userPal = UserPALEntity.lowActive;
    }

    return UserEntity(
      birthday: userBirthday,
      heightCM: userHeight,
      weightKG: userWeight,
      gender: userGender,
      goal: userGoal,
      pal: userPal,
      caloriesProfile:
          userGender == UserGenderEntity.nonBinary ? caloriesProfile : null,
      targetWeightKg: targetWeight,
    );
  }
}
