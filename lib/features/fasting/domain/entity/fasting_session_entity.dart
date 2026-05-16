import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';

/// Plain domain model for a fasting session. End-state is represented by two
/// independent timestamps so the UI never has to ask "did the user fail" —
/// the natural-completion and user-cancellation paths read identically from
/// the data layer and only differ in which timestamp is set.
class FastingSessionEntity extends Equatable {
  final String id;
  final DateTime startedAt;
  final int targetDurationMinutes;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const FastingSessionEntity({
    required this.id,
    required this.startedAt,
    required this.targetDurationMinutes,
    this.completedAt,
    this.cancelledAt,
  });

  bool get isActive => completedAt == null && cancelledAt == null;

  Duration get targetDuration => Duration(minutes: targetDurationMinutes);

  Duration elapsedAt(DateTime now) => now.difference(startedAt);

  factory FastingSessionEntity.fromDBO(FastingSessionDBO dbo) =>
      FastingSessionEntity(
        id: dbo.id,
        startedAt: dbo.startedAt,
        targetDurationMinutes: dbo.targetDurationMinutes,
        completedAt: dbo.completedAt,
        cancelledAt: dbo.cancelledAt,
      );

  FastingSessionDBO toDBO() => FastingSessionDBO(
    id: id,
    startedAt: startedAt,
    targetDurationMinutes: targetDurationMinutes,
    completedAt: completedAt,
    cancelledAt: cancelledAt,
  );

  FastingSessionEntity copyWith({
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return FastingSessionEntity(
      id: id,
      startedAt: startedAt,
      targetDurationMinutes: targetDurationMinutes,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    startedAt,
    targetDurationMinutes,
    completedAt,
    cancelledAt,
  ];
}
