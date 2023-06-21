import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_item_type.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProductItemCard extends StatelessWidget {
  final AddItemType addItemType;
  final ProductEntity productEntity;

  const ProductItemCard(
      {Key? key, required this.productEntity, required this.addItemType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        child: SizedBox(
          height: 100,
          child: Center(
              child: ListTile(
            leading: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              backgroundImage: CachedNetworkImageProvider(
                  productEntity.thumbnailImageUrl ?? ""),
            ),
            title: Text(productEntity.productName ?? "?",
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.fade),
            subtitle: productEntity.productQuantity != null
                ? Text(
                    '${productEntity.productQuantity}${productEntity.productUnit ?? S.of(context).gramMilliliterUnit}',
                    style: Theme.of(context).textTheme.titleMedium)
                : const SizedBox(),
            trailing: IconButton(
              style: IconButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer),
              icon: const Icon(Icons.add_outlined),
              onPressed: () {},
            ),
          )),
        ),
        onTap: () => _onItemPressed(context),
      ),
    );
  }

  void _onItemPressed(BuildContext context) {
    Navigator.of(context).pushNamed(NavigationOptions.itemDetailRoute,
        arguments: MealDetailScreenArguments(
            productEntity, addItemType.getIntakeType()));
  }
}
