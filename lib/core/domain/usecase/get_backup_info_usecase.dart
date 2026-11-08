import 'package:opennutritracker/core/data/repository/backup_info_repository.dart';
import 'package:opennutritracker/core/domain/entity/backup_info_entity.dart';

class GetBackupInfoUsecase {
  final BackupInfoRepository _backupInfoRepository;

  GetBackupInfoUsecase(this._backupInfoRepository);

  Future<BackupInfoEntity> getBackupInfo() async {
    return await _backupInfoRepository.getBackupInfo();
  }

  Future<void> reloadBackupInfo() async {
    await _backupInfoRepository.reloadBackupInfo();
  }
}