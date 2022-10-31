import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum UserPALEntity {
  lightActivity,
  moderateActivity,
  vigorousActivity;

  factory UserPALEntity.fromUserPALDBO(UserPALDBO palDBO) {
    UserPALEntity palEntity;
    switch (palDBO) {
      case UserPALDBO.lightActivity:
        palEntity = UserPALEntity.lightActivity;
        break;
      case UserPALDBO.moderateActivity:
        palEntity = UserPALEntity.moderateActivity;
        break;
      case UserPALDBO.vigorousActivity:
        palEntity = UserPALEntity.vigorousActivity;
        break;
    }
    return palEntity;
  }

  String getName(BuildContext context) {
    String name;
    switch (this) {
      case UserPALEntity.lightActivity:
        name = S.of(context).activityLightLabel;
        break;
      case UserPALEntity.moderateActivity:
        name = S.of(context).activityModerateLabel;
        break;
      case UserPALEntity.vigorousActivity:
        name = S.of(context).activityVigorousLabel;
        break;
    }
    return name;
  }
}
