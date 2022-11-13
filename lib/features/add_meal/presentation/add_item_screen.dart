import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/addItem/presentation/add_item_type.dart';
import 'package:opennutritracker/features/addItem/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/addItem/presentation/widgets/item_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/addItem/presentation/widgets/product_item_card.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late AddItemType itemType;

  late ProductsBloc _productsBloc;

  @override
  void initState() {
    _productsBloc = ProductsBloc();
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
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(itemType.getTypeName(context))),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ItemSearchBar(
                onSearchSubmit: _onSearchSubmit,
                onBarcodePressed: _onBarcodeIconPressed,
              ),
              const SizedBox(height: 32.0),
              Container(
                  padding: const EdgeInsets.only(left: 8.0),
                  alignment: Alignment.centerLeft,
                  child: Text(S.of(context).searchResultsLabel,
                      style: Theme.of(context).textTheme.headline5)),
              BlocBuilder<ProductsBloc, ProductsState>(
                bloc: _productsBloc,
                builder: (context, state) {
                  if (state is ProductsInitial) {
                    return Text(S.of(context).searchDefaultLabel);
                  } else if (state is ProductsLoadingState) {
                    return const CircularProgressIndicator();
                  } else if (state is ProductsLoadedState) {
                    return Flexible(
                        child: ListView.builder(
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              return ProductItemCard(
                                  productEntity: state.products[index],
                                  addItemType: itemType);
                            }));
                  } else {
                    return const SizedBox();
                  }
                },
              )
            ],
          ),
        ));
  }

  void _onSearchSubmit(String inputText) {
    _productsBloc.add(LoadProductsEvent(searchString: inputText));
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
