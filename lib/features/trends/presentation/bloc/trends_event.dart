part of 'trends_bloc.dart';

abstract class TrendsEvent extends Equatable {
  const TrendsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendsEvent extends TrendsEvent {
  /// Null loads this profile's last selected range; 0 means All.
  final int? rangeDays;

  const LoadTrendsEvent({this.rangeDays});

  @override
  List<Object?> get props => [rangeDays];
}

/// Reloads with the range of the last [LoadTrendsEvent]. For callers outside
/// the page that changed something Trends reads — a goal, a setting, a
/// weight entry. Does nothing before the page's first load, which reads
/// fresh data anyway.
class RefreshTrendsEvent extends TrendsEvent {
  const RefreshTrendsEvent();
}
