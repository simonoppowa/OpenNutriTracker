import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MacroNutrientsView extends StatefulWidget {
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const MacroNutrientsView({
    super.key,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
  });

  @override
  State<MacroNutrientsView> createState() => _MacroNutrientsViewState();
}

class _MacroNutrientsViewState extends State<MacroNutrientsView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MacroRing(
          intake: widget.totalCarbsIntake,
          goal: widget.totalCarbsGoal,
          label: S.of(context).carbsLabel,
          color: palette.carbs,
          palette: palette,
        ),
        _MacroRing(
          intake: widget.totalFatsIntake,
          goal: widget.totalFatsGoal,
          label: S.of(context).fatLabel,
          color: palette.fat,
          palette: palette,
        ),
        _MacroRing(
          intake: widget.totalProteinsIntake,
          goal: widget.totalProteinsGoal,
          label: S.of(context).proteinLabel,
          color: palette.protein,
          palette: palette,
        ),
      ],
    );
  }
}

class _MacroRing extends StatelessWidget {
  final double intake;
  final double goal;
  final String label;
  final Color color;
  final AppPalette palette;

  const _MacroRing({
    required this.intake,
    required this.goal,
    required this.label,
    required this.color,
    required this.palette,
  });

  double get _percent {
    if (intake <= 0 || goal <= 0) {
      return 0;
    } else if (intake > goal) {
      return 1;
    } else {
      return intake / goal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 15.0,
          lineWidth: 6.0,
          animation: true,
          percent: _percent,
          progressColor: color,
          backgroundColor: palette.surfaceMuted,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        Padding(
          padding: const EdgeInsets.all(Dimens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${intake.toInt()}/${goal.toInt()} g',
                style: textTheme.titleSmall?.copyWith(
                  color: palette.textStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
