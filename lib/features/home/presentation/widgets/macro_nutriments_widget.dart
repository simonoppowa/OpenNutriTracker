import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MacroNutrientsView extends StatefulWidget {
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;

  const MacroNutrientsView(
      {Key? key,
      required this.totalCarbsIntake,
      required this.totalFatsIntake,
      required this.totalProteinsIntake})
      : super(key: key);

  @override
  State<MacroNutrientsView> createState() => _MacroNutrientsViewState();
}

class _MacroNutrientsViewState extends State<MacroNutrientsView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          children: [
            CircularPercentIndicator(
              radius: 15.0,
              lineWidth: 6.0,
              animation: true,
              percent: 0.8,
              progressColor: Theme.of(context).colorScheme.primary,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                children: [
                  Text(
                    '${widget.totalCarbsIntake.toInt()}/151 g',
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  Text(
                    S.of(context).carbsLabel,
                    style: Theme.of(context).textTheme.bodyText2,
                  )
                ],
              ),
            )
          ],
        ),
        Row(
          children: [
            CircularPercentIndicator(
              radius: 15.0,
              lineWidth: 6.0,
              animation: true,
              percent: 0.3,
              progressColor: Theme.of(context).colorScheme.primary,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                children: [
                  Text(
                    "${widget.totalFatsIntake.toInt()}/76 g",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  Text(
                    S.of(context).fatLabel,
                    style: Theme.of(context).textTheme.bodyText2,
                  )
                ],
              ),
            )
          ],
        ),
        Row(
          children: [
            CircularPercentIndicator(
              radius: 15.0,
              lineWidth: 6.0,
              animation: true,
              percent: 0.5,
              progressColor: Theme.of(context).colorScheme.primary,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                children: [
                  Text(
                    "${widget.totalProteinsIntake.toInt()}/114 g",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  Text(
                    S.of(context).proteinLabel,
                    style: Theme.of(context).textTheme.bodyText2,
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }
}
