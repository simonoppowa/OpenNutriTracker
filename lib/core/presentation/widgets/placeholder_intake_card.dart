import 'package:flutter/material.dart';

class PlaceholderIntakeCard extends StatelessWidget {
  const PlaceholderIntakeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        //elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        child: Icon(Icons.local_pizza_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
