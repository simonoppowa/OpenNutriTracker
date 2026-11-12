import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_touch.dart';

Future<LineTouchData> _touch(
  WidgetTester tester,
  LineTouchData Function(BuildContext context) build,
) async {
  late LineTouchData data;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          data = build(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return data;
}

void main() {
  final bar = LineChartBarData(
    spots: const [FlSpot(0, 1200), FlSpot(1, 1500)],
    color: Colors.teal,
  );
  final spot = LineBarSpot(bar, 0, bar.spots[1]);

  testWidgets('the label is the item text; after follows it as a span', (
    tester,
  ) async {
    final data = await _touch(
      tester,
      (context) => labelledTouch(
        context,
        (s) => '${s.y.round()}',
        after: (s) => ' kcal\nday ${s.x.round()}',
      ),
    );
    final item = data.touchTooltipData.getTooltipItems([spot]).single!;
    expect(item.text, '1500');
    expect(item.children!.map((c) => c.toPlainText()), [' kcal\nday 1']);
  });

  testWidgets('without after, the item is the label alone', (tester) async {
    final data = await _touch(
      tester,
      (context) => labelledTouch(context, (s) => 'Weighed ${s.y}'),
    );
    final item = data.touchTooltipData.getTooltipItems([spot]).single!;
    expect(item.text, 'Weighed 1500.0');
    expect(item.children, isEmpty);
  });

  testWidgets('a touch marks the point with a dot, not a line to the axis', (
    tester,
  ) async {
    final data = await _touch(
      tester,
      (context) => labelledTouch(context, (s) => ''),
    );
    final indicator = data.getTouchedSpotIndicator(bar, [1]).single!;
    expect(indicator.indicatorBelowLine.strokeWidth, 0);
    expect(indicator.touchedSpotDotData.show, isTrue);
    final painter =
        indicator.touchedSpotDotData.getDotPainter(bar.spots[1], 0, bar, 1)
            as FlDotCirclePainter;
    expect(painter.color, Colors.teal);
  });

  testWidgets('a touch anywhere over the chart takes the nearest point', (
    tester,
  ) async {
    final data = await _touch(
      tester,
      (context) => labelledTouch(context, (s) => ''),
    );
    expect(data.touchSpotThreshold, double.infinity);
  });
}
