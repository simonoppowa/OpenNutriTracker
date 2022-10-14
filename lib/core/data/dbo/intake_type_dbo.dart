import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

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
  snack;

  factory IntakeTypeDBO.fromIntakeTypeEntity(IntakeTypeEntity entityType) {
    IntakeTypeDBO intakeDBOType;
    switch (entityType) {
      case IntakeTypeEntity.breakfast:
        intakeDBOType = IntakeTypeDBO.breakfast;
        break;
      case IntakeTypeEntity.lunch:
        intakeDBOType = IntakeTypeDBO.lunch;
        break;
      case IntakeTypeEntity.dinner:
        intakeDBOType = IntakeTypeDBO.dinner;
        break;
      case IntakeTypeEntity.snack:
        intakeDBOType = IntakeTypeDBO.snack;
        break;
    }
    return intakeDBOType;
  }
}
