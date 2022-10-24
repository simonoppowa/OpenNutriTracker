import 'package:hive/hive.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';

part 'user_gender_dbo.g.dart';

@HiveType(typeId: 6)
enum UserGenderDBO {
  @HiveField(0)
  male,
  @HiveField(1)
  female;

  factory UserGenderDBO.fromUserGenderEntity(UserGenderEntity genderEntity) {
    UserGenderDBO gender;
    switch (genderEntity) {
      case UserGenderEntity.male:
        gender = UserGenderDBO.male;
        break;
      case UserGenderEntity.female:
        gender = UserGenderDBO.female;
        break;
    }
    return gender;
  }
}
