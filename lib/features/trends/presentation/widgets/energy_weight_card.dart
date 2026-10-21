import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/trends/domain/energy_weight_series.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Energy logged per day (bars, the average goal as a dashed line) and the
/// smoothed weight trend (line, own axis on the right) over the same days
/// (#58). The line chart lies over the bar chart; both reserve the same axis
/// space so day i sits at the same x in both, and the line runs from -0.5
/// to n - 0.5, where the bars' centres fall.
class EnergyWeightCard extends StatelessWidget {
  final EnergyWeightSeries series;
  final BodyWeightUnit bodyWeightUnit;

  const EnergyWeightCard({
    super.key,
    required this.series,
    required this.bodyWeightUnit,
  });

  static const _axisSpace = 40.0;
  static const _chartHeight = 180.0;

  double _weight(double kg) => switch (bodyWeightUnit) {
    BodyWeightUnit.kg => kg,
    BodyWeightUnit.lb => UnitCalc.kgToLbs(kg),
    BodyWeightUnit.st => kg * 2.20462 / 14,
  };

  String _weightUnit(S s) => switch (bodyWeightUnit) {
    BodyWeightUnit.kg => s.kgLabel,
    BodyWeightUnit.lb => s.lbsLabel,
    BodyWeightUnit.st => s.stLabel,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final accent = theme.colorScheme.primary;
    final weightColor = palette.protein;
    final energyUnit = EnergyDisplay.unitLabel(context);
    final days = series.days;
    final hasEnergy = days.any((d) => d.kcal != null);

    final goals = [for (final d in days) ?d.kcalGoal];
    final avgGoal = goals.isEmpty
        ? null
        : EnergyDisplay.convert(
            context,
            goals.reduce((a, b) => a + b) / goals.length,
          );
    final energies = [
      for (final d in days)
        if (d.kcal case final kcal?) EnergyDisplay.convert(context, kcal),
    ];
    final maxEnergy = [
      ...energies,
      ?avgGoal,
    ].fold<double>(0, (m, v) => v > m ? v : m);

    final weights = [
      for (final segment in series.weightSegments)
        for (final point in segment) _weight(point.kg),
    ];
    final minWeight = weights.isEmpty
        ? 0.0
        : weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.isEmpty
        ? 0.0
        : weights.reduce((a, b) => a > b ? a : b);
    final weightPad = ((maxWeight - minWeight) * 0.2).clamp(0.5, 5.0);
    final indexOf = {for (var i = 0; i < days.length; i++) days[i].day: i};

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: palette.textMuted,
    );
    Widget axisLabel(double value, TitleMeta meta) => SideTitleWidget(
      meta: meta,
      child: Text(meta.formattedValue, style: labelStyle),
    );
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
    final reserved = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _axisSpace,
        getTitlesWidget: (_, _) => const SizedBox.shrink(),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.trendsEnergyWeightLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: Dimens.spacing8),
          Wrap(
            spacing: Dimens.spacing16,
            children: [
              _Legend(color: accent, label: energyUnit),
              _Legend(color: weightColor, label: _weightUnit(s)),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          if (!hasEnergy && weights.isEmpty)
            Text(
              s.trendsNoEntriesLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            )
          else
            Semantics(
              label: s.trendsEnergyWeightLabel,
              child: SizedBox(
                height: _chartHeight,
                child: Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        minY: 0,
                        maxY: maxEnergy * 1.15 + 1,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          topTitles: hidden,
                          bottomTitles: hidden,
                          rightTitles: reserved,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: _axisSpace,
                              getTitlesWidget: axisLabel,
                            ),
                          ),
                        ),
                        extraLinesData: avgGoal == null || avgGoal <= 0
                            ? const ExtraLinesData()
                            : ExtraLinesData(
                                horizontalLines: [
                                  HorizontalLine(
                                    y: avgGoal,
                                    color: palette.textMuted,
                                    strokeWidth: 1.2,
                                    dashArray: const [6, 4],
                                  ),
                                ],
                              ),
                        barGroups: [
                          for (var i = 0; i < days.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                if (days[i].kcal case final kcal?)
                                  BarChartRodData(
                                    toY: EnergyDisplay.convert(context, kcal),
                                    color: accent.withValues(alpha: 0.7),
                                    width: days.length <= 14 ? 10 : 3,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (weights.isNotEmpty)
                      LineChart(
                        LineChartData(
                          minX: -0.5,
                          maxX: days.length - 0.5,
                          minY: minWeight - weightPad,
                          maxY: maxWeight + weightPad,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            topTitles: hidden,
                            bottomTitles: hidden,
                            leftTitles: reserved,
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: _axisSpace,
                                getTitlesWidget: axisLabel,
                              ),
                            ),
                          ),
                          lineBarsData: [
                            for (final segment in series.weightSegments)
                              LineChartBarData(
                                spots: [
                                  for (final point in segment)
                                    if (indexOf[point.day] case final i?)
                                      FlSpot(i.toDouble(), _weight(point.kg)),
                                ],
                                color: weightColor,
                                barWidth: 3,
                                isCurved: true,
                                preventCurveOverShooting: true,
                                dotData: FlDotData(show: segment.length == 1),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: Dimens.spacing4),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
