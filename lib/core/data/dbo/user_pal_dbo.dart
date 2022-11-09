import 'package:hive/hive.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';

part 'user_pal_dbo.g.dart';

@HiveType(typeId: 8)
enum UserPALDBO {
  @HiveField(0)
  sedentary,
  @HiveField(1)
  lowActive,
  @HiveField(2)
  active,
  @HiveField(3)
  veryActive;

  factory UserPALDBO.fromUserPALEntity(UserPALEntity palEntity) {
    UserPALDBO palDBO;
    switch (palEntity) {
      case UserPALEntity.sedentary:
        palDBO = UserPALDBO.sedentary;
        break;
      case UserPALEntity.lowActive:
        palDBO = UserPALDBO.lowActive;
        break;
      case UserPALEntity.active:
        palDBO = UserPALDBO.active;
        break;
      case UserPALEntity.veryActive:
        palDBO = UserPALDBO.veryActive;
        break;
    }
    return palDBO;
  }
}
