part of 'activities_bloc.dart';

abstract class ActivitiesEvent extends Equatable {
  const ActivitiesEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivitiesEvent extends ActivitiesEvent {
  final BuildContext context;

  const LoadActivitiesEvent({required this.context});

  @override
  List<Object?> get props => [];
}

class SearchActivitiesEvent extends ActivitiesEvent {
  final BuildContext context;
  final String searchString;

  const SearchActivitiesEvent(
      {required this.context, required this.searchString});

  @override
  List<Object?> get props => [searchString];
}
