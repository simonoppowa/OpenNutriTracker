// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfigDBOAdapter extends TypeAdapter<ConfigDBO> {
  @override
  final typeId = 13;

  @override
  ConfigDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfigDBO(
        fields[0] as bool,
        fields[1] as bool,
        fields[2] as bool,
        fields[3] as AppThemeDBO,
        usesImperialUnits: fields[4] == null ? false : fields[4] as bool?,
        userKcalAdjustment: (fields[5] as num?)?.toDouble(),
        showActivityTracking: fields[9] as bool?,
        showMealMacros: fields[14] as bool?,
        notificationsEnabled: fields[10] as bool?,
        notificationHour: (fields[11] as num?)?.toInt(),
        notificationMinute: (fields[12] as num?)?.toInt(),
        selectedLocale: fields[13] as String?,
        showMicronutrients: fields[15] as bool?,
        usesKilojoules: fields[16] as bool?,
        mealKcalSharesPct: (fields[17] as Map?)?.cast<String, int>(),
        customMealFormMode: fields[18] as String?,
        dayStartOffsetHours: (fields[19] as num?)?.toInt(),
        diarySortPreferences: (fields[21] as Map?)?.cast<String, int>(),
        nutrientPanelVisibility: (fields[22] as Map?)?.cast<String, bool>(),
        dayStartOffsetMinutes: (fields[23] as num?)?.toInt(),
        dailyWaterGoalMl: (fields[24] as num?)?.toInt(),
        fastingWarningAcknowledged: fields[25] as bool?,
        useMaterialYou: fields[20] as bool?,
        accentColor: (fields[26] as num?)?.toInt(),
        scannerPortraitLock: fields[27] as bool?,
        usesImperialFoodUnits: fields[28] as bool?,
        usesImperialHeightUnits: fields[29] as bool?,
        bodyWeightUnitIndex: (fields[30] as num?)?.toInt(),
        foodSourceToggles: (fields[31] as Map?)?.cast<String, bool>(),
        isDemoData: fields[32] as bool?,
        healthImportEnabled: fields[33] as bool?,
        healthWorkoutKcalMultiplier: (fields[34] as num?)?.toDouble(),
        healthLastImportAt: fields[35] as DateTime?,
        healthDeletedExternalIds: (fields[36] as List?)?.cast<String>(),
        policyNoticeRevisionSeen: (fields[37] as num?)?.toInt(),
        healthDeletedWorkouts: (fields[38] as Map?)?.cast<String, DateTime>(),
        defaultToRawFoodUnits: fields[39] as bool?,
        lastBackupAt: fields[100] as DateTime?,
        backupReminderDays: (fields[101] as num?)?.toInt(),
        confirmedStoreBarcodes: (fields[102] as List?)?.cast<String>(),
        waterQuickAmountMl: (fields[103] as num?)?.toInt(),
        kcalGoalMode: fields[104] as String?,
        fixedKcalGoal: (fields[105] as num?)?.toDouble(),
        macroGoalMode: fields[106] as String?,
        carbGoalG: (fields[107] as num?)?.toDouble(),
        fatGoalG: (fields[108] as num?)?.toDouble(),
        proteinGoalG: (fields[109] as num?)?.toDouble(),
        trainingGoalTargets: (fields[110] as Map?)?.cast<String, dynamic>(),
        trainingWeekdays: (fields[111] as List?)?.cast<int>(),
        dayTypeOverrides: (fields[112] as Map?)?.cast<String, String>(),
        autoTrainingDayMode: fields[113] as String?,
        offSearchCountry: fields[114] as String?,
        nutrientReferenceStandard: fields[115] as String?,
        trendsTolerancePercent: (fields[116] as num?)?.toInt(),
        trendsDeficitThresholdPercent: (fields[117] as num?)?.toInt(),
        remindersJson: fields[118] as String?,
      )
      ..userCarbGoalPct = (fields[6] as num?)?.toDouble()
      ..userProteinGoalPct = (fields[7] as num?)?.toDouble()
      ..userFatGoalPct = (fields[8] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, ConfigDBO obj) {
    writer
      ..writeByte(59)
      ..writeByte(0)
      ..write(obj.hasAcceptedDisclaimer)
      ..writeByte(1)
      ..write(obj.hasAcceptedPolicy)
      ..writeByte(2)
      ..write(obj.hasAcceptedSendAnonymousData)
      ..writeByte(3)
      ..write(obj.selectedAppTheme)
      ..writeByte(4)
      ..write(obj.usesImperialUnits)
      ..writeByte(5)
      ..write(obj.userKcalAdjustment)
      ..writeByte(6)
      ..write(obj.userCarbGoalPct)
      ..writeByte(7)
      ..write(obj.userProteinGoalPct)
      ..writeByte(8)
      ..write(obj.userFatGoalPct)
      ..writeByte(9)
      ..write(obj.showActivityTracking)
      ..writeByte(10)
      ..write(obj.notificationsEnabled)
      ..writeByte(11)
      ..write(obj.notificationHour)
      ..writeByte(12)
      ..write(obj.notificationMinute)
      ..writeByte(13)
      ..write(obj.selectedLocale)
      ..writeByte(14)
      ..write(obj.showMealMacros)
      ..writeByte(15)
      ..write(obj.showMicronutrients)
      ..writeByte(16)
      ..write(obj.usesKilojoules)
      ..writeByte(17)
      ..write(obj.mealKcalSharesPct)
      ..writeByte(18)
      ..write(obj.customMealFormMode)
      ..writeByte(19)
      ..write(obj.dayStartOffsetHours)
      ..writeByte(20)
      ..write(obj.useMaterialYou)
      ..writeByte(21)
      ..write(obj.diarySortPreferences)
      ..writeByte(22)
      ..write(obj.nutrientPanelVisibility)
      ..writeByte(23)
      ..write(obj.dayStartOffsetMinutes)
      ..writeByte(24)
      ..write(obj.dailyWaterGoalMl)
      ..writeByte(25)
      ..write(obj.fastingWarningAcknowledged)
      ..writeByte(26)
      ..write(obj.accentColor)
      ..writeByte(27)
      ..write(obj.scannerPortraitLock)
      ..writeByte(28)
      ..write(obj.usesImperialFoodUnits)
      ..writeByte(29)
      ..write(obj.usesImperialHeightUnits)
      ..writeByte(30)
      ..write(obj.bodyWeightUnitIndex)
      ..writeByte(31)
      ..write(obj.foodSourceToggles)
      ..writeByte(32)
      ..write(obj.isDemoData)
      ..writeByte(33)
      ..write(obj.healthImportEnabled)
      ..writeByte(34)
      ..write(obj.healthWorkoutKcalMultiplier)
      ..writeByte(35)
      ..write(obj.healthLastImportAt)
      ..writeByte(36)
      ..write(obj.healthDeletedExternalIds)
      ..writeByte(37)
      ..write(obj.policyNoticeRevisionSeen)
      ..writeByte(38)
      ..write(obj.healthDeletedWorkouts)
      ..writeByte(39)
      ..write(obj.defaultToRawFoodUnits)
      ..writeByte(100)
      ..write(obj.lastBackupAt)
      ..writeByte(101)
      ..write(obj.backupReminderDays)
      ..writeByte(102)
      ..write(obj.confirmedStoreBarcodes)
      ..writeByte(103)
      ..write(obj.waterQuickAmountMl)
      ..writeByte(104)
      ..write(obj.kcalGoalMode)
      ..writeByte(105)
      ..write(obj.fixedKcalGoal)
      ..writeByte(106)
      ..write(obj.macroGoalMode)
      ..writeByte(107)
      ..write(obj.carbGoalG)
      ..writeByte(108)
      ..write(obj.fatGoalG)
      ..writeByte(109)
      ..write(obj.proteinGoalG)
      ..writeByte(110)
      ..write(obj.trainingGoalTargets)
      ..writeByte(111)
      ..write(obj.trainingWeekdays)
      ..writeByte(112)
      ..write(obj.dayTypeOverrides)
      ..writeByte(113)
      ..write(obj.autoTrainingDayMode)
      ..writeByte(114)
      ..write(obj.offSearchCountry)
      ..writeByte(115)
      ..write(obj.nutrientReferenceStandard)
      ..writeByte(116)
      ..write(obj.trendsTolerancePercent)
      ..writeByte(117)
      ..write(obj.trendsDeficitThresholdPercent)
      ..writeByte(118)
      ..write(obj.remindersJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigDBO _$ConfigDBOFromJson(Map<String, dynamic> json) =>
    ConfigDBO(
        json['hasAcceptedDisclaimer'] as bool,
        json['hasAcceptedPolicy'] as bool,
        json['hasAcceptedSendAnonymousData'] as bool,
        $enumDecode(_$AppThemeDBOEnumMap, json['selectedAppTheme']),
        usesImperialUnits: json['usesImperialUnits'] as bool? ?? false,
        userKcalAdjustment: (json['userKcalAdjustment'] as num?)?.toDouble(),
        showActivityTracking: json['showActivityTracking'] as bool?,
        showMealMacros: json['showMealMacros'] as bool?,
        notificationsEnabled: json['notificationsEnabled'] as bool?,
        notificationHour: (json['notificationHour'] as num?)?.toInt(),
        notificationMinute: (json['notificationMinute'] as num?)?.toInt(),
        selectedLocale: json['selectedLocale'] as String?,
        showMicronutrients: json['showMicronutrients'] as bool?,
        usesKilojoules: json['usesKilojoules'] as bool?,
        mealKcalSharesPct: (json['mealKcalSharesPct'] as Map<String, dynamic>?)
            ?.map((k, e) => MapEntry(k, (e as num).toInt())),
        customMealFormMode: json['customMealFormMode'] as String?,
        dayStartOffsetHours: (json['dayStartOffsetHours'] as num?)?.toInt(),
        diarySortPreferences:
            (json['diarySortPreferences'] as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, (e as num).toInt()),
            ),
        nutrientPanelVisibility:
            (json['nutrientPanelVisibility'] as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as bool),
            ),
        dayStartOffsetMinutes: (json['dayStartOffsetMinutes'] as num?)?.toInt(),
        dailyWaterGoalMl: (json['dailyWaterGoalMl'] as num?)?.toInt(),
        fastingWarningAcknowledged: json['fastingWarningAcknowledged'] as bool?,
        useMaterialYou: json['useMaterialYou'] as bool?,
        accentColor: (json['accentColor'] as num?)?.toInt(),
        scannerPortraitLock: json['scannerPortraitLock'] as bool?,
        usesImperialFoodUnits: json['usesImperialFoodUnits'] as bool?,
        usesImperialHeightUnits: json['usesImperialHeightUnits'] as bool?,
        bodyWeightUnitIndex: (json['bodyWeightUnitIndex'] as num?)?.toInt(),
        foodSourceToggles: (json['foodSourceToggles'] as Map<String, dynamic>?)
            ?.map((k, e) => MapEntry(k, e as bool)),
        isDemoData: json['isDemoData'] as bool?,
        healthImportEnabled: json['healthImportEnabled'] as bool?,
        healthWorkoutKcalMultiplier:
            (json['healthWorkoutKcalMultiplier'] as num?)?.toDouble(),
        healthLastImportAt: json['healthLastImportAt'] == null
            ? null
            : DateTime.parse(json['healthLastImportAt'] as String),
        healthDeletedExternalIds:
            (json['healthDeletedExternalIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList(),
        policyNoticeRevisionSeen: (json['policyNoticeRevisionSeen'] as num?)
            ?.toInt(),
        healthDeletedWorkouts:
            (json['healthDeletedWorkouts'] as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, DateTime.parse(e as String)),
            ),
        defaultToRawFoodUnits: json['defaultToRawFoodUnits'] as bool?,
        lastBackupAt: json['lastBackupAt'] == null
            ? null
            : DateTime.parse(json['lastBackupAt'] as String),
        backupReminderDays: (json['backupReminderDays'] as num?)?.toInt(),
        confirmedStoreBarcodes:
            (json['confirmedStoreBarcodes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList(),
        waterQuickAmountMl: (json['waterQuickAmountMl'] as num?)?.toInt(),
        kcalGoalMode: json['kcalGoalMode'] as String?,
        fixedKcalGoal: (json['fixedKcalGoal'] as num?)?.toDouble(),
        macroGoalMode: json['macroGoalMode'] as String?,
        carbGoalG: (json['carbGoalG'] as num?)?.toDouble(),
        fatGoalG: (json['fatGoalG'] as num?)?.toDouble(),
        proteinGoalG: (json['proteinGoalG'] as num?)?.toDouble(),
        trainingGoalTargets:
            json['trainingGoalTargets'] as Map<String, dynamic>?,
        trainingWeekdays: (json['trainingWeekdays'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        dayTypeOverrides: (json['dayTypeOverrides'] as Map<String, dynamic>?)
            ?.map((k, e) => MapEntry(k, e as String)),
        autoTrainingDayMode: json['autoTrainingDayMode'] as String?,
        offSearchCountry: json['offSearchCountry'] as String?,
        nutrientReferenceStandard: json['nutrientReferenceStandard'] as String?,
        trendsTolerancePercent: (json['trendsTolerancePercent'] as num?)
            ?.toInt(),
        trendsDeficitThresholdPercent:
            (json['trendsDeficitThresholdPercent'] as num?)?.toInt(),
        remindersJson: json['remindersJson'] as String?,
      )
      ..userCarbGoalPct = (json['userCarbGoalPct'] as num?)?.toDouble()
      ..userProteinGoalPct = (json['userProteinGoalPct'] as num?)?.toDouble()
      ..userFatGoalPct = (json['userFatGoalPct'] as num?)?.toDouble();

Map<String, dynamic> _$ConfigDBOToJson(ConfigDBO instance) => <String, dynamic>{
  'hasAcceptedDisclaimer': instance.hasAcceptedDisclaimer,
  'hasAcceptedPolicy': instance.hasAcceptedPolicy,
  'hasAcceptedSendAnonymousData': instance.hasAcceptedSendAnonymousData,
  'selectedAppTheme': _$AppThemeDBOEnumMap[instance.selectedAppTheme]!,
  'usesImperialUnits': instance.usesImperialUnits,
  'userKcalAdjustment': instance.userKcalAdjustment,
  'userCarbGoalPct': instance.userCarbGoalPct,
  'userProteinGoalPct': instance.userProteinGoalPct,
  'userFatGoalPct': instance.userFatGoalPct,
  'showActivityTracking': instance.showActivityTracking,
  'notificationsEnabled': instance.notificationsEnabled,
  'notificationHour': instance.notificationHour,
  'notificationMinute': instance.notificationMinute,
  'selectedLocale': instance.selectedLocale,
  'showMealMacros': instance.showMealMacros,
  'showMicronutrients': instance.showMicronutrients,
  'usesKilojoules': instance.usesKilojoules,
  'mealKcalSharesPct': instance.mealKcalSharesPct,
  'customMealFormMode': instance.customMealFormMode,
  'dayStartOffsetHours': instance.dayStartOffsetHours,
  'nutrientPanelVisibility': instance.nutrientPanelVisibility,
  'diarySortPreferences': instance.diarySortPreferences,
  'dayStartOffsetMinutes': instance.dayStartOffsetMinutes,
  'dailyWaterGoalMl': instance.dailyWaterGoalMl,
  'fastingWarningAcknowledged': instance.fastingWarningAcknowledged,
  'useMaterialYou': instance.useMaterialYou,
  'accentColor': instance.accentColor,
  'scannerPortraitLock': instance.scannerPortraitLock,
  'usesImperialFoodUnits': instance.usesImperialFoodUnits,
  'usesImperialHeightUnits': instance.usesImperialHeightUnits,
  'bodyWeightUnitIndex': instance.bodyWeightUnitIndex,
  'foodSourceToggles': instance.foodSourceToggles,
  'isDemoData': instance.isDemoData,
  'healthImportEnabled': instance.healthImportEnabled,
  'healthWorkoutKcalMultiplier': instance.healthWorkoutKcalMultiplier,
  'healthLastImportAt': instance.healthLastImportAt?.toIso8601String(),
  'healthDeletedExternalIds': instance.healthDeletedExternalIds,
  'healthDeletedWorkouts': instance.healthDeletedWorkouts?.map(
    (k, e) => MapEntry(k, e.toIso8601String()),
  ),
  'policyNoticeRevisionSeen': instance.policyNoticeRevisionSeen,
  'defaultToRawFoodUnits': instance.defaultToRawFoodUnits,
  'lastBackupAt': instance.lastBackupAt?.toIso8601String(),
  'backupReminderDays': instance.backupReminderDays,
  'confirmedStoreBarcodes': instance.confirmedStoreBarcodes,
  'waterQuickAmountMl': instance.waterQuickAmountMl,
  'kcalGoalMode': instance.kcalGoalMode,
  'fixedKcalGoal': instance.fixedKcalGoal,
  'macroGoalMode': instance.macroGoalMode,
  'carbGoalG': instance.carbGoalG,
  'fatGoalG': instance.fatGoalG,
  'proteinGoalG': instance.proteinGoalG,
  'trainingGoalTargets': instance.trainingGoalTargets,
  'trainingWeekdays': instance.trainingWeekdays,
  'dayTypeOverrides': instance.dayTypeOverrides,
  'autoTrainingDayMode': instance.autoTrainingDayMode,
  'offSearchCountry': instance.offSearchCountry,
  'nutrientReferenceStandard': instance.nutrientReferenceStandard,
  'trendsTolerancePercent': instance.trendsTolerancePercent,
  'trendsDeficitThresholdPercent': instance.trendsDeficitThresholdPercent,
  'remindersJson': instance.remindersJson,
};

const _$AppThemeDBOEnumMap = {
  AppThemeDBO.light: 'light',
  AppThemeDBO.dark: 'dark',
  AppThemeDBO.system: 'system',
};
