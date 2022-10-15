import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class IntakeRepository {
  final IntakeDataSource _intakeDataSource;

  IntakeRepository(this._intakeDataSource);

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    final intakeDBO = IntakeDBO.fromIntakeEntity(intakeEntity);

    _intakeDataSource.addIntake(intakeDBO);
  }

  Future<List<IntakeEntity>> getIntakeByDateAndType(
      IntakeTypeEntity intakeType, DateTime date) async {
    final intakeDBOList = await _intakeDataSource.getAllIntakesByDate(
        IntakeTypeDBO.fromIntakeTypeEntity(intakeType), date);

    return intakeDBOList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }
}
