part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
}

class LoadDiaryYearEvent extends DiaryEvent {
  final BuildContext context;

  const LoadDiaryYearEvent(this.context);

  @override
  List<Object?> get props => [];
}
