import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';

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
}
