import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import 'package:opennutritracker/core/data/dbo/backup_info_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class BackupInfoDataSource {
  static const _backupInfoKey = "BackupInfoKey";

  final _log = Logger('BackupInfoDataSource');
  final HiveDBProvider _hiveDBProvider;

  BackupInfoDataSource(this._hiveDBProvider);

  LazyBox<BackupInfoDBO> get _backupInfoBox => _hiveDBProvider.backupInfoBox;

  Future<bool> backupInfoInitialized() async =>
      _backupInfoBox.containsKey(_backupInfoKey);

  Future<void> initializeBackupInfo() async =>
      _backupInfoBox.put(_backupInfoKey, BackupInfoDBO.empty());

  Future<void> addBackupInfo(BackupInfoDBO backupInfoDBO) async {
    _log.fine('Adding new backup info item to db');
    _backupInfoBox.put(_backupInfoKey, backupInfoDBO);
  }

  Future<BackupInfoDBO> getBackupInfo() async {
    return await _backupInfoBox.get(_backupInfoKey) ?? BackupInfoDBO.empty();
  }

  Future<void> setLastBackupTimestamp(DateTime? timestamp) async {
    _log.fine('Updating lastBackupTimestamp to $timestamp');
    final backupInfo = await _backupInfoBox.get(_backupInfoKey);
    backupInfo?.lastBackupTimestamp = timestamp;
    await backupInfo?.save();
  }

  Future<void> reloadBackupInfo() async {
    _log.fine('Reloading backup info box from disk');
    await _hiveDBProvider.reloadBackupInfoBox();
  }

  Future<void> updateBackupInfo(BackupInfoDBO backupInfoDBO) async {
    _log.fine('Updating backup info');
    await _backupInfoBox.put(_backupInfoKey, backupInfoDBO);
    await backupInfoDBO.save();
  }
}