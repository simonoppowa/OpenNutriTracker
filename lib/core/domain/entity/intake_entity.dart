import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class IntakeEntity extends Equatable {
  final String id;
  final String unit;
  final double amount;
  final IntakeTypeEntity type;
  final DateTime dateTime;

  final MealEntity meal;

  /// The recipe as it existed when this occurrence was logged. Null on old
  /// intakes, which cannot safely be exploded from a later recipe version.
  final RecipeEntity? recipeSnapshot;

  /// Links replacement ingredients to their original intake. While the
  /// original still exists, these rows are pending and must not be counted.
  final String? conversionParentId;

  const IntakeEntity({
    required this.id,
    required this.unit,
    required this.amount,
    required this.type,
    required this.meal,
    required this.dateTime,
    this.recipeSnapshot,
    this.conversionParentId,
  });

  factory IntakeEntity.fromIntakeDBO(IntakeDBO intakeDBO) {
    return IntakeEntity(
      id: intakeDBO.id,
      unit: intakeDBO.unit,
      amount: intakeDBO.amount,
      type: IntakeTypeEntity.fromIntakeTypeDBO(intakeDBO.type),
      meal: MealEntity.fromMealDBO(intakeDBO.meal),
      dateTime: intakeDBO.dateTime,
      recipeSnapshot: intakeDBO.recipeSnapshot == null
          ? null
          : RecipeEntity.fromDBO(intakeDBO.recipeSnapshot!),
      conversionParentId: intakeDBO.conversionParentId,
    );
  }

  double get totalKcal => amount * (meal.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram =>
      amount * (meal.nutriments.carbohydratesPerUnit ?? 0);

  double get totalFatsGram => amount * (meal.nutriments.fatPerUnit ?? 0);

  double get totalProteinsGram =>
      amount * (meal.nutriments.proteinsPerUnit ?? 0);

  @override
  List<Object?> get props => [
    id,
    unit,
    amount,
    type,
    dateTime,
    recipeSnapshot,
    conversionParentId,
  ];
}
