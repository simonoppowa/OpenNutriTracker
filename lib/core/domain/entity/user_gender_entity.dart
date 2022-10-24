import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';

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
}
