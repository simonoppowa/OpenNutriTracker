import 'package:equatable/equatable.dart';
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
    on<UpdateImagePathEvent>((event, emit) {
      emit(state.copyWith(
        imagePath: event.imagePath,
        clearImagePath: event.imagePath == null,
      ));
    });
    on<AddIngredientEvent>(_onAddIngredient);
    on<UpdateIngredientEvent>(_onUpdateIngredient);
    on<RemoveIngredientEvent>(_onRemoveIngredient);
    on<UpdateTotalWeightEvent>(_onUpdateTotalWeight);
    on<SaveRecipeEvent>(_onSave);
  }


  void _onInitialize(
    InitializeBuilderEvent event,
    Emitter<RecipeBuilderState> emit,
  ) {
    if (event.existing == null) {
      // Generate the recipe id eagerly so any photo the user attaches
      // before they hit save can be filed under the correct filename
      // (recipe_images/<id>.webp). The id is still kept on save below.
      emit(RecipeBuilderState.initial().copyWith(
        id: IdGenerator.getUniqueID(),
      ));
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
          // Duplicates start without an image — the photo is tied to the
          // original recipe id and copying it isn't worth the disk churn
          // here. The user can attach a fresh photo to the new recipe.
          imagePath: isDuplicate ? null : r.imagePath,
          clearImagePath: isDuplicate ? true : (r.imagePath == null),
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
        imagePath: state.imagePath,
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
