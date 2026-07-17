import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class CustomMealDataSource {
  final HiveDBProvider _db;

  CustomMealDataSource(this._db);

  Box<MealDBO> get _customMealBox => _db.customMealBox;

  Future<void> saveCustomMeal(MealDBO mealDBO) async {
    final existing = _customMealBox.values.cast<MealDBO?>().firstWhere(
        (m) =>
            (mealDBO.code != null && m?.code == mealDBO.code) ||
            (mealDBO.code == null && m?.name == mealDBO.name),
        orElse: () => null);
    if (existing != null) {
      await _customMealBox.put(existing.key, mealDBO);
    } else {
      await _customMealBox.add(mealDBO);
    }
  }

  List<MealDBO> getAllCustomMeals() => _customMealBox.values.toList();

  Future<void> deleteCustomMeal(String mealKey) async {
    final toDelete = _customMealBox.values
        .where((m) => (m.code ?? m.name) == mealKey)
        .toList();
    for (final meal in toDelete) {
      await meal.delete();
    }
  }
}
