part of 'recipe_builder_bloc.dart';

enum SaveError {
  nameRequired,
  needsIngredients,
  invalidTotalWeight,
  unknown,
}

class RecipeBuilderState extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final int? servingsCount;
  final List<RecipeIngredientEntity> ingredients;
  final double totalWeightG;
  final bool totalWeightOverridden;
  final MealNutrimentsEntity aggregatedNutrimentsPer100;
  final List<String> tags;
  final String? imagePath;
  final bool isExistingRecipe;
  final bool isSaving;
  final bool didSave;
  final SaveError? saveError;
  final String? errorMessage;

  const RecipeBuilderState({
    required this.id,
    required this.name,
    required this.description,
    required this.servingsCount,
    required this.ingredients,
    required this.totalWeightG,
    required this.totalWeightOverridden,
    required this.aggregatedNutrimentsPer100,
    required this.tags,
    required this.imagePath,
    required this.isExistingRecipe,
    required this.isSaving,
    required this.didSave,
    required this.saveError,
    required this.errorMessage,
  });

  factory RecipeBuilderState.initial() => RecipeBuilderState(
        id: null,
        name: '',
        description: null,
        servingsCount: null,
        ingredients: const [],
        totalWeightG: 0,
        totalWeightOverridden: false,
        aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
        tags: const [],
        imagePath: null,
        isExistingRecipe: false,
        isSaving: false,
        didSave: false,
        saveError: null,
        errorMessage: null,
      );

  RecipeBuilderState copyWith({
    String? id,
    String? name,
    String? description,
    int? servingsCount,
    List<RecipeIngredientEntity>? ingredients,
    double? totalWeightG,
    bool? totalWeightOverridden,
    MealNutrimentsEntity? aggregatedNutrimentsPer100,
    List<String>? tags,
    String? imagePath,
    bool? isExistingRecipe,
    bool? isSaving,
    bool? didSave,
    SaveError? saveError,
    String? errorMessage,
    bool clearServingsCount = false,
    bool clearSaveError = false,
    bool clearImagePath = false,
  }) {
    return RecipeBuilderState(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servingsCount:
          clearServingsCount ? null : (servingsCount ?? this.servingsCount),
      ingredients: ingredients ?? this.ingredients,
      totalWeightG: totalWeightG ?? this.totalWeightG,
      totalWeightOverridden:
          totalWeightOverridden ?? this.totalWeightOverridden,
      aggregatedNutrimentsPer100:
          aggregatedNutrimentsPer100 ?? this.aggregatedNutrimentsPer100,
      tags: tags ?? this.tags,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isExistingRecipe: isExistingRecipe ?? this.isExistingRecipe,
      isSaving: isSaving ?? this.isSaving,
      didSave: didSave ?? this.didSave,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        servingsCount,
        ingredients,
        totalWeightG,
        totalWeightOverridden,
        aggregatedNutrimentsPer100,
        tags,
        imagePath,
        isExistingRecipe,
        isSaving,
        didSave,
        saveError,
        errorMessage,
      ];
}
