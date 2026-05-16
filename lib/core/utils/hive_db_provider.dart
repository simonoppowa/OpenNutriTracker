import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/hive_registrar.g.dart';

class HiveDBProvider extends ChangeNotifier {
  static const configBoxName = 'ConfigBox';
  static const intakeBoxName = 'IntakeBox';
  static const userActivityBoxName = 'UserActivityBox';
  static const userBoxName = 'UserBox';
  static const trackedDayBoxName = 'TrackedDayBox';
  static const customMealBoxName = 'CustomMealBox';
  static const recipeBoxName = 'RecipeBox';
  static const cachedOffMealBoxName = 'CachedOffMealBox';
  // Sidecar to cachedOffMealBox: maps meal `code` -> millisSinceEpoch of
  // last "touch" (creation or user re-select). Used by the TTL sweep so
  // unused cache entries age out after 90 days.
  static const cachedOffMealTimestampsBoxName = 'CachedOffMealTimestampsBox';
  // #70 follow-up: saved Custom activity templates (name + typical kcal).
  static const customActivityTemplateBoxName = 'CustomActivityTemplateBox';
  static const weightLogBoxName = 'WeightLogBox';
  // #32: per-entry water intake log keyed by uuid; one row per sip so the
  // dialog's "undo last" can roll a single entry back without losing the
  // rest of the day.
  static const waterIntakeBoxName = 'WaterIntakeBox';
  // #84: persisted fasting sessions, one record per start. The data layer
  // intentionally keeps cancelled and completed sessions side by side with no
  // success/failure label on the record — see `FastingSessionDBO`.
  static const fastingBoxName = 'FastingBox';

  late Box<ConfigDBO> configBox;
  late Box<IntakeDBO> intakeBox;
  late Box<UserActivityDBO> userActivityBox;
  late Box<UserDBO> userBox;
  late Box<TrackedDayDBO> trackedDayBox;
  late Box<MealDBO> customMealBox;
  late Box<RecipeDBO> recipeBox;
  late Box<MealDBO> cachedOffMealBox;
  late Box<int> cachedOffMealTimestampsBox;
  late Box<CustomActivityTemplateDBO> customActivityTemplateBox;
  late Box<WeightLogDBO> weightLogBox;
  late Box<WaterIntakeDBO> waterIntakeBox;
  late Box<FastingSessionDBO> fastingBox;

  Future<void> initHiveDB(Uint8List encryptionKey) async {
    final encryptionCypher = HiveAesCipher(encryptionKey);
    await Hive.initFlutter();
    // Delegate to the generated registrar so any new DBO type added to
    // the project is registered automatically on the next `just build`.
    // Registering by hand had drifted out of sync — `CaloriesProfileDBO`
    // (#7 on UserDBO) was missing, causing every save with a non-null
    // hormone profile to throw, which the previous broken async chains
    // swallowed silently. Result: profile reset to null on app relaunch.
    Hive.registerAdapters();

    configBox = await Hive.openBox(
      configBoxName,
      encryptionCipher: encryptionCypher,
    );
    intakeBox = await Hive.openBox(
      intakeBoxName,
      encryptionCipher: encryptionCypher,
    );
    userActivityBox = await Hive.openBox(
      userActivityBoxName,
      encryptionCipher: encryptionCypher,
    );
    userBox = await Hive.openBox(
      userBoxName,
      encryptionCipher: encryptionCypher,
    );
    trackedDayBox = await Hive.openBox(
      trackedDayBoxName,
      encryptionCipher: encryptionCypher,
    );
    customMealBox = await Hive.openBox(
      customMealBoxName,
      encryptionCipher: encryptionCypher,
    );
    recipeBox = await Hive.openBox(
      recipeBoxName,
      encryptionCipher: encryptionCypher,
    );
    cachedOffMealBox = await Hive.openBox(
      cachedOffMealBoxName,
      encryptionCipher: encryptionCypher,
    );
    cachedOffMealTimestampsBox = await Hive.openBox(
      cachedOffMealTimestampsBoxName,
      encryptionCipher: encryptionCypher,
    );
    customActivityTemplateBox = await Hive.openBox(
      customActivityTemplateBoxName,
      encryptionCipher: encryptionCypher,
    );
    weightLogBox = await Hive.openBox(
      weightLogBoxName,
      encryptionCipher: encryptionCypher,
    );
    waterIntakeBox = await Hive.openBox(
      waterIntakeBoxName,
      encryptionCipher: encryptionCypher,
    );
    fastingBox = await Hive.openBox(
      fastingBoxName,
      encryptionCipher: encryptionCypher,
    );
  }

  static List<int> generateNewHiveEncryptionKey() => Hive.generateSecureKey();
}
