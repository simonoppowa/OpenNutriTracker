import 'package:opennutritracker/core/data/repository/backup_info_repository.dart';

class SetBackupInfoUsecase {
  final BackupInfoRepository _backupInfoRepository;

  SetBackupInfoUsecase(this._backupInfoRepository);

  Future<void> setLastBackupTimestamp(DateTime? timestamp) async {
    await _backupInfoRepository.setLastBackupTimestamp(timestamp);
  }
}