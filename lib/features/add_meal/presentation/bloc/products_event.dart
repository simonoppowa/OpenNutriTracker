part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductsEvent {
  final String searchString;

  const LoadProductsEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class RefreshProductsEvent extends ProductsEvent {
  const RefreshProductsEvent();

  @override
  List<Object?> get props => [];
}
