import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/generated/l10n.dart';

class BMIOverview extends StatelessWidget {
  final double bmiValue;
  final String statusName;

  const BMIOverview({Key? key, required this.bmiValue, required this.statusName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(36.0),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer),
          child: Column(
            children: [
              Text(
                '${bmiValue.roundToPrecision(1)}',
                style: Theme.of(context).textTheme.headline3,
              ),
              Text(S.of(context).bmiLabel,
                  style: Theme.of(context).textTheme.headline6)
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Text(statusName,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center),
      ],
    );
  }
}
