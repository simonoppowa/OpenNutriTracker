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
  final bool usesImperialUnits;

  /// True when the remote OFF source returned zero results (or failed
  /// silently — e.g. rate limit). The UI uses this to show a "no results"
  /// hint below any custom-meal matches.
  final bool remoteSourceEmpty;

  /// The raw search input these results answer. The UI compares it with
  /// the current text-field value to tell "no results for what you typed"
  /// apart from "results for an older query while yours is still
  /// debouncing/in flight" — the latter shows a spinner, not "no results".
  final String query;

  const ProductsLoadedState({
    required this.products,
    this.usesImperialUnits = false,
    this.remoteSourceEmpty = false,
    this.query = '',
  });

  @override
  List<Object?> get props => [products, remoteSourceEmpty, query];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
