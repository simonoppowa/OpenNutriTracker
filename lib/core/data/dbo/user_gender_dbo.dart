import 'package:hive/hive.dart';

part 'user_gender_dbo.g.dart';

@HiveType(typeId: 6)
enum UserGenderDBO {
  @HiveField(0)
  male,
  @HiveField(1)
  female;
}
