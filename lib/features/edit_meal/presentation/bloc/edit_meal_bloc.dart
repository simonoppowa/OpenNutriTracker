import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'edit_meal_state.dart';

part 'edit_meal_event.dart';

/// Computes the per-100g scale factor for a typed base-quantity string.
///
/// `createNewMealEntity` multiplies every typed nutriment by this factor
/// before storing it on the per-100g fields, so values typed at the
/// user's chosen base quantity land in the canonical "per 100" slot.
/// Lifted out of the bloc so it can be unit-tested directly without
/// instantiating the bloc's dependency graph — see
/// `test/unit_test/edit_meal_simple_mode_scale_test.dart` for the
/// regression coverage on Simple-mode (#232).
double factorTo100gFromBase(String baseQuantity) {
  final parsed = double.tryParse(baseQuantity);
  return parsed != null ? (100 / parsed) : 1;
}

/// Custom meal form view mode (#232). Persisted on ConfigDBO so the form
/// remembers which view the user prefers between sessions.
enum CustomMealFormMode {
  simple,
  advanced;

  static CustomMealFormMode fromString(String? value) {
    if (value == advanced.name) return advanced;
    // Simple is the default for new users and for any unrecognised value:
    // it removes the per-100g cognitive load and matches the most common
    // request from the people who filed #232.
    return simple;
  }
}

class EditMealBloc extends Bloc<EditMealEvent, EditMealState> {
  final GetConfigUsecase _getConfigUsecase;
  final CustomMealDataSource _customMealDataSource; // #267
  final ConfigRepository _configRepository;

  EditMealBloc(this._getConfigUsecase, this._customMealDataSource, this._configRepository)
      : super(EditMealInitial()) {
    on<InitializeEditMealEvent>((event, emit) async {
      emit(EditMealLoadingState());

      final config = await _getConfigUsecase.getConfig();
      final mode = CustomMealFormMode.fromString(
        await _configRepository.getCustomMealFormMode(),
      );
      emit(EditMealLoadedState(
        usesImperialUnits: config.usesImperialUnits,
        formMode: mode,
      ));
    });
  }

  /// Persist the user's form view preference so the next custom-meal entry
  /// opens in the same mode they last used (#232).
  Future<void> setFormMode(CustomMealFormMode mode) async {
    await _configRepository.setCustomMealFormMode(mode.name);
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
    String? fiberText,
    String? saturatedFatText,
    String? sugarsText,
    String? sodiumText,
    String? calciumText,
    String? ironText,
    String? potassiumText,
    String? magnesiumText,
    String? vitaminDText,
    String? vitaminB12Text,
    String? barcodeOverride,
    String? localImagePathOverride,
    bool clearLocalImagePath = false,
  }) {
    final double factorTo100g = factorTo100gFromBase(baseQuantity);

    double? multiplyIfNotNull(double? nutrimentValue) {
      return nutrimentValue != null ? nutrimentValue * factorTo100g : null;
    }

    double? fromTextOrOld(String? text, double? oldValue) =>
        multiplyIfNotNull(text?.toDoubleOrNull() ?? oldValue);

    final newMealNutriments = MealNutrimentsEntity(
      energyKcal100: multiplyIfNotNull(kcalText.toDoubleOrNull()),
      carbohydrates100: multiplyIfNotNull(carbsText.toDoubleOrNull()),
      fat100: multiplyIfNotNull(fatText.toDoubleOrNull()),
      proteins100: multiplyIfNotNull(proteinText.toDoubleOrNull()),
      sugars100: fromTextOrOld(sugarsText, oldMealEntity.nutriments.sugars100),
      saturatedFat100: fromTextOrOld(saturatedFatText, oldMealEntity.nutriments.saturatedFat100),
      fiber100: fromTextOrOld(fiberText, oldMealEntity.nutriments.fiber100),
      sodium100: fromTextOrOld(sodiumText, oldMealEntity.nutriments.sodium100),
      calcium100: fromTextOrOld(calciumText, oldMealEntity.nutriments.calcium100),
      iron100: fromTextOrOld(ironText, oldMealEntity.nutriments.iron100),
      potassium100: fromTextOrOld(potassiumText, oldMealEntity.nutriments.potassium100),
      magnesium100: fromTextOrOld(magnesiumText, oldMealEntity.nutriments.magnesium100),
      vitaminD100: fromTextOrOld(vitaminDText, oldMealEntity.nutriments.vitaminD100),
      vitaminB12100: fromTextOrOld(vitaminB12Text, oldMealEntity.nutriments.vitaminB12100),
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
