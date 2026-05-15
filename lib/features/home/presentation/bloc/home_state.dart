part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
}

class HomeInitial extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoadingState extends HomeState {
  @override
  List<Object?> get props => [];
}

class HomeLoadedState extends HomeState {
  final bool showDisclaimerDialog;
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;
  final List<UserActivityEntity> userActivityList;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;
  final bool usesImperialUnits;
  final bool showActivityTracking; // #277
  final bool showMealMacros;
  final double userWeightKg;
  // #150: recommended kcal target for each meal section, derived from the
  // daily goal and the share configured under Settings → Calculations.
  final double breakfastKcalTarget;
  final double lunchKcalTarget;
  final double dinnerKcalTarget;
  final double snackKcalTarget;
  // #150 follow-up: per-meal share percentages. A 0% share signals that the
  // user has explicitly opted out of seeing that meal section (e.g. OMAD has
  // 0% snack), so the section is hidden entirely rather than showing an empty
  // header with a 0-kcal target.
  final int breakfastSharePct;
  final int lunchSharePct;
  final int dinnerSharePct;
  final int snackSharePct;
  final UserGenderEntity userGender;
  final CaloriesProfileEntity? userCaloriesProfile;

  const HomeLoadedState({
    required this.showDisclaimerDialog,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
    required this.userActivityList,
    required this.breakfastIntakeList,
    required this.lunchIntakeList,
    required this.dinnerIntakeList,
    required this.snackIntakeList,
    required this.usesImperialUnits,
    required this.userWeightKg,
    required this.breakfastKcalTarget,
    required this.lunchKcalTarget,
    required this.dinnerKcalTarget,
    required this.snackKcalTarget,
    required this.breakfastSharePct,
    required this.lunchSharePct,
    required this.dinnerSharePct,
    required this.snackSharePct,
    required this.userGender,
    required this.userCaloriesProfile,
    this.showActivityTracking = true,
    this.showMealMacros = true,
  });

  @override
  List<Object?> get props => [
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList,
        usesImperialUnits,
        userWeightKg,
        totalKcalDaily,
      ];
}
