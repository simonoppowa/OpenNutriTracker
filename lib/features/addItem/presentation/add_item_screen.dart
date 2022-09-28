import 'package:flutter/material.dart';
import 'package:opennutritracker/features/addItem/presentation/add_item_type.dart';
import 'package:opennutritracker/features/addItem/presentation/widgets/item_search_bar.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({Key? key}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late AddItemType itemType;

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
              const ItemSearchBar(),
              const SizedBox(height: 32.0),
              Container(
                  padding: const EdgeInsets.only(left: 8.0),
                  alignment: Alignment.centerLeft,
                  child: Text(S.of(context).searchResultsLabel,
                      style: Theme.of(context).textTheme.headline5)),
            ],
          ),
        ));
  }
}

class AddItemScreenArguments {
  final AddItemType itemType;

  AddItemScreenArguments(this.itemType);
}
