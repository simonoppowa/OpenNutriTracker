import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Smoothed weight trend line shared by the weight-history screen and the
/// Trends view, so both render the same chart — dated axis, a dashed
/// target-weight reference, dots on each reading, and a curved line.
///
/// [windowDays] sets how far back the chart looks; entries older than that
/// are dropped. The y-range is computed from the recorded weights so a
/// far-away target weight never squashes the trend.
class WeightTrendChart extends StatelessWidget {
  final List<WeightLogEntity> entries;
  final BodyWeightUnit bodyWeightUnit;
  final double? targetWeightKg;
  final int windowDays;
  final double chartHeight;

  const WeightTrendChart({
    super.key,
    required this.entries,
    required this.bodyWeightUnit,
    required this.targetWeightKg,
    this.windowDays = 30,
    this.chartHeight = 220,
  });

  /// Converts a stored kg value to the chart's y-axis unit.
  double _toChartY(double kg) {
    switch (bodyWeightUnit) {
      case BodyWeightUnit.kg:
        return kg;
      case BodyWeightUnit.lb:
        return UnitCalc.kgToLbs(kg);
      case BodyWeightUnit.st:
        // Decimal stones: total lbs / 14. One decimal is enough for the axis.
        return kg * 2.20462 / 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.primary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // windowDays days ending today (today sits at the right edge), matching
    // how the calorie/water charts window their range.
    final windowStart = today.subtract(Duration(days: windowDays - 1));

    final inWindow = entries
        .where((e) => !e.date.isBefore(windowStart) && !e.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (inWindow.length < 2) {
      return Padding(
        key: const Key('weightHistoryChartEmptyState'),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SizedBox(
          height: chartHeight,
          child: Center(
            child: Text(
              S.of(context).weightHistoryChartEmptyState,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (final entry in inWindow)
        FlSpot(
          // x = days since the window start, so today sits at x = windowDays.
          entry.date.difference(windowStart).inDays.toDouble(),
          _toChartY(entry.weightKg),
        ),
    ];

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Pad so points don't sit on the edges. When all weights are identical we
    // still need a non-zero range or fl_chart throws.
    final yPadding = ((maxY - minY) * 0.15).clamp(0.5, 5.0);

    final targetY = targetWeightKg == null ? null : _toChartY(targetWeightKg!);
    // Only draw the dashed reference when the target sits within (or just
    // adjacent to) the auto y-range, so a far-off target doesn't autoscale
    // the chart away from the recorded weights.
    final showTargetLine = targetY != null &&
        targetY >= (minY - yPadding) &&
        targetY <= (maxY + yPadding);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMd(localeTag);
    // ~5 evenly spaced date labels regardless of window length.
    final labelInterval = (windowDays / 5).ceilToDouble().clamp(1, 30).toDouble();

    return Padding(
      key: const Key('weightHistoryChart'),
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      child: SizedBox(
        height: chartHeight,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (windowDays - 1).toDouble(),
            minY: minY - yPadding,
            maxY: maxY + yPadding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(bodyWeightUnit == BodyWeightUnit.st ? 1 : 0),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: labelInterval,
                  getTitlesWidget: (value, meta) {
                    final day = windowStart.add(Duration(days: value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dateFormat.format(day),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (showTargetLine)
                  HorizontalLine(
                    y: targetY,
                    color: theme.colorScheme.outline,
                    strokeWidth: 1.2,
                    dashArray: const [6, 4],
                  ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
