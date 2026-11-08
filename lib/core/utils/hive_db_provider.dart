import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/backup_info_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';

class HiveDBProvider extends ChangeNotifier {
  static const configBoxName = 'ConfigBox';
  static const intakeBoxName = 'IntakeBox';
  static const userActivityBoxName = 'UserActivityBox';
  static const userBoxName = 'UserBox';
  static const trackedDayBoxName = 'TrackedDayBox';
  static const backupInfoBoxName = 'BackupInfoBox';

  late Box<ConfigDBO> configBox;
  late Box<IntakeDBO> intakeBox;
  late Box<UserActivityDBO> userActivityBox;
  late Box<UserDBO> userBox;
  late Box<TrackedDayDBO> trackedDayBox;
  // Backup Info is accessed by multiple isolates (the main isolate + the background
  // task worker). Therefore it must be lazy to ensure each read pulls directly from
  // persistent storage, otherwise the main app won't update until it's restarted
  late LazyBox<BackupInfoDBO> backupInfoBox;

  HiveCipher? _encryptionCypher;

  Future<void> initHiveDB(Uint8List encryptionKey) async {
    final encryptionCypher = HiveAesCipher(encryptionKey);
    _encryptionCypher = encryptionCypher;
    await Hive.initFlutter();
    Hive.registerAdapter(ConfigDBOAdapter());
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(MealDBOAdapter());
    Hive.registerAdapter(MealNutrimentsDBOAdapter());
    Hive.registerAdapter(MealSourceDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
    Hive.registerAdapter(UserDBOAdapter());
    Hive.registerAdapter(UserGenderDBOAdapter());
    Hive.registerAdapter(UserWeightGoalDBOAdapter());
    Hive.registerAdapter(UserPALDBOAdapter());
    Hive.registerAdapter(TrackedDayDBOAdapter());
    Hive.registerAdapter(UserActivityDBOAdapter());
    Hive.registerAdapter(PhysicalActivityDBOAdapter());
    Hive.registerAdapter(PhysicalActivityTypeDBOAdapter());
    Hive.registerAdapter(AppThemeDBOAdapter());
    Hive.registerAdapter(BackupInfoDBOAdapter());

    configBox =
        await Hive.openBox(configBoxName, encryptionCipher: encryptionCypher);
    intakeBox =
        await Hive.openBox(intakeBoxName, encryptionCipher: encryptionCypher);
    userActivityBox = await Hive.openBox(userActivityBoxName,
        encryptionCipher: encryptionCypher);
    userBox =
        await Hive.openBox(userBoxName, encryptionCipher: encryptionCypher);
    trackedDayBox = await Hive.openBox(trackedDayBoxName,
        encryptionCipher: encryptionCypher);
    backupInfoBox = await Hive.openLazyBox(backupInfoBoxName,
        encryptionCipher: encryptionCypher);
  }

  /// Closes and reopens the backup info box so its in-memory keystore is
  /// repopulated from disk. The background task isolate writes to this same
  /// box, so without a reopen the main app won't see those writes until restart.
  Future<void> reloadBackupInfoBox() async {
    final cypher = _encryptionCypher;
    if (cypher == null) return;
    await backupInfoBox.close();
    backupInfoBox = await Hive.openLazyBox(backupInfoBoxName,
        encryptionCipher: cypher);
  }

  static generateNewHiveEncryptionKey() => Hive.generateSecureKey();
}
