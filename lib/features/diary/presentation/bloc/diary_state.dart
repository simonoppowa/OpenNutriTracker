part of 'diary_bloc.dart';

abstract class DiaryState extends Equatable {
  const DiaryState();
}

class DiaryInitial extends DiaryState {
  @override
  List<Object> get props => [];
}

class DiaryLoadingState extends DiaryState {
  @override
  List<Object?> get props => [];
}

class DiaryLoadedState extends DiaryState {
  final Map<String, TrackedDayEntity> trackedDayMap;
  final bool usesImperialUnits;
  final bool showMealMacros;
  final bool showActivityTracking;

  /// The keys of the days with at least one entry logged, which are the
  /// days the calendar marks.
  final Set<String> daysWithEntries;

  const DiaryLoadedState(
    this.trackedDayMap,
    this.usesImperialUnits, {
    this.showMealMacros = true,
    this.showActivityTracking = true,
    this.daysWithEntries = const {},
  });

  @override
  List<Object?> get props => [
        trackedDayMap,
        usesImperialUnits,
        showMealMacros,
        showActivityTracking,
        daysWithEntries,
      ];
}
