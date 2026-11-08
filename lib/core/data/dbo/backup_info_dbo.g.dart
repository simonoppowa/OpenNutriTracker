// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_info_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BackupInfoDBOAdapter extends TypeAdapter<BackupInfoDBO> {
  @override
  final int typeId = 16;

  @override
  BackupInfoDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BackupInfoDBO(
      lastBackupTimestamp: fields[0] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BackupInfoDBO obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.lastBackupTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupInfoDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
