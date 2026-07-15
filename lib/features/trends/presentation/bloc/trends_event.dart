part of 'trends_bloc.dart';

abstract class TrendsEvent extends Equatable {
  const TrendsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendsEvent extends TrendsEvent {
  /// Window for the calorie and macro trends, in days (7, 30 or 90). The
  /// on-track streak is always the most recent 7 days within the window.
  final int rangeDays;

  const LoadTrendsEvent({this.rangeDays = 7});

  @override
  List<Object?> get props => [rangeDays];
}
