import 'package:hive_flutter/hive_flutter.dart';

part 'intake_type_dbo.g.dart';

@HiveType(typeId: 4)
enum IntakeTypeDBO {
  @HiveField(0)
  breakfast,
  @HiveField(1)
  lunch,
  @HiveField(2)
  dinner,
  @HiveField(3)
  snack
}
