import 'package:flutter/material.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class ProductItemCard extends StatelessWidget {
  const ProductItemCard({Key? key}) : super(key: key);

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
            leading: FlutterLogo(size: 80),
            title: Text('Lorem ipsum', // TODO remove
                style: Theme.of(context).textTheme.headline6,
                maxLines: 2,
                overflow: TextOverflow.fade),
            subtitle: Text('100g, 400 kcal',
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
      ),
    );
  }
}
