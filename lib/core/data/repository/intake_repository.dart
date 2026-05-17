import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class IntakeRepository {
  final IntakeDataSource _intakeDataSource;

  IntakeRepository(this._intakeDataSource);

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    final intakeDBO = IntakeDBO.fromIntakeEntity(intakeEntity);

    await _intakeDataSource.addIntake(intakeDBO);
  }

  Future<void> addAllIntakeDBOs(List<IntakeDBO> intakeDBOs) async {
    await _intakeDataSource.addAllIntakes(intakeDBOs);
  }

  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    await _intakeDataSource.deleteIntakeFromId(intakeEntity.id);
  }

  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    var result = await _intakeDataSource.updateIntake(intakeId, fields);
    return result == null ? null : IntakeEntity.fromIntakeDBO(result);
  }

  Future<List<IntakeDBO>> getAllIntakesDBO() async {
    return await _intakeDataSource.getAllIntakes();
  }

  Future<List<IntakeEntity>> getIntakeByDateAndType(
    IntakeTypeEntity intakeType,
    DateTime date, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    final intakeDBOList = await _intakeDataSource.getAllIntakesByDate(
      IntakeTypeDBO.fromIntakeTypeEntity(intakeType),
      date,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );

    return intakeDBOList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }

  Future<List<IntakeEntity>> getRecentIntake() async {
    final intakeList = await _intakeDataSource.getRecentlyAddedIntake();

    return intakeList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }

  Future<IntakeEntity?> getIntakeById(String intakeId) async {
    final result = await _intakeDataSource.getIntakeById(intakeId);
    return result == null ? null : IntakeEntity.fromIntakeDBO(result);
  }

  Future<List<IntakeEntity>> getCustomMealIntakes() async {
    final dboList = await _intakeDataSource.getCustomMealIntakes();
    return dboList.map(IntakeEntity.fromIntakeDBO).toList();
  }

  /// Rewrites every custom-meal intake whose key (code-or-name) matches
  /// [fromMealKey] to instead snapshot [toMeal]. Returns the rewritten
  /// before/after pairs so the caller can reconcile TrackedDay totals from
  /// the macro diff per intake.
  Future<List<(IntakeEntity, IntakeEntity)>> remapCustomMealOnIntakes({
    required String fromMealKey,
    required MealDBO toMeal,
  }) async {
    final rewrites = await _intakeDataSource.remapCustomMealOnIntakes(
      fromMealKey: fromMealKey,
      toMeal: toMeal,
    );
    return rewrites
        .map((pair) => (
              IntakeEntity.fromIntakeDBO(pair.$1),
              IntakeEntity.fromIntakeDBO(pair.$2),
            ))
        .toList();
  }
}
