import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class ProductItemCard extends StatelessWidget {
  final ProductEntity productEntity;

  const ProductItemCard({Key? key, required this.productEntity})
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
                style: Theme.of(context).textTheme.headline6,
                maxLines: 2,
                overflow: TextOverflow.fade),
            subtitle: Text(productEntity.productQuantityFormatted ?? "",
                style: Theme.of(context).textTheme.subtitle1),
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
    Navigator.of(context).pushNamed(NavigationOptions.itemDetailRoute);
  }
}
