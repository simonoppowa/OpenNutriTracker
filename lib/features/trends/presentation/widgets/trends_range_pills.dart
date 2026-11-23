import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The range Trends covers, from a week to everything logged. Picking one
/// reloads the shared [TrendsBloc], so the overview and an open metric page
/// move together.
class TrendsRangePills extends StatelessWidget {
  final int rangeDays;

  const TrendsRangePills({super.key, required this.rangeDays});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // 0 is the "All" sentinel; the bloc resolves it to the full span.
    final ranges = [
      (days: 7, label: s.trendsRangeWeekLabel),
      (days: 30, label: s.trendsRangeMonthLabel),
      (days: 90, label: s.trendsRangeThreeMonthsLabel),
      (days: 180, label: s.trendsRangeSixMonthsLabel),
      (days: 365, label: s.trendsRangeYearLabel),
      (days: 0, label: s.allItemsLabel),
    ];
    return Semantics(
      identifier: 'trends-range-selector',
      // Scrolls rather than overflows at a large font on a narrow screen.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final r in ranges)
              ButtonSegment(
                value: r.days,
                label: Text(r.label),
                tooltip: r.days == 0 ? null : s.trendsRangeTooltip(r.days),
              ),
          ],
          selected: {rangeDays},
          onSelectionChanged: (selected) => context.read<TrendsBloc>().add(
            LoadTrendsEvent(rangeDays: selected.first),
          ),
        ),
      ),
    );
  }
}
