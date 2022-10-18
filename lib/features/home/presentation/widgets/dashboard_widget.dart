import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({Key? key}) : super(key: key);

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
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
                    Text("1056", style: Theme.of(context).textTheme.headline6),
                    Text(S.of(context).suppliedLabel,
                        style: Theme.of(context).textTheme.subtitle2),
                  ],
                ),
                CircularPercentIndicator(
                  radius: 90.0,
                  lineWidth: 13.0,
                  animation: true,
                  percent: 0.7,
                  arcType: ArcType.FULL,
                  progressColor: Theme.of(context).colorScheme.primary,
                  arcBackgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(50),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("1542",
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
                      Text(
                        S.of(context).kcalLeftLabel,
                        style: Theme.of(context).textTheme.subtitle1,
                      )
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_down_outlined),
                    Text("153", style: Theme.of(context).textTheme.headline6),
                    Text(S.of(context).burnedLabel,
                        style: Theme.of(context).textTheme.subtitle2),
                  ],
                ),
              ],
            ),
            const MacroNutrientsView(),
          ],
        ),
      ),
    );
  }
}
