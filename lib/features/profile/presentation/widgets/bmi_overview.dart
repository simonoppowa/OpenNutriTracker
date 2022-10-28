import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class BMIOverview extends StatelessWidget {
  const BMIOverview({Key? key}) : super(key: key);

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
                '23',
                style: Theme.of(context).textTheme.headline3,
              ),
              Text(S.of(context).bmiLabel,
                  style: Theme.of(context).textTheme.headline6)
            ],
          ),
        ),
        Text('Normal Weight',
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center),
      ],
    );
  }
}
