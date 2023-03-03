part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
}

class OnboardingInitialState extends OnboardingState {
  @override
  List<Object> get props => [];
}

class OnboardingLoadingState extends OnboardingState {
  @override
  List<Object?> get props => [];
}

class OnboardingLoadedState extends OnboardingState {
  @override
  List<Object?> get props => [];
}
