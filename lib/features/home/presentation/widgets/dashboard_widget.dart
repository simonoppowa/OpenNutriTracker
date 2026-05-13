import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
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

  const DashboardWidget({
    super.key,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  @override
  Widget build(BuildContext context) {
    double kcalValue = 0;
    double gaugeValue = 0;
    String kcalLabelText = S.of(context).kcalLeftLabel;

    if (widget.totalKcalLeft > widget.totalKcalDaily) {
      kcalValue = widget.totalKcalDaily;
      gaugeValue = 0;
    } else if (widget.totalKcalLeft < 0) {
      kcalValue = widget.totalKcalLeft.abs();
      gaugeValue = 1;
      kcalLabelText = S.of(context).kcalTooMuchLabel;
    } else {
      kcalValue = widget.totalKcalLeft;
      gaugeValue = (widget.totalKcalDaily - widget.totalKcalLeft) /
          widget.totalKcalDaily;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: S.of(context).sourcesIconTooltip,
                  icon: Icon(
                    Icons.info_outline,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SourcesScreen(),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Text(
                        '${widget.totalKcalSupplied.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        S.of(context).suppliedLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                  CircularPercentIndicator(
                    radius: 90.0,
                    lineWidth: 13.0,
                    animation: true,
                    percent: gaugeValue,
                    arcType: ArcType.FULL,
                    progressColor: Theme.of(context).colorScheme.primary,
                    arcBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(50),
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedFlipCounter(
                          duration: const Duration(milliseconds: 1000),
                          value: kcalValue.toInt(),
                          textStyle: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -1,
                              ),
                        ),
                        Text(
                          kcalLabelText,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      Text(
                        '${widget.totalKcalBurned.toInt()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        S.of(context).burnedLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
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
                totalProteinsGoal: widget.totalProteinsGoal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
