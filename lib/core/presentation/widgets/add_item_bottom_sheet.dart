import 'package:flutter/material.dart';
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
                .headline6
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).activityLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).activityExample,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.sports_baseball_outlined)),
        ),
        const Divider(indent: 16),
        ListTile(
          title: Text(
            S.of(context).breakfastLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).breakfastExample,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.bakery_dining_outlined)),
        ),
        ListTile(
          title: Text(
            S.of(context).lunchLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).lunchExample,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.lunch_dining_outlined)),
        ),
        ListTile(
          title: Text(
            S.of(context).dinnerLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).dinnerExample,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.dinner_dining_outlined)),
        ),
        ListTile(
          title: Text(
            S.of(context).snackLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).snackExample,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          // ignore: sized_box_for_whitespace
          leading: Container(
              height: double.infinity,
              child: const Icon(Icons.icecream_outlined)),
        ),
      ],
    );
  }
}
