import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final Box<IntakeDBO> intakeBox;

  IntakeDataSource(this.intakeBox);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    intakeBox.add(intakeDBO);
  }

  // TODO
  // Future<List<IntakeDBO>> getAllIntakesByDate(DateTime dateTime) async {
  //   intakeBox.values.where((intake) => ...)
  // }
}
