part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  @override
  List<Object> get props => [];
}

class ProductsLoadingState extends ProductsState {
  @override
  List<Object?> get props => [];
}

class ProductsLoadedState extends ProductsState {
  final List<MealEntity> products;

  const ProductsLoadedState({required this.products});

  @override
  List<Object?> get props => [products];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
