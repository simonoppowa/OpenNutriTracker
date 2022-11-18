part of 'activity_detail_bloc.dart';

abstract class ActivityDetailState extends Equatable {
  const ActivityDetailState();
}

class ActivityDetailInitial extends ActivityDetailState {
  @override
  List<Object> get props => [];
}

class ActivityDetailLoadingState extends ActivityDetailState {
  @override
  List<Object?> get props => [];
}

class ActivityDetailLoadedState extends ActivityDetailState {
  final double totalKcalBurned;
  final int quantityMin;
  final UserEntity userEntity;

  const ActivityDetailLoadedState(
      this.totalKcalBurned, this.userEntity, this.quantityMin);

  @override
  List<Object?> get props => [];
}
