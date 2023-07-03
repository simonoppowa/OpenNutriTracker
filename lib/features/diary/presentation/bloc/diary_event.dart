part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
}

class LoadDiaryYearEvent extends DiaryEvent {
  const LoadDiaryYearEvent();

  @override
  List<Object?> get props => [];
}
