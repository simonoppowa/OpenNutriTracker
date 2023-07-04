import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddItemBottomSheet extends StatelessWidget {
  const AddItemBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            S.of(context).addItemLabel,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).activityLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).activityExample,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.sports_baseball_outlined)),
          onTap: () {
            _showAddActivityScreen(context);
          },
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          title: Text(
            S.of(context).breakfastLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).breakfastExample,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.bakery_dining_outlined)),
          onTap: () {
            _showAddItemScreen(context, AddMealType.breakfastType);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).lunchLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).lunchExample,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.lunch_dining_outlined)),
          onTap: () {
            _showAddItemScreen(context, AddMealType.lunchType);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).dinnerLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).dinnerExample,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.dinner_dining_outlined)),
          onTap: () {
            _showAddItemScreen(context, AddMealType.dinnerType);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).snackLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            S.of(context).snackExample,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(CustomIcons.food_apple_outline)),
          onTap: () {
            _showAddItemScreen(context, AddMealType.snackType);
          },
        ),
      ],
    );
  }

  void _showAddItemScreen(BuildContext context, AddMealType itemType) {
    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).pushNamed(NavigationOptions.addMealRoute,
        arguments: AddMealScreenArguments(itemType));
  }

  void _showAddActivityScreen(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(NavigationOptions.addActivityRoute);
  }
}
