import 'package:flutter/material.dart';

class MealPlaceholder extends StatelessWidget {
  const MealPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer),
      child: Icon(
        Icons.restaurant_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }
}
