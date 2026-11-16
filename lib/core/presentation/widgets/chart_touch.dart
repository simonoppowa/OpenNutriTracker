import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Touch behaviour shared by the Trends and weight-history line charts.
///
/// The touched point gets a larger dot instead of fl_chart's default line
/// down to the axis, and the tooltip shows one line per series, built by
/// [label]. [after] follows the label in the same line as a separate span,
/// for a unit and a date after a bare number, so the item's own text stays
/// the number alone.
///
/// A touch anywhere over the chart picks the nearest day. fl_chart's
/// default only reacts within 10 px of a point, so on a sparse range a tap
/// between two days found nothing.
LineTouchData labelledTouch(
  BuildContext context,
  String Function(LineBarSpot spot) label, {
  String Function(LineBarSpot spot)? after,
}) {
  final scheme = Theme.of(context).colorScheme;
  final style = (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
      .copyWith(color: scheme.onInverseSurface);
  return LineTouchData(
    touchSpotThreshold: double.infinity,
    getTouchedSpotIndicator: (bar, indexes) => [
      for (final _ in indexes)
        TouchedSpotIndicatorData(
          const FlLine(color: Colors.transparent, strokeWidth: 0),
          FlDotData(
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 5,
              color: bar.color ?? scheme.primary,
              strokeWidth: 2,
              strokeColor: scheme.surface,
            ),
          ),
        ),
    ],
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => scheme.inverseSurface,
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      getTooltipItems: (spots) => [
        for (final s in spots)
          LineTooltipItem(
            label(s),
            style,
            children: [
              if (after != null) TextSpan(text: after(s), style: style),
            ],
          ),
      ],
    ),
  );
}
