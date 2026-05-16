import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fasting_session_dbo.g.dart';

/// Persistent record of a single fasting timer session. Sessions are written
/// when the user taps "Start timer" and updated in place when they either
/// cancel (`cancelledAt`) or the timer reaches its target naturally
/// (`completedAt`). The two end-state fields are kept separate so analytics or
/// future history views can read both outcomes neutrally — there is no
/// "broken" vs "successful" framing in the data model, and there should not
/// be one in the UI either.
@HiveType(typeId: 22)
@JsonSerializable()
class FastingSessionDBO extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime startedAt;
  @HiveField(2)
  int targetDurationMinutes;
  @HiveField(3)
  DateTime? completedAt;
  @HiveField(4)
  DateTime? cancelledAt;

  FastingSessionDBO({
    required this.id,
    required this.startedAt,
    required this.targetDurationMinutes,
    this.completedAt,
    this.cancelledAt,
  });

  factory FastingSessionDBO.fromJson(Map<String, dynamic> json) =>
      _$FastingSessionDBOFromJson(json);

  Map<String, dynamic> toJson() => _$FastingSessionDBOToJson(this);
}
