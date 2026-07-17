part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  @override
  List<Object> get props => [];
}

class ProfileLoadingState extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileLoadedState extends ProfileState {
  final UserBMIEntity userBMI;
  final UserEntity userEntity;

  // Granular unit preferences. Height (cm/ft) and body weight (kg/lb/st) are
  // chosen independently of the food unit preference.
  final BodyWeightUnit bodyWeightUnit;
  final bool usesImperialHeightUnits;
  // #32: resolved daily water goal in millilitres, with the user's
  // override applied (or the gendered seed if none is stored yet). The
  // profile entry subtitle shows this so the user sees the value the
  // home chip is using without opening the dialog.
  final int effectiveWaterGoalMl;

  const ProfileLoadedState({
    required this.userBMI,
    required this.userEntity,
    required this.bodyWeightUnit,
    required this.usesImperialHeightUnits,
    required this.effectiveWaterGoalMl,
  });

  @override
  List<Object?> get props => [
        userBMI,
        userEntity,
        bodyWeightUnit,
        usesImperialHeightUnits,
        effectiveWaterGoalMl,
      ];
}
