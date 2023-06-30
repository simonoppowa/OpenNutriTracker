import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DashboardWidget extends StatefulWidget {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const DashboardWidget(
      {Key? key,
      required this.totalKcalSupplied,
      required this.totalKcalBurned,
      required this.totalKcalDaily,
      required this.totalKcalLeft,
      required this.totalCarbsIntake,
      required this.totalFatsIntake,
      required this.totalProteinsIntake,
      required this.totalCarbsGoal,
      required this.totalFatsGoal,
      required this.totalProteinsGoal})
      : super(key: key);

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  @override
  Widget build(BuildContext context) {
    double kcalLeftLabel = 0;
    double gaugeValue = 0;
    if (widget.totalKcalLeft > widget.totalKcalDaily) {
      kcalLeftLabel = widget.totalKcalDaily;
      gaugeValue = 0;
    } else if (widget.totalKcalLeft < 0) {
      kcalLeftLabel = 0;
      gaugeValue = 1;
    } else {
      kcalLeftLabel = widget.totalKcalLeft;
      gaugeValue = (widget.totalKcalDaily - widget.totalKcalLeft) /
          widget.totalKcalDaily;
    }
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_up_outlined),
                    Text('${widget.totalKcalSupplied.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(S.of(context).suppliedLabel,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                CircularPercentIndicator(
                  radius: 90.0,
                  lineWidth: 13.0,
                  animation: true,
                  percent: gaugeValue,
                  arcType: ArcType.FULL,
                  progressColor: Theme.of(context).colorScheme.primary,
                  arcBackgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(50),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(kcalLeftLabel.toInt().toString(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
                      Text(
                        S.of(context).kcalLeftLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_down_outlined),
                    Text('${widget.totalKcalBurned.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(S.of(context).burnedLabel,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ],
            ),
            MacroNutrientsView(
                totalCarbsIntake: widget.totalCarbsIntake,
                totalFatsIntake: widget.totalFatsIntake,
                totalProteinsIntake: widget.totalProteinsIntake,
                totalCarbsGoal: widget.totalCarbsGoal,
                totalFatsGoal: widget.totalFatsGoal,
                totalProteinsGoal: widget.totalProteinsGoal),
          ],
        ),
      ),
    );
  }
}
