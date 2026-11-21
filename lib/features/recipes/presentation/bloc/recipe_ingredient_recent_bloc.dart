import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_recent_ingredients_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';

/// The recipe ingredient picker's Recent tab: the foods this profile logged
/// plus the ones the saved recipes use (#516). Its own type so the add-meal
/// Recently list keeps reading only the intake log.
class RecipeIngredientRecentBloc extends RecentMealBloc {
  RecipeIngredientRecentBloc(
    GetRecentIngredientsUsecase getRecentIngredientsUsecase,
    GetConfigUsecase getConfigUsecase,
  ) : super.fromSource(
        getRecentIngredientsUsecase.getRecentIngredients,
        getConfigUsecase,
      );
}
