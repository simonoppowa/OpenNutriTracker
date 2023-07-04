import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'products_event.dart';

part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final log = Logger('ProductsBloc');

  final SearchProductsUseCase _searchProductUseCase;

  String _searchString = "";

  ProductsBloc(this._searchProductUseCase) : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      if (event.searchString != _searchString) {
        _searchString = event.searchString;
        emit(ProductsLoadingState());
        try {
          final result = await _searchProductUseCase
              .searchOFFProductsByString(_searchString);
          emit(ProductsLoadedState(products: result));
        } catch (error) {
          log.severe(error);
          emit(ProductsFailedState());
        }
      }
    });
    on<RefreshProductsEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final result = await _searchProductUseCase
            .searchOFFProductsByString(_searchString);
        emit(ProductsLoadedState(products: result));
      } catch (error) {
        log.severe(error);
        emit(ProductsFailedState());
      }
    });
  }
}
