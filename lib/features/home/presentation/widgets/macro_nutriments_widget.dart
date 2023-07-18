import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MacroNutrientsView extends StatefulWidget {
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const MacroNutrientsView(
      {Key? key,
      required this.totalCarbsIntake,
      required this.totalFatsIntake,
      required this.totalProteinsIntake,
      required this.totalCarbsGoal,
      required this.totalFatsGoal,
      required this.totalProteinsGoal})
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
              percent: getGoalPercentage(
                  widget.totalCarbsGoal, widget.totalCarbsIntake),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withAlpha(50),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Text(
                    '${widget.totalCarbsIntake.toInt()}/${widget.totalCarbsGoal.toInt()} g',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    S.of(context).carbsLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
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
              percent: getGoalPercentage(
                  widget.totalFatsGoal, widget.totalFatsIntake),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withAlpha(50),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Text(
                    "${widget.totalFatsIntake.toInt()}/${widget.totalFatsGoal.toInt()} g",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(S.of(context).fatLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface)),
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
              percent: getGoalPercentage(
                  widget.totalProteinsGoal, widget.totalProteinsIntake),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withAlpha(50),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Text(
                    "${widget.totalProteinsIntake.toInt()}/${widget.totalProteinsGoal.toInt()} g",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    S.of(context).proteinLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  double getGoalPercentage(double goal, double supplied) {
    if (supplied <= 0 || goal <= 0) {
      return 0;
    } else if (supplied > goal) {
      return 1;
    } else {
      return supplied / goal;
    }
  }
}
