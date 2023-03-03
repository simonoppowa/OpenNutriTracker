// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_weight_goal_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserWeightGoalDBOAdapter extends TypeAdapter<UserWeightGoalDBO> {
  @override
  final int typeId = 7;

  @override
  UserWeightGoalDBO read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserWeightGoalDBO.loseWeight;
      case 1:
        return UserWeightGoalDBO.maintainWeight;
      case 2:
        return UserWeightGoalDBO.gainWeight;
      default:
        return UserWeightGoalDBO.loseWeight;
    }
  }

  @override
  void write(BinaryWriter writer, UserWeightGoalDBO obj) {
    switch (obj) {
      case UserWeightGoalDBO.loseWeight:
        writer.writeByte(0);
        break;
      case UserWeightGoalDBO.maintainWeight:
        writer.writeByte(1);
        break;
      case UserWeightGoalDBO.gainWeight:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWeightGoalDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
