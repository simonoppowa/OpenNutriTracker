// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeDBOAdapter extends TypeAdapter<AppThemeDBO> {
  @override
  final int typeId = 15;

  @override
  AppThemeDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppThemeDBO.light;
      case 1:
        return AppThemeDBO.dark;
      case 2:
        return AppThemeDBO.system;
      default:
        return AppThemeDBO.light;
    }
  }

  @override
  void write(BinaryWriter writer, AppThemeDBO obj) {
    switch (obj) {
      case AppThemeDBO.light:
        writer.writeByte(0);
        break;
      case AppThemeDBO.dark:
        writer.writeByte(1);
        break;
      case AppThemeDBO.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
