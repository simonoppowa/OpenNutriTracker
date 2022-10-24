import 'package:hive/hive.dart';

part 'user_pal_dbo.g.dart';

@HiveType(typeId: 8)
enum UserPALDBO {
  @HiveField(0)
  lightActivity,
  @HiveField(1)
  moderateActivity,
  @HiveField(2)
  vigorousActivity;
}
