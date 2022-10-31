part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final BuildContext context;

  LoadProfileEvent({required this.context});
}
