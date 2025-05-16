import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

part 'user_weight_dbo.g.dart';

@HiveType(typeId: 18)
@JsonSerializable()
class UserWeightDbo extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double weight;
  @HiveField(2)
  final DateTime date;

  UserWeightDbo(this.id, this.weight, this.date);

  factory UserWeightDbo.fromUserWeightEntity(
      UserWeightEntity userWeightEntity) {
    return UserWeightDbo(
        userWeightEntity.id, userWeightEntity.weight, userWeightEntity.date);
  }
}
