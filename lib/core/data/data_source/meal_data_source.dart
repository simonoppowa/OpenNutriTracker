import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';

class MealDataSource {
  final log = Logger('MealDataSource');
  final Box<MealDBO> _mealBox;

  MealDataSource(this._mealBox);

  Future<void> addMeal(MealDBO mealDBO) async {
    if ((await getMealByName(mealDBO.name ?? "")) == null ){
      log.fine('Adding new meal item to db');
      _mealBox.add(mealDBO);
    }
  }

  Future<void> deleteMealFromId(String mealId) async {
    log.fine('Deleting meal item from db');
    _mealBox.values
        .where((dbo) => dbo.code == mealId)
        .toList()
        .forEach((element) {
      element.delete();
    });
  }

  Future<MealDBO?> getMealById(String mealId) async {
    return _mealBox.values.firstWhereOrNull(
            (meal) => meal.code == mealId
    );
  }

  Future<MealDBO?> getMealByName(String name) async {
    return _mealBox.values.firstWhereOrNull(
            (meal) => meal.name == name
    );
  }

  Future<List<MealDBO>> getMealsByName(String name) async {
    return _mealBox.values.where(
            (meal) => meal.name!.contains(name)
    ).toList();
  }


  Future<MealDBO?> getMealByBarcode(String barcode) async {
    return _mealBox.values.firstWhereOrNull(
            (meal) => meal.barcode == barcode
    );
  }

}
