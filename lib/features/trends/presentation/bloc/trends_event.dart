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

  /// A calendar week, a month or a picked span (#57); when set it replaces
  /// [rangeDays].
  final TrendsPeriod? period;

  const LoadTrendsEvent({this.rangeDays = 7, this.period});

  @override
  List<Object?> get props => [rangeDays, period];
}
