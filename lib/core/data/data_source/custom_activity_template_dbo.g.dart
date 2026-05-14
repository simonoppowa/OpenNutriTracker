// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_activity_template_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomActivityTemplateDBOAdapter
    extends TypeAdapter<CustomActivityTemplateDBO> {
  @override
  final typeId = 21;

  @override
  CustomActivityTemplateDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomActivityTemplateDBO(
      fields[0] as String,
      (fields[1] as num).toDouble(),
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomActivityTemplateDBO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.typicalKcal)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomActivityTemplateDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomActivityTemplateDBO _$CustomActivityTemplateDBOFromJson(
  Map<String, dynamic> json,
) => CustomActivityTemplateDBO(
  json['name'] as String,
  (json['typicalKcal'] as num).toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CustomActivityTemplateDBOToJson(
  CustomActivityTemplateDBO instance,
) => <String, dynamic>{
  'name': instance.name,
  'typicalKcal': instance.typicalKcal,
  'notes': instance.notes,
};
