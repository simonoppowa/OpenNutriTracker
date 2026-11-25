import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_touch.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/calc/weight_moving_average.dart';
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

  /// Trailing-window length for the moving-average overlay. Null hides the
  /// overlay entirely; the default of 7 days is a common weight-tracking
  /// smoothing that hides day-to-day water swings without lagging the real
  /// trend too far (#1119).
  final int? movingAverageWindowDays;

  /// The clock "today" is read from. The window's DST behaviour depends on
  /// which dates it spans, so a test that reads the real clock only proves
  /// something for a few weeks a year; tests pin this and restore it.
  /// Production never assigns it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// Height of the date labels under the plot; the y-axis gets the rest.
  static const double _bottomTitlesReservedSize = 28;

  /// Least vertical room one weight label needs: a `labelSmall` line
  /// (11.5 px) plus a gap, so neighbouring labels never touch.
  static const double _minYLabelSpacing = 24;

  const WeightTrendChart({
    super.key,
    required this.entries,
    required this.bodyWeightUnit,
    required this.targetWeightKg,
    this.windowDays = 30,
    this.chartHeight = 220,
    this.movingAverageWindowDays = 7,
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

    final now = clock();
    final today = DateTime(now.year, now.month, now.day);
    // windowDays calendar days ending today (today sits at the right edge),
    // matching how the calorie/water charts window their range. Built with
    // the y/m/d constructor, not `subtract(Duration)`: a Duration is fixed
    // 24-hour spans, so with an autumn fall-back inside the window it lands
    // an hour past local midnight and drops that day's entry (#1207).
    final windowStart = DateTime(
      today.year,
      today.month,
      today.day - (windowDays - 1),
    );
    // x = whole calendar days since the window start, so today sits at
    // x = windowDays - 1 and a day is one unit even when a DST transition
    // makes it 23 or 25 hours long. Every consumer of the x axis (dots,
    // date labels) goes through this pair so they cannot drift apart.
    int dayIndex(DateTime date) =>
        CalendarDayCalc.daysBetween(windowStart, date);
    DateTime dayAt(int x) => DateUtils.addDaysToDate(windowStart, x);

    final inWindow =
        entries
            .where(
              (e) => !e.date.isBefore(windowStart) && !e.date.isAfter(today),
            )
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
        FlSpot(dayIndex(entry.date).toDouble(), _toChartY(entry.weightKg)),
    ];

    // Compute the moving average against the *full* log and clip to the
    // visible window, so the leftmost MA point is anchored on entries
    // predating the window rather than lagging one window-length behind.
    final maSpots = <FlSpot>[
      if (movingAverageWindowDays != null)
        for (final point
            in WeightMovingAverage(windowDays: movingAverageWindowDays!)
                .compute(entries)
                .where((p) =>
                    !p.date.isBefore(windowStart) &&
                    !p.date.isAfter(today)))
          FlSpot(dayIndex(point.date).toDouble(), _toChartY(point.weightKg)),
    ];

    // The MA is the one series whose leftmost points fold in readings
    // that predate the visible window, so its y can land above or below
    // the raw envelope; include both series in the range so the dashed
    // line never paints outside the plot (LineChartData defaults to
    // FlClipData.none()).
    final rangeSpots = [...spots, ...maSpots];
    final minY = rangeSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = rangeSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Pad so points don't sit on the edges. When all weights are identical we
    // still need a non-zero range or fl_chart throws. The floor is small so
    // a week's few tenths of change still fill the chart.
    final yPadding = ((maxY - minY) * 0.15).clamp(0.1, 5.0);

    final targetY = targetWeightKg == null ? null : _toChartY(targetWeightKg!);
    // Only draw the dashed reference when the target sits within (or just
    // adjacent to) the auto y-range, so a far-off target doesn't autoscale
    // the chart away from the recorded weights.
    final showTargetLine =
        targetY != null &&
        targetY >= (minY - yPadding) &&
        targetY <= (maxY + yPadding);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMd(localeTag);
    // Read here: the tooltip is built outside this build.
    final l10n = S.of(context);
    final unitLabel = switch (bodyWeightUnit) {
      BodyWeightUnit.kg => l10n.kgLabel,
      BodyWeightUnit.lb => l10n.lbsLabel,
      BodyWeightUnit.st => l10n.stLabel,
    };
    // At large text the axes widen to fit their labels ("87.5", not "87."
    // over "5") and the dates thin out so they don't overlap.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // ~5 evenly spaced date labels regardless of window length (3 at large
    // text).
    final labelInterval = (windowDays / (textScale >= 1.5 ? 3 : 5))
        .ceilToDouble()
        .clamp(1.0, double.infinity)
        .toDouble();

    // Below ~3 kg/lb of spread the ticks sit less than a unit apart and a
    // zero-decimal label would round two neighbours to the same whole
    // number ("62, 62, 63, 63" in #1445). Pair a half-unit interval with a
    // one-decimal label so no two ticks ever print the same text. Stones
    // is always one decimal because 2.20462/14 rarely lands on a whole.
    final narrowRange = (maxY - minY) < 3;
    final yAxisDecimals =
        bodyWeightUnit == BodyWeightUnit.st || narrowRange ? 1 : 0;
    // On a wide range one-unit ticks crowd together (80–100 kg pads to
    // 77–103: 27 labels in under 200 px), so step the interval up through
    // multiples of the base until the labels fit the plot's height. Every
    // multiple keeps the ticks on values the chosen decimals print exactly.
    final baseYInterval = yAxisDecimals == 1 ? 0.5 : 1.0;
    final yRange = (maxY + yPadding) - (minY - yPadding);
    final maxYLabels =
        (chartHeight - _bottomTitlesReservedSize) / _minYLabelSpacing;
    final yAxisInterval = [1, 2, 5, 10, 20, 50]
        .map((step) => baseYInterval * step)
        .firstWhere(
          (interval) => yRange / interval <= maxYLabels,
          orElse: () => baseYInterval * 100,
        );

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
            // Each number says which series it is, at one decimal, with its
            // unit: fl_chart's default printed the moving average unrounded
            // ("95.13333333333337") and unlabelled beside the weigh-in.
            lineTouchData: labelledTouch(context, (s) {
              final weight = s.y.toStringAsFixed(1);
              return s.barIndex == 0
                  ? l10n.weightChartWeighedTooltip(weight, unitLabel)
                  : l10n.weightChartAverageTooltip(
                      movingAverageWindowDays ?? 0,
                      weight,
                      unitLabel,
                    );
            }),
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
                  reservedSize: 40 * textScale,
                  interval: yAxisInterval,
                  // The padded bounds sit off the tick grid, and fl_chart
                  // labels them by default: 62–65.8 kg pads up to 66.37,
                  // which prints "66" right beside the regular tick at 66.
                  minIncluded: false,
                  maxIncluded: false,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(yAxisDecimals),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: _bottomTitlesReservedSize * textScale,
                  interval: labelInterval,
                  getTitlesWidget: (value, meta) {
                    final day = dayAt(value.toInt());
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
              // Moving-average overlay (#1119): dashed, no dots, thinner
              // than the primary line so the raw readings still read as
              // the leading signal. Rendered second so it sits on top of
              // the raw line where they overlap.
              if (maSpots.length >= 2)
                LineChartBarData(
                  spots: maSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: lineColor.withValues(alpha: 0.55),
                  barWidth: 1.5,
                  dashArray: const [6, 4],
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
