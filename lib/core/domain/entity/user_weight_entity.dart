import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';

class UserWeightEntity {
  final String id;
  final double weight;
  final DateTime date;

  const UserWeightEntity(
      {required this.id, required this.weight, required this.date});

  factory UserWeightEntity.fromUserWeightDbo(UserWeightDbo userWeightDbo) {
    return UserWeightEntity(
        id: userWeightDbo.id,
        weight: userWeightDbo.weight,
        date: userWeightDbo.date);
  }

  static getIconData() => Icons.monitor_weight_outlined;
}
