import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';

enum IntakeTypeEntity {
  breakfast,
  lunch,
  dinner,
  snack;

  factory IntakeTypeEntity.fromIntakeTypeDBO(IntakeTypeDBO intakeTypeDBO) {
    IntakeTypeEntity intakeTypeEntity;
    switch (intakeTypeDBO) {
      case IntakeTypeDBO.breakfast:
        intakeTypeEntity = IntakeTypeEntity.breakfast;
        break;
      case IntakeTypeDBO.lunch:
        intakeTypeEntity = IntakeTypeEntity.lunch;
        break;
      case IntakeTypeDBO.dinner:
        intakeTypeEntity = IntakeTypeEntity.dinner;
        break;
      case IntakeTypeDBO.snack:
        intakeTypeEntity = IntakeTypeEntity.snack;
        break;
    }
    return intakeTypeEntity;
  }
}
