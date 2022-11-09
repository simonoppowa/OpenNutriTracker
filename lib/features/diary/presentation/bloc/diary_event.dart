part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
}

class LoadDiaryEvent extends DiaryEvent {
  final BuildContext context;
  final DateTime startDate;
  final DateTime endDate;

  const LoadDiaryEvent(this.context, this.startDate, this.endDate);

  @override
  List<Object?> get props => [];
}
