// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfigDBOAdapter extends TypeAdapter<ConfigDBO> {
  @override
  final int typeId = 13;

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
      usesImperialUnits: fields[4] as bool?,
      userKcalAdjustment: fields[5] as double?,
    )
      ..userCarbGoalPct = fields[6] as double?
      ..userProteinGoalPct = fields[7] as double?
      ..userFatGoalPct = fields[8] as double?;
  }

  @override
  void write(BinaryWriter writer, ConfigDBO obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.userFatGoalPct);
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

ConfigDBO _$ConfigDBOFromJson(Map<String, dynamic> json) => ConfigDBO(
      json['hasAcceptedDisclaimer'] as bool,
      json['hasAcceptedPolicy'] as bool,
      json['hasAcceptedSendAnonymousData'] as bool,
      $enumDecode(_$AppThemeDBOEnumMap, json['selectedAppTheme']),
      usesImperialUnits: json['usesImperialUnits'] as bool? ?? false,
      userKcalAdjustment: (json['userKcalAdjustment'] as num?)?.toDouble(),
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
    };

const _$AppThemeDBOEnumMap = {
  AppThemeDBO.light: 'light',
  AppThemeDBO.dark: 'dark',
  AppThemeDBO.system: 'system',
};
