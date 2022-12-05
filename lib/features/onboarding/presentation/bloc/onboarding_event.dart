part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
}

class LoadOnboardingEvent extends OnboardingEvent {
  @override
  List<Object?> get props => [];
}
