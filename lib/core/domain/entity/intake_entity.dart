import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class IntakeEntity extends Equatable {
  final String id;
  final String unit;
  final double amount;
  final IntakeTypeEntity type;
  final DateTime dateTime;

  final MealEntity meal;

  const IntakeEntity({
    required this.id,
    required this.unit,
    required this.amount,
    required this.type,
    required this.meal,
    required this.dateTime,
  });

  factory IntakeEntity.fromIntakeDBO(IntakeDBO intakeDBO) {
    return IntakeEntity(
      id: intakeDBO.id,
      unit: intakeDBO.unit,
      amount: intakeDBO.amount,
      type: IntakeTypeEntity.fromIntakeTypeDBO(intakeDBO.type),
      meal: MealEntity.fromMealDBO(intakeDBO.meal),
      dateTime: intakeDBO.dateTime,
    );
  }

  /// True when this entry is a Quick Add without a weight (#705): its
  /// totals are the values the user typed and there is no weight to show or
  /// to scale them by.
  ///
  /// Only at the basis the meal was stored for. The same meal logged again
  /// at another amount — from Recents, through its detail screen — has
  /// scaled totals, so it shows and edits its amount like any other food.
  bool get hasFixedTotals =>
      meal.fixedTotals && amount == MealEntity.fixedTotalsBasis;

  double get totalKcal => amount * (meal.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram =>
      amount * (meal.nutriments.carbohydratesPerUnit ?? 0);

  double get totalFatsGram => amount * (meal.nutriments.fatPerUnit ?? 0);

  double get totalProteinsGram =>
      amount * (meal.nutriments.proteinsPerUnit ?? 0);

  @override
  List<Object?> get props => [id, unit, amount, type, dateTime];
}
