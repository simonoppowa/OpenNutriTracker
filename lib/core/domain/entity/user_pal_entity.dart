import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum UserPALEntity {
  sedentary,
  lowActive,
  active,
  veryActive;

  factory UserPALEntity.fromUserPALDBO(UserPALDBO palDBO) {
    UserPALEntity palEntity;
    switch (palDBO) {
      case UserPALDBO.sedentary:
        palEntity = UserPALEntity.sedentary;
        break;
      case UserPALDBO.lowActive:
        palEntity = UserPALEntity.lowActive;
        break;
      case UserPALDBO.active:
        palEntity = UserPALEntity.active;
        break;
      case UserPALDBO.veryActive:
        palEntity = UserPALEntity.veryActive;
        break;
    }
    return palEntity;
  }

  String getName(BuildContext context) {
    String name;
    switch (this) {
      case UserPALEntity.sedentary:
        name = S.of(context).palSedentaryLabel;
        break;
      case UserPALEntity.lowActive:
        name = S.of(context).palLowLActiveLabel;
        break;
      case UserPALEntity.active:
        name = S.of(context).palActiveLabel;
        break;
      case UserPALEntity.veryActive:
        name = S.of(context).palVeryActiveLabel;
        break;
    }
    return name;
  }
}
