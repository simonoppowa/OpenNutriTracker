import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/item_detail/presentation/widgets/item_detail_macro_nutrients.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({Key? key}) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Coffee')),
      body: ListView(
        children: [
          CachedNetworkImage(
            imageUrl:
                "",
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
                    Text('12 ${S.of(context).kcalLabel}', // TODO Change
                        style: Theme.of(context).textTheme.headline5),
                    Text(' / 100 g')
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).carbsLabel, value: 15),
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).fatLabel, value: 0.4),
                    ItemDetailMacroNutrients(
                        typeString: S.of(context).proteinLabel, value: 4.5)
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16.0),
              ],
            ),
          )
        ],
      ),
    );
  }
}
