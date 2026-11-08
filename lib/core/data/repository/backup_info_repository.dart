import 'package:opennutritracker/core/data/data_source/backup_info_data_source.dart';
import 'package:opennutritracker/core/data/dbo/backup_info_dbo.dart';
import 'package:opennutritracker/core/domain/entity/backup_info_entity.dart';

class BackupInfoRepository {
  final BackupInfoDataSource _backupInfoDataSource;

  BackupInfoRepository(this._backupInfoDataSource);

  Future<BackupInfoDBO> getBackupInfoDBO() async {
    return await _backupInfoDataSource.getBackupInfo();
  }

  Future<BackupInfoEntity> getBackupInfo() async {
    final backupInfoDBO = await _backupInfoDataSource.getBackupInfo();
    return BackupInfoEntity.fromBackupInfoDBO(backupInfoDBO);
  }

  Future<void> setLastBackupTimestamp(DateTime? timestamp) async {
    await _backupInfoDataSource.setLastBackupTimestamp(timestamp);
  }

  Future<void> reloadBackupInfo() async {
    await _backupInfoDataSource.reloadBackupInfo();
  }

  Future<void> updateBackupInfo(BackupInfoDBO backupInfoDBO) async {
    await _backupInfoDataSource.updateBackupInfo(backupInfoDBO);
  }
}