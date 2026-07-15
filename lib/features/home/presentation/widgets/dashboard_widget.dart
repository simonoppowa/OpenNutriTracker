import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

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
    final usesKilojoules = context.watch<EnergyUnitProvider>().usesKilojoules;
    String kcalLabelText = usesKilojoules
        ? '${S.of(context).kjLabel} ${S.of(context).energyLeftLabel}'
        : S.of(context).kcalLeftLabel;

    if (widget.totalKcalLeft > widget.totalKcalDaily) {
      kcalValue = widget.totalKcalDaily;
      gaugeValue = 0;
    } else if (widget.totalKcalLeft < 0) {
      kcalValue = widget.totalKcalLeft.abs();
      gaugeValue = 1;
      kcalLabelText = usesKilojoules
          ? '${S.of(context).kjLabel} ${S.of(context).energyTooMuchLabel}'
          : S.of(context).kcalTooMuchLabel;
    } else {
      kcalValue = widget.totalKcalLeft;
      gaugeValue =
          (widget.totalKcalDaily - widget.totalKcalLeft) / widget.totalKcalDaily;
    }
    final displayValue = usesKilojoules ? UnitCalc.kcalToKj(kcalValue) : kcalValue;
    final displaySupplied = usesKilojoules
        ? UnitCalc.kcalToKj(widget.totalKcalSupplied)
        : widget.totalKcalSupplied;
    final displayBurned = usesKilojoules
        ? UnitCalc.kcalToKj(widget.totalKcalBurned)
        : widget.totalKcalBurned;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimens.spacing16, Dimens.spacing8, Dimens.spacing16, Dimens.spacing4),
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(Dimens.spacing24, Dimens.spacing20, Dimens.spacing24, Dimens.spacing24),
            child: Column(
              children: [
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.arrow_downward_rounded,
                      value: '${displaySupplied.toInt()}',
                      label: S.of(context).suppliedLabel,
                      color: palette.proteinColor,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SourcesScreen()),
                      ),
                      child: Icon(Icons.info_outline_rounded, color: palette.textMuted, size: 22),
                    ),
                    const Spacer(),
                    _MiniStat(
                      icon: Icons.local_fire_department_rounded,
                      value: '${displayBurned.toInt()}',
                      label: S.of(context).burnedLabel,
                      color: palette.carbsColor,
                      trailing: true,
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing16),
                Semantics(
                  label: '${displayValue.toInt()} $kcalLabelText',
                  excludeSemantics: true,
                  child: CircularPercentIndicator(
                  radius: 90,
                  lineWidth: 16,
                  percent: gaugeValue.clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 800,
                  curve: AppMotion.emphasized,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: palette.surfaceMuted,
                  progressColor: Theme.of(context).colorScheme.primary,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 800),
                        curve: AppMotion.emphasized,
                        value: displayValue.toInt(),
                        textStyle: textTheme.displaySmall?.copyWith(height: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(kcalLabelText, style: textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Row(
            children: [
              Expanded(
                child: _MacroTile(
                  label: S.of(context).carbsLabel,
                  intake: widget.totalCarbsIntake,
                  goal: widget.totalCarbsGoal,
                  color: palette.carbs,
                  palette: palette,
                ),
              ),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: _MacroTile(
                  label: S.of(context).fatLabel,
                  intake: widget.totalFatsIntake,
                  goal: widget.totalFatsGoal,
                  color: palette.fat,
                  palette: palette,
                ),
              ),
              const SizedBox(width: Dimens.spacing12),
              Expanded(
                child: _MacroTile(
                  label: S.of(context).proteinLabel,
                  intake: widget.totalProteinsIntake,
                  goal: widget.totalProteinsGoal,
                  color: palette.protein,
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool trailing;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: trailing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: textTheme.titleMedium),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double intake;
  final double goal;
  final Color color;
  final AppPalette palette;

  const _MacroTile({
    required this.label,
    required this.intake,
    required this.goal,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pct = (goal <= 0) ? 0.0 : (intake / goal).clamp(0.0, 1.0);
    return AppCard(
      borderRadius: Dimens.radiusM,
      padding: const EdgeInsets.fromLTRB(Dimens.spacing16, Dimens.spacing16, Dimens.spacing16, Dimens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: textTheme.labelMedium)),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: palette.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: Dimens.spacing12),
          Text(
            '${intake.toInt()}/${goal.toInt()} g',
            style: textTheme.bodySmall?.copyWith(color: palette.textStrong, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
