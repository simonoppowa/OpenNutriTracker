import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'food_event.dart';

part 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final log = Logger('FoodBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";

  FoodBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(FoodInitial()) {
    on<LoadFoodEvent>((event, emit) async {
      if (event.searchString != _searchString) {
        _searchString = event.searchString;
        emit(FoodLoadingState());
        try {
          final result = await _searchProductUseCase.searchFDCFoodByString(
            _searchString,
          );
          final config = await _getConfigUsecase.getConfig();

          emit(
            FoodLoadedState(
              food: result,
              usesImperialUnits: config.usesImperialUnits,
            ),
          );
        } catch (error) {
          log.severe(error);
          emit(FoodFailedState());
        }
      }
    });
    on<RefreshFoodEvent>((event, emit) async {
      emit(FoodLoadingState());
      try {
        final result = await _searchProductUseCase.searchFDCFoodByString(
          _searchString,
        );
        emit(FoodLoadedState(food: result));
      } catch (error) {
        log.severe(error);
        emit(FoodFailedState());
      }
    });
  }
}
