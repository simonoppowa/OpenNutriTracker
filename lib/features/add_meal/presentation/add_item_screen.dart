import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_item_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/item_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/product_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late AddItemType itemType;

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;

  late TabController _tabController;

  @override
  void initState() {
    _productsBloc = ProductsBloc();
    _foodBloc = FoodBloc();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Update search results when tab changes
      _onSearchSubmit(_searchStringListener.value);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as AddItemScreenArguments;
    itemType = args.itemType;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(itemType.getTypeName(context))),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ItemSearchBar(
                searchStringListener: _searchStringListener,
                onSearchSubmit: _onSearchSubmit,
                onBarcodePressed: _onBarcodeIconPressed,
              ),
              const SizedBox(height: 16.0),
              TabBar(
                  tabs: [
                    Tab(text: S.of(context).searchProductsPage),
                    Tab(text: S.of(context).searchFoodPage)
                  ],
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<ProductsBloc, ProductsState>(
                        bloc: _productsBloc,
                        builder: (context, state) {
                          if (state is ProductsInitial) {
                            return Text(S.of(context).searchDefaultLabel);
                          } else if (state is ProductsLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is ProductsLoadedState) {
                            return state.products.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.products.length,
                                        itemBuilder: (context, index) {
                                          return ProductItemCard(
                                              productEntity:
                                                  state.products[index],
                                              addItemType: itemType);
                                        }))
                                : const NoResultsWidget();
                          } else if (state is ProductsFailedState) {
                            return ErrorDialog(
                                errorText:
                                    S.of(context).errorFetchingProductData);
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<FoodBloc, FoodState>(
                        bloc: _foodBloc,
                        builder: (context, state) {
                          if (state is FoodInitial) {
                            return Text(S.of(context).searchDefaultLabel);
                          } else if (state is FoodLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is FoodLoadedState) {
                            return state.food.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.food.length,
                                        itemBuilder: (context, index) {
                                          return ProductItemCard(
                                              productEntity: state.food[index],
                                              addItemType: itemType);
                                        }))
                                : const NoResultsWidget();
                          } else if (state is ProductsFailedState) {
                            return ErrorDialog(
                                errorText:
                                    S.of(context).errorFetchingProductData);
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                ]),
              )
            ],
          ),
        ));
  }

  void _onSearchSubmit(String inputText) {
    if (_tabController.index == 0) {
      _productsBloc.add(LoadProductsEvent(searchString: inputText));
    } else {
      _foodBloc.add(LoadFoodEvent(searchString: inputText));
    }
  }

  void _onBarcodeIconPressed() {
    Navigator.of(context).pushNamed(NavigationOptions.scannerRoute,
        arguments: ScannerScreenArguments(itemType.getIntakeType()));
  }
}

class AddItemScreenArguments {
  final AddItemType itemType;

  AddItemScreenArguments(this.itemType);
}
