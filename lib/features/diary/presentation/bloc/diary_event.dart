part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
}

class LoadDiaryEvent extends DiaryEvent {
  @override
  List<Object?> get props => [];
}
