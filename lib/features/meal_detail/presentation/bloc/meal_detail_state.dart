part of 'meal_detail_bloc.dart';

abstract class MealDetailState extends Equatable {
  final String totalQuantityConverted;
  final double totalKcal;
  final double totalCarbs;
  final double totalFat;
  final double totalProtein;

  final String selectedUnit;

  final double dayKcalConsumed;
  final double dayKcalGoal;

  const MealDetailState({
    required this.totalQuantityConverted,
    this.totalKcal = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
    required this.selectedUnit,
    this.dayKcalConsumed = 0,
    this.dayKcalGoal = 0,
  });

  @override
  List<Object> get props => [
        totalQuantityConverted,
        totalKcal,
        totalCarbs,
        totalFat,
        totalProtein,
        selectedUnit,
        dayKcalConsumed,
        dayKcalGoal,
      ];

  MealDetailInitial copyWith({
    String? totalQuantityConverted,
    double? totalKcal,
    double? totalCarbs,
    double? totalFat,
    double? totalProtein,
    String? selectedUnit,
    double? dayKcalConsumed,
    double? dayKcalGoal,
  }) {
    return MealDetailInitial(
      totalQuantityConverted:
          totalQuantityConverted ?? this.totalQuantityConverted,
      totalKcal: totalKcal ?? this.totalKcal,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalProtein: totalProtein ?? this.totalProtein,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      dayKcalConsumed: dayKcalConsumed ?? this.dayKcalConsumed,
      dayKcalGoal: dayKcalGoal ?? this.dayKcalGoal,
    );
  }
}

class MealDetailInitial extends MealDetailState {
  const MealDetailInitial({
    required super.totalQuantityConverted,
    super.totalKcal,
    super.totalCarbs,
    super.totalFat,
    super.totalProtein,
    required super.selectedUnit,
    super.dayKcalConsumed,
    super.dayKcalGoal,
  });
}
