import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealItemCard extends StatelessWidget {
  final AddMealType addMealType;
  final MealEntity mealEntity;

  const MealItemCard(
      {Key? key, required this.mealEntity, required this.addMealType})
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
            leading: ClipOval(
                child: CachedNetworkImage(
              fit: BoxFit.cover,
              width: 60,
              height: 60,
              imageUrl: mealEntity.thumbnailImageUrl ?? "",
              placeholder: (context, url) =>
                  const Icon(Icons.restaurant_outlined),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.restaurant_outlined),
            )),
            title: AutoSizeText(mealEntity.name ?? "?",
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            subtitle: mealEntity.mealQuantity != null
                ? AutoSizeText(
                    '${mealEntity.mealQuantity}${mealEntity.mealUnit ?? S.of(context).gramMilliliterUnit}',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : const SizedBox(),
            trailing: IconButton(
              style: IconButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer),
              icon: const Icon(Icons.add_outlined),
              onPressed: () => _onItemPressed(context),
            ),
          )),
        ),
        onTap: () => _onItemPressed(context),
      ),
    );
  }

  void _onItemPressed(BuildContext context) {
    Navigator.of(context).pushNamed(NavigationOptions.itemDetailRoute,
        arguments:
            MealDetailScreenArguments(mealEntity, addMealType.getIntakeType()));
  }
}
