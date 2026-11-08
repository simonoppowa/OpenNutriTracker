import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/backup_info_dbo.dart';

class BackupInfoEntity extends Equatable {
  final DateTime? lastBackupTimestamp;

  const BackupInfoEntity({this.lastBackupTimestamp});

  factory BackupInfoEntity.fromBackupInfoDBO(BackupInfoDBO dbo) =>
      BackupInfoEntity(lastBackupTimestamp: dbo.lastBackupTimestamp);

  @override
  List<Object?> get props => [lastBackupTimestamp];
}