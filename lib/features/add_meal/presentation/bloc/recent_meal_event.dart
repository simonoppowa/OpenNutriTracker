part of 'recent_meal_bloc.dart';

abstract class RecentMealEvent extends Equatable {
  const RecentMealEvent();
}

class LoadRecentMealEvent extends RecentMealEvent {
  final BuildContext context;

  const LoadRecentMealEvent({required this.context});

  @override
  List<Object?> get props => [];
}
