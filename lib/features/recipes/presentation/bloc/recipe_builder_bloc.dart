import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

part 'recipe_builder_event.dart';
part 'recipe_builder_state.dart';

class RecipeBuilderBloc
    extends Bloc<RecipeBuilderEvent, RecipeBuilderState> {
  final ComputeRecipeNutritionUseCase _computeUseCase;
  final SaveRecipeUseCase _saveUseCase;

  RecipeBuilderBloc(this._computeUseCase, this._saveUseCase)
      : super(RecipeBuilderState.initial()) {
    on<InitializeBuilderEvent>(_onInitialize);
    on<UpdateNameEvent>(_onUpdateName);
    on<UpdateDescriptionEvent>(_onUpdateDescription);
    on<UpdateServingsCountEvent>(_onUpdateServings);
    on<UpdateTagsEvent>((event, emit) {
      emit(state.copyWith(tags: event.tags));
    });
    on<AddIngredientEvent>(_onAddIngredient);
    on<UpdateIngredientEvent>(_onUpdateIngredient);
    on<RemoveIngredientEvent>(_onRemoveIngredient);
    on<UpdateTotalWeightEvent>(_onUpdateTotalWeight);
    on<UpdateBarcodeEvent>((event, emit) {
      final trimmed = event.barcode?.trim();
      final normalized = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      emit(
        state.copyWith(
          barcode: normalized,
          clearBarcode: normalized == null,
        ),
      );
    });
    on<SaveRecipeEvent>(_onSave);
  }

  // Lenient EAN-13 / UPC-A check — accept any 8-to-14 digit run. The longer
  // bound covers GTIN-14 case packaging, the shorter covers EAN-8.
  static final _barcodeFormat = RegExp(r'^\d{8,14}$');

  static bool _isBarcodeValid(String value) => _barcodeFormat.hasMatch(value);

  // EAN-13 specific check-digit validation. For a 13-digit code the final
  // digit must match the value computed from the first twelve, otherwise
  // the user has miskeyed somewhere. 8 / 12 / 14-digit codes use different
  // algorithms (EAN-8, UPC-A, GTIN-14) and are accepted at face value by
  // the lenient regex above — we don't validate those here because real
  // products on those formats may have been entered correctly without
  // matching the EAN-13 weighting.
  //
  // Algorithm: sum the odd-positioned digits (1, 3, 5, 7, 9, 11), sum the
  // even-positioned digits (2, 4, 6, 8, 10, 12) and weight that by three,
  // take modulo ten, subtract from ten, modulo ten again — that's the
  // expected 13th digit.
  @visibleForTesting
  static bool isEan13CheckDigitValid(String value) =>
      _isEan13CheckDigitValid(value);

  static bool _isEan13CheckDigitValid(String value) {
    if (value.length != 13) return true;
    var sumOdd = 0;
    var sumEven = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(value[i]);
      // i is 0-indexed; position 1 (odd) corresponds to i == 0, etc.
      if (i.isEven) {
        sumOdd += digit;
      } else {
        sumEven += digit;
      }
    }
    final check = (10 - ((sumOdd + 3 * sumEven) % 10)) % 10;
    return int.parse(value[12]) == check;
  }

  void _onInitialize(
    InitializeBuilderEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    if (event.existing == null) {
      emit(RecipeBuilderState.initial());
    } else {
      final r = event.existing!;
      // Empty id is the sentinel used by the duplicate-recipe action: keep
      // the field values but treat the builder as a fresh create so save()
      // assigns a new uuid.
      final isDuplicate = r.id.isEmpty;
      emit(
        state.copyWith(
          id: isDuplicate ? null : r.id,
          name: r.name,
          description: r.description,
          servingsCount: r.servingsCount,
          ingredients: r.ingredients,
          totalWeightG: r.totalWeightG,
          totalWeightOverridden: false,
          aggregatedNutrimentsPer100: r.aggregatedNutrimentsPer100,
          isExistingRecipe: !isDuplicate,
          tags: r.tags,
          barcode: r.barcode,
          clearBarcode: r.barcode == null,
        ),
      );
      _recompute(emit);
    }
  }

  void _onUpdateName(
    UpdateNameEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onUpdateDescription(
    UpdateDescriptionEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onUpdateServings(
    UpdateServingsCountEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        servingsCount: event.servingsCount,
        clearServingsCount: event.servingsCount == null,
      ),
    );
  }

  void _onAddIngredient(
    AddIngredientEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    final convertedG = _computeUseCase.convertAmountToGrams(
          amount: event.amount,
          unit: event.unit,
          servingQuantityG: event.meal.servingQuantity,
        ) ??
        0;
    final newIngredient = RecipeIngredientEntity(
      snapshotMeal: event.meal,
      amount: event.amount,
      unit: event.unit,
      convertedAmountG: convertedG,
    );
    emit(
      state.copyWith(ingredients: [...state.ingredients, newIngredient]),
    );
    _recompute(emit);
  }

  void _onUpdateIngredient(
    UpdateIngredientEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    if (event.index < 0 || event.index >= state.ingredients.length) return;
    final old = state.ingredients[event.index];
    final convertedG = _computeUseCase.convertAmountToGrams(
          amount: event.amount,
          unit: event.unit,
          servingQuantityG: old.snapshotMeal.servingQuantity,
        ) ??
        0;
    final updated = old.copyWith(
      amount: event.amount,
      unit: event.unit,
      convertedAmountG: convertedG,
    );
    final newList = List<RecipeIngredientEntity>.from(state.ingredients);
    newList[event.index] = updated;
    emit(state.copyWith(ingredients: newList));
    _recompute(emit);
  }

  void _onRemoveIngredient(
    RemoveIngredientEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    if (event.index < 0 || event.index >= state.ingredients.length) return;
    final newList = List<RecipeIngredientEntity>.from(state.ingredients)
      ..removeAt(event.index);
    emit(state.copyWith(ingredients: newList));
    _recompute(emit);
  }

  void _onUpdateTotalWeight(
    UpdateTotalWeightEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    emit(
      state.copyWith(
        totalWeightG: event.totalWeightG,
        totalWeightOverridden: true,
      ),
    );
    _recompute(emit);
  }

  void _recompute(Emitter<RecipeBuilderState> emit) {
    final result = _computeUseCase.compute(
      state.ingredients,
      totalWeightOverride:
          state.totalWeightOverridden ? state.totalWeightG : null,
    );
    emit(
      state.copyWith(
        totalWeightG: result.totalWeightG,
        aggregatedNutrimentsPer100: result.perHundredG,
      ),
    );
  }

  Future<void> _onSave(
    SaveRecipeEvent event,
    Emitter<RecipeBuilderState> emit,
  ) async {
    final trimmedName = state.name.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(saveError: SaveError.nameRequired));
      return;
    }
    if (state.ingredients.isEmpty) {
      emit(state.copyWith(saveError: SaveError.needsIngredients));
      return;
    }
    if (state.totalWeightG <= 0) {
      emit(state.copyWith(saveError: SaveError.invalidTotalWeight));
      return;
    }
    final trimmedBarcode = state.barcode?.trim();
    final normalizedBarcode =
        (trimmedBarcode == null || trimmedBarcode.isEmpty)
            ? null
            : trimmedBarcode;
    if (normalizedBarcode != null && !_isBarcodeValid(normalizedBarcode)) {
      emit(state.copyWith(saveError: SaveError.invalidBarcode));
      return;
    }
    if (normalizedBarcode != null &&
        !_isEan13CheckDigitValid(normalizedBarcode)) {
      emit(state.copyWith(saveError: SaveError.invalidEan13CheckDigit));
      return;
    }

    emit(state.copyWith(isSaving: true, clearSaveError: true));
    try {
      final now = DateTime.now();
      final recipe = RecipeEntity(
        id: state.id ?? IdGenerator.getUniqueID(),
        name: trimmedName,
        description: state.description?.trim().isEmpty ?? true
            ? null
            : state.description?.trim(),
        ingredients: state.ingredients,
        totalWeightG: state.totalWeightG,
        aggregatedNutrimentsPer100: state.aggregatedNutrimentsPer100,
        createdAt: state.isExistingRecipe ? now : now,
        updatedAt: now,
        servingsCount: state.servingsCount,
        tags: state.tags,
        barcode: normalizedBarcode,
      );
      await _saveUseCase.save(
        recipe,
        totalWeightOverridden: state.totalWeightOverridden,
      );
      emit(state.copyWith(isSaving: false, didSave: true));
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          saveError: SaveError.unknown,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
