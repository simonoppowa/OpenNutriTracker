import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum UserGenderEntity {
  male,
  female;

  factory UserGenderEntity.fromUserGenderDBO(UserGenderDBO genderDBO) {
    UserGenderEntity genderEntity;
    switch (genderDBO) {
      case UserGenderDBO.male:
        genderEntity = UserGenderEntity.male;
        break;
      case UserGenderDBO.female:
        genderEntity = UserGenderEntity.female;
        break;
    }
    return genderEntity;
  }

  String getName(BuildContext context) {
    String name;
    switch (this) {
      case UserGenderEntity.male:
        name = S.of(context).genderMaleLabel;
        break;
      case UserGenderEntity.female:
        name = S.of(context).genderFemaleLabel;
        break;
    }
    return name;
  }

  IconData getIcon() {
    IconData icon;
    switch (this) {
      case UserGenderEntity.male:
        icon = Icons.male_outlined;
        break;
      case UserGenderEntity.female:
        icon = Icons.female_outlined;
        break;
    }
    return icon;
  }
}
