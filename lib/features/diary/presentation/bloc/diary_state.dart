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

  const DiaryLoadedState(this.trackedDayMap);

  @override
  List<Object?> get props => [trackedDayMap];
}
