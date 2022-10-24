import 'package:hive/hive.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';

part 'user_pal_dbo.g.dart';

@HiveType(typeId: 8)
enum UserPALDBO {
  @HiveField(0)
  lightActivity,
  @HiveField(1)
  moderateActivity,
  @HiveField(2)
  vigorousActivity;

  factory UserPALDBO.fromUserPALEntity(UserPALEntity palEntity) {
    UserPALDBO palDBO;
    switch (palEntity) {
      case UserPALEntity.lightActivity:
        palDBO = UserPALDBO.lightActivity;
        break;
      case UserPALEntity.moderateActivity:
        palDBO = UserPALDBO.moderateActivity;
        break;
      case UserPALEntity.vigorousActivity:
        palDBO = UserPALDBO.vigorousActivity;
        break;
    }
    return palDBO;
  }
}
