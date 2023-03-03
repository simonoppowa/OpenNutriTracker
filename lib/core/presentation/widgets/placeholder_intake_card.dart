import 'package:flutter/material.dart';

class PlaceholderIntakeCard extends StatelessWidget {
  final IconData icon;

  const PlaceholderIntakeCard({Key? key, required this.icon}) : super(key: key);

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
        child: Icon(icon,
            size: 36, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
