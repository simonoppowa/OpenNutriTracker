import 'package:flutter/material.dart';
import 'package:opennutritracker/features/addItem/presentation/add_item_type.dart';

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
        appBar: AppBar(title: Text(itemType.typeName)),
        body: const Center(child: Text('Add Item Body')));
  }
}

class AddItemScreenArguments {
  final AddItemType itemType;

  AddItemScreenArguments(this.itemType);
}
