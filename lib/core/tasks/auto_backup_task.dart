import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:workmanager/workmanager.dart';

const autoBackupTaskKey = "com.opennutritracker.autobackuptask";

const autoBackupFileName = "opennutritracker-backup"; // Not including .zip file extension

void refreshAutoBackupTask() {
  //Workmanager().registerPeriodicTask(
  //  autoBackupTaskKey,
  //  autoBackupTaskKey,
  //  initialDelay: Duration(seconds: 10),
  //  frequency: Duration(minutes: 15),
  //);
  Workmanager().cancelByUniqueName(autoBackupTaskKey);
  Workmanager().registerOneOffTask(
    autoBackupTaskKey,
    autoBackupTaskKey,
    initialDelay: Duration(seconds: 15),
  );
}

Future<bool> autoBackupAndroid(String autoBackupLocation, bool? autoBackupOverwrite, ExportDataUsecase exportDataUsecase) async {
  final safUtil = SafUtil();
  final safStream = SafStream();

  final exportZipFileName = "$autoBackupFileName.zip";

  // Generate a new backup in its place
  final zipDataBytes = await exportDataUsecase.exportData();
  if (zipDataBytes == null) {
    if (kDebugMode) {
      debugPrint("Autobackup failed to get zip file data bytelist");
    }
    return Future.value(false);
  }
  final safFile = await safStream.writeFileBytes(autoBackupLocation, exportZipFileName, "application/octet-stream", zipDataBytes, overwrite: autoBackupOverwrite, append: false);
  final exportCreated = await safUtil.exists(safFile.uri.toString(), false);
  if (safFile.fileName != null) {
    if (kDebugMode) {
      debugPrint("Backup succeeded, path = ${safFile.uri.path}");
    }
  } else {
    if (kDebugMode) {
      debugPrint("Backup FAILED, path = ${safFile.uri.path}, exists = $exportCreated");
      return Future.value(false);
    }
  }
  return Future.value(true);
}

Future<bool> runAutoBackupTask() async {
  if (kDebugMode) {
    debugPrint("Entered runAutoBackupTask");
  }

  // Init secure storage and Hive database;
  final secureAppStorageProvider = SecureAppStorageProvider();
  final hiveDBProvider = HiveDBProvider();
  await hiveDBProvider
      .initHiveDB(await secureAppStorageProvider.getHiveEncryptionKey());

  // Init config usecase and dependencies
  final configDataStorage = ConfigDataSource(hiveDBProvider.configBox);
  final configRepository = ConfigRepository(configDataStorage);
  final getConfigUsecase = GetConfigUsecase(configRepository);

  // Init export_data_usecase and dependencies
  final userActivityDataSource = UserActivityDataSource(hiveDBProvider.userActivityBox);
  final intakeDataSource = IntakeDataSource(hiveDBProvider.intakeBox);
  final trackedDayDataSource = TrackedDayDataSource(hiveDBProvider.trackedDayBox);
  final userActivityRepo = UserActivityRepository(userActivityDataSource);
  final intakeRepo = IntakeRepository(intakeDataSource);
  final trackedDayRepo = TrackedDayRepository(trackedDayDataSource);
  final exportDataUsecase = ExportDataUsecase(userActivityRepo, intakeRepo, trackedDayRepo);

  // Get backup configuration
  final config = await getConfigUsecase.getConfig();
  final autoBackupEnabled = config.autoBackupEnabled ?? false;
  final autoBackupLocation = config.autoBackupLocation;
  final autoBackupOverwrite = config.autoBackupOverwrite;

  // Verify backup config
  if (!autoBackupEnabled) {
    if (kDebugMode) {
      debugPrint("Autobackup disabled, skipping backup...");
    }
    return Future.value(true);
  }
  if (autoBackupLocation == null) {
    if (kDebugMode) {
      debugPrint("Autobackup location is null, skipping backup...");
    }
    return Future.value(true);
  }

  if (Platform.isAndroid) {
    return autoBackupAndroid(autoBackupLocation, autoBackupOverwrite, exportDataUsecase);
  } else {
    // Other platforms are not currently supported
    if (kDebugMode) {
      debugPrint("Autobackup failed: unsupported platform");
    }
    Future.value(false);
  }

  
  return Future.value(true);
}
