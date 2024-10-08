import 'package:opennutritracker/core/data/data_source/meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class MealRepository {
  final MealDataSource _mealDataSource;

  MealRepository(this._mealDataSource);

  Future<void> addMeal(MealEntity mealEntity) async {
    final mealDBO = MealDBO.fromMealEntity(mealEntity);

    await _mealDataSource.addMeal(mealDBO);
  }

  Future<void> deleteMeal(MealEntity mealEntity) async {
    if (mealEntity.code != null) {
      await _mealDataSource.deleteMealFromId(mealEntity.code ?? "");
    }
  }

  // Future<MealEntity?> updateMeal(String mealId, Map<String, dynamic> fields) async {
  //   var result = await _mealDataSource.updateMeal(mealId, fields);
  //   return result == null ? null : MealEntity.fromMealDBO(result);
  // }

  Future<MealEntity?> getMealById(String mealId) async {
    final result = await _mealDataSource.getMealById(mealId);
    return result == null ? null : MealEntity.fromMealDBO(result);
  }
}
