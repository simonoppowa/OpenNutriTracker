import 'package:hive_flutter/hive_flutter.dart';

part 'tracked_day_dbo.g.dart';

@HiveType(typeId: 9)
class TrackedDayDBO {
  @HiveField(0)
  double calorieGoal;
  @HiveField(1)
  double caloriesTracked;

  TrackedDayDBO({required this.calorieGoal, required this.caloriesTracked});
}
