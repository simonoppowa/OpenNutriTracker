import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class MealDetailMacroNutrients extends StatelessWidget {
  final String typeString;
  final double? value;

  const MealDetailMacroNutrients(
      {super.key, required this.typeString, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${value?.roundToPrecision(1) ?? "?"} g',
            style: Theme.of(context).textTheme.titleLarge),
        Text(
          typeString,
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );
  }
}
