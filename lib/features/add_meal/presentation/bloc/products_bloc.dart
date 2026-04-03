import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'products_event.dart';

part 'products_state.dart';


class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final log = Logger('ProductsBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";


  Future<List<MealEntity>> searchByString(String searchString, ConfigEntity config) async {
    List<MealEntity> result;

    if(!config.useLocalDataBase || (config.localDatabaseFile == null)) {
      result = await _searchProductUseCase.searchOFFProductsByString(
        searchString,
      );
    } else {
      result = await _searchProductUseCase.searchLocalOFFProductsByString(
        searchString,
        config.localDatabaseFile!
      );
    }

    return result;
  }

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      if (event.searchString != _searchString) {
        _searchString = event.searchString;
        emit(ProductsLoadingState());
        try {
          final config = await _getConfigUsecase.getConfig();

          final result = await searchByString(_searchString, config);

          emit(
            ProductsLoadedState(
              products: result,
              usesImperialUnits: config.usesImperialUnits,
            ),
          );
        } catch (error) {
          log.severe(error);
          emit(ProductsFailedState());
        }
      }
    });
    on<RefreshProductsEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final config = await _getConfigUsecase.getConfig();

        final result = await searchByString(_searchString, config);

        emit(ProductsLoadedState(products: result));
      } catch (error) {
        log.severe(error);
        emit(ProductsFailedState());
      }
    });
  }
}
