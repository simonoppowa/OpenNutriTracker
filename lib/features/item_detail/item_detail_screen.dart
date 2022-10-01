import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';
import 'package:opennutritracker/features/item_detail/presentation/widgets/item_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/item_detail/presentation/widgets/item_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/item_detail/presentation/widgets/item_detail_nutriments_table.dart';
import 'package:opennutritracker/features/item_detail/presentation/widgets/item_info_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({Key? key}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final log = Logger('ItemDetailScreen');

  late ProductEntity product;
  late TextEditingController quantityTextController;

  late String totalQuantityText;

  @override
  void initState() {
    quantityTextController = TextEditingController();
    quantityTextController.text = '100';
    totalQuantityText = '100';
    quantityTextController.addListener(() {
      _onQuantityChanged(quantityTextController.text);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ItemDetailScreenArguments;
    product = args.productEntity;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${product.productName} (${product.brands}) [${product.productQuantity?.toInt()}${product.productUnit ?? "g/ml"}]')),
      body: ListView(
        children: [
          CachedNetworkImage(
            imageUrl: product.mainImageUrl ?? "",
            imageBuilder: (context, imageProvider) {
              return Container(
                height: 300,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                        '${product.nutriments.energyKcal100?.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headline5),
                    Text(' / $totalQuantityText ${product.productUnit}')
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).carbsLabel,
                        value: product.nutriments.carbohydrates100g),
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).fatLabel,
                        value: product.nutriments.fat100g),
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).proteinLabel,
                        value: product.nutriments.proteins100g)
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16.0),
                ItemDetailNutrimentsTable(product: product),
                const SizedBox(height: 32.0),
                ItemInfoButton(url: product.url ?? OFFConst.offWebsiteUrl),
                const SizedBox(height: 200.0) // height added to scroll
              ],
            ),
          )
        ],
      ),
      bottomSheet: ItemDetailBottomSheet(quantityTextController: quantityTextController),
    );
  }

  void _onQuantityChanged(String quantityString) {
    setState(() {
      try {
        final quantity = double.parse(quantityString);
        totalQuantityText = quantity.toInt().toString();
      } on FormatException catch(e) {
       log.warning("Error while parsing: \"$quantityString\"");
      }
    });
  }
}

class ItemDetailScreenArguments {
  final ProductEntity productEntity;

  ItemDetailScreenArguments(this.productEntity);
}
