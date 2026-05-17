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
      )
      ..userCarbGoalPct = (fields[6] as num?)?.toDouble()
      ..userProteinGoalPct = (fields[7] as num?)?.toDouble()
      ..userFatGoalPct = (fields[8] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, ConfigDBO obj) {
    writer
      ..writeByte(27)
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
      ..write(obj.accentColor);
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
};

const _$AppThemeDBOEnumMap = {
  AppThemeDBO.light: 'light',
  AppThemeDBO.dark: 'dark',
  AppThemeDBO.system: 'system',
};
