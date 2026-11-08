import 'package:hive_flutter/hive_flutter.dart';

part 'backup_info_dbo.g.dart';

@HiveType(typeId: 16)
class BackupInfoDBO extends HiveObject {
  @HiveField(0)
  DateTime? lastBackupTimestamp;

  BackupInfoDBO({this.lastBackupTimestamp});

  factory BackupInfoDBO.empty() => BackupInfoDBO();
}