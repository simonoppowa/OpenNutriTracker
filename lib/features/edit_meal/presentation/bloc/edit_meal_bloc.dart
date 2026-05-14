import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'edit_meal_state.dart';

part 'edit_meal_event.dart';

class EditMealBloc extends Bloc<EditMealEvent, EditMealState> {
  final GetConfigUsecase _getConfigUsecase;
  final CustomMealDataSource _customMealDataSource; // #267

  EditMealBloc(this._getConfigUsecase, this._customMealDataSource) : super(EditMealInitial()) {
    on<InitializeEditMealEvent>((event, emit) async {
      emit(EditMealLoadingState());

      final config = await _getConfigUsecase.getConfig();
      emit(EditMealLoadedState(usesImperialUnits: config.usesImperialUnits));
    });
  }

  MealEntity createNewMealEntity(
    MealEntity oldMealEntity,
    String nameText,
    String brandsText,
    String mealQuantityText,
    String servingQuantityText,
    String baseQuantity,
    String? unitText,
    String kcalText,
    String carbsText,
    String fatText,
    String proteinText, {
    String? barcodeOverride,
    String? localImagePathOverride,
    bool clearLocalImagePath = false,
  }) {
    final baseQuantityDouble = double.tryParse(baseQuantity);

    final double factorTo100g =
        baseQuantityDouble != null ? (100 / baseQuantityDouble) : 1;

    double? multiplyIfNotNull(double? nutrimentValue) {
      return nutrimentValue != null ? nutrimentValue * factorTo100g : null;
    }

    final newMealNutriments = MealNutrimentsEntity(
      energyKcal100: multiplyIfNotNull(kcalText.toDoubleOrNull()),
      carbohydrates100: multiplyIfNotNull(carbsText.toDoubleOrNull()),
      fat100: multiplyIfNotNull(fatText.toDoubleOrNull()),
      proteins100: multiplyIfNotNull(proteinText.toDoubleOrNull()),
      sugars100: multiplyIfNotNull(oldMealEntity.nutriments.sugars100),
      saturatedFat100: multiplyIfNotNull(
        oldMealEntity.nutriments.saturatedFat100,
      ),
      fiber100: multiplyIfNotNull(oldMealEntity.nutriments.fiber100),
    );

    return MealEntity(
      // #167: a user-typed or scanned barcode wins over whatever came
      // from the originating OFF/FDC record, but only when the override
      // was actually supplied. Empty-string is treated as "clear" so a
      // user can erase a stored code by blanking the field.
      code: barcodeOverride ?? oldMealEntity.code,
      name: nameText.toStringOrNull(),
      brands: brandsText.toStringOrNull(),
      url: oldMealEntity.url,
      thumbnailImageUrl: oldMealEntity.thumbnailImageUrl,
      mainImageUrl: oldMealEntity.mainImageUrl,
      mealQuantity: mealQuantityText.toStringOrNull(),
      mealUnit: unitText,
      servingQuantity: servingQuantityText.toDoubleOrNull(),
      servingUnit: servingQuantityText.toStringOrNull(),
      servingSize: oldMealEntity.servingSize,
      nutriments: newMealNutriments,
      source: oldMealEntity.source,
      // #64 follow-up: a freshly-picked local photo wins over what was
      // on the old entity; a clear flag means the user removed the
      // photo and the slug should be wiped from the saved meal.
      localImagePath: clearLocalImagePath
          ? null
          : (localImagePathOverride ?? oldMealEntity.localImagePath),
    );
  }

  /// Persist custom meal template so it appears in Recent Meals before first log (#267)
  Future<void> saveCustomMeal(MealEntity mealEntity) async {
    await _customMealDataSource.saveCustomMeal(MealDBO.fromMealEntity(mealEntity));
  }
}
