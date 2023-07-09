import 'package:flutter/material.dart';

class DefaultMealImage extends StatelessWidget {
  const DefaultMealImage({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        width: 120,
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          Icons.restaurant_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      );
}
