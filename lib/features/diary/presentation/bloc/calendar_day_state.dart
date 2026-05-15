part of 'calendar_day_bloc.dart';

abstract class CalendarDayState extends Equatable {
  const CalendarDayState();
}

class CalendarDayInitial extends CalendarDayState {
  @override
  List<Object> get props => [];
}

class CalendarDayLoading extends CalendarDayState {
  @override
  List<Object?> get props => [];
}

class CalendarDayLoaded extends CalendarDayState {
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivityList;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;
  // #150: per-meal recommended kcal targets for this calendar day.
  // 0 means no daily goal exists for this day, in which case the diary
  // view simply omits the target portion of the section header.
  final double breakfastKcalTarget;
  final double lunchKcalTarget;
  final double dinnerKcalTarget;
  final double snackKcalTarget;
  // #150 follow-up: per-meal share percentages. A 0% share hides the section
  // entirely so OMAD / two-meal users don't see meal slots they've explicitly
  // opted out of.
  final int breakfastSharePct;
  final int lunchSharePct;
  final int dinnerSharePct;
  final int snackSharePct;
  // Persisted per-meal sort preference, keyed by meal type string
  // (breakfast / lunch / dinner / snack) and valued by DiarySortType index.
  // Null when the user has never picked a sort, in which case the diary
  // falls back to DiarySortType.timeAdded.
  final Map<String, int>? diarySortPreferences;

  const CalendarDayLoaded(
    this.trackedDayEntity,
    this.userActivityList,
    this.breakfastIntakeList,
    this.lunchIntakeList,
    this.dinnerIntakeList,
    this.snackIntakeList,
    this.breakfastKcalTarget,
    this.lunchKcalTarget,
    this.dinnerKcalTarget,
    this.snackKcalTarget,
    this.breakfastSharePct,
    this.lunchSharePct,
    this.dinnerSharePct,
    this.snackSharePct, {
    this.diarySortPreferences,
  });

  @override
  List<Object?> get props => [
        trackedDayEntity,
        breakfastKcalTarget,
        lunchKcalTarget,
        dinnerKcalTarget,
        snackKcalTarget,
        breakfastSharePct,
        lunchSharePct,
        dinnerSharePct,
        snackSharePct,
        diarySortPreferences,
      ];
}
