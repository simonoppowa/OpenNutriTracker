import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/meal_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class LocalDataSource {
  final log = Logger('LocalDataSource');

  Future<List<MealEntity>> fetchSearchWordResults(String searchString) async {
    final mealSrc = locator<MealDataSource>();
    return (await mealSrc.getMealsByName(searchString)).map((meal) => MealEntity.fromMealDBO(meal)).toList();
  }
}
