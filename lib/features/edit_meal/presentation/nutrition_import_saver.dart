import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

Future<NutritionBatchSelection> saveImportedNutritionEntries(
  EditMealBloc bloc,
  List<NutritionEntry> entries,
) async {
  final selection = selectNutritionBatch(entries, bloc.customMealNames);
  for (final entry in selection.entries) {
    final values = entry.toPer100();
    final unit = entry.basis == NutritionBasis.per100ml
        ? 'ml'
        : entry.basis == NutritionBasis.per100g
        ? 'g'
        : entry.servingUnit!;
    await bloc.saveCustomMeal(
      MealEntity(
        code: MealEntity.empty().code,
        name: entry.name.trim(),
        brands: entry.brand.trim(),
        url: null,
        mealQuantity: '100',
        mealUnit: unit,
        servingQuantity: entry.servingSize,
        servingUnit: unit,
        servingSize: entry.servingSize == null
            ? null
            : '${entry.servingSize} $unit',
        source: MealSourceEntity.custom,
        nutriments: MealNutrimentsEntity(
          energyKcal100: values['kcal'],
          carbohydrates100: values['carbs'],
          fat100: values['fat'],
          proteins100: values['protein'],
          sugars100: values['sugars'],
          saturatedFat100: values['saturatedFat'],
          fiber100: values['fiber'],
          sodium100: values['sodium'],
          calcium100: values['calcium'],
          iron100: values['iron'],
          potassium100: values['potassium'],
          magnesium100: values['magnesium'],
          vitaminD100: values['vitaminD'],
          vitaminB12100: values['vitaminB12'],
        ),
      ),
    );
  }
  return selection;
}
