import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class ItemDetailMacroNutrients extends StatelessWidget {
  final String typeString;
  final double? value;

  const ItemDetailMacroNutrients(
      {Key? key, required this.typeString, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${value?.roundToPrecision(1) ?? "?"} g',
            style: Theme.of(context).textTheme.headline6),
        Text(
          typeString,
          style: Theme.of(context).textTheme.bodyText2,
        )
      ],
    );
  }
}
