import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/trends/domain/trends_period.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Picks what the trends show (#57): the last 7, 30 or 90 days or everything,
/// a calendar week or a month (each with back and forth), or a span from a
/// date range picker. Every choice goes out as a [LoadTrendsEvent].
class TrendsPeriodSelector extends StatelessWidget {
  final int rangeDays;
  final TrendsPeriod? period;
  final ValueChanged<LoadTrendsEvent> onLoad;
  final DateTime Function() today;

  const TrendsPeriodSelector({
    super.key,
    required this.rangeDays,
    required this.period,
    required this.onLoad,
    this.today = DateTime.now,
  });

  Future<void> _pickRange(BuildContext context) async {
    final now = today();
    final current = period;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: current == null || current.start.isAfter(now)
          ? null
          : DateTimeRange(
              start: current.start,
              end: current.end.isAfter(now) ? now : current.end,
            ),
    );
    if (picked == null) return;
    onLoad(
      LoadTrendsEvent(period: TrendsPeriod.custom(picked.start, picked.end)),
    );
  }

  String _label(BuildContext context, TrendsPeriod period) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayMonth = DateFormat.MMMd(locale);
    final range =
        '${dayMonth.format(period.start)} – ${dayMonth.format(period.end)}';
    return switch (period.kind) {
      TrendsPeriodKind.week =>
        '${s.trendsCalendarWeekLabel(period.isoWeek)} · $range',
      TrendsPeriodKind.month => DateFormat.yMMMM(locale).format(period.start),
      _ => '$range ${period.end.year}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final current = period;
    final kind = current?.kind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'trends-range-selector',
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              const ButtonSegment(value: 7, label: Text('7d')),
              const ButtonSegment(value: 30, label: Text('30d')),
              const ButtonSegment(value: 90, label: Text('90d')),
              ButtonSegment(value: 0, label: Text(s.allItemsLabel)),
            ],
            selected: current == null ? {rangeDays} : {},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              onLoad(LoadTrendsEvent(rangeDays: selection.first));
            },
          ),
        ),
        const SizedBox(height: Dimens.spacing8),
        Wrap(
          spacing: Dimens.spacing8,
          children: [
            ChoiceChip(
              label: Text(s.trendsWeekLabel),
              selected: kind == TrendsPeriodKind.week,
              onSelected: (_) =>
                  onLoad(LoadTrendsEvent(period: TrendsPeriod.week(today()))),
            ),
            ChoiceChip(
              label: Text(s.trendsMonthLabel),
              selected: kind == TrendsPeriodKind.month,
              onSelected: (_) =>
                  onLoad(LoadTrendsEvent(period: TrendsPeriod.month(today()))),
            ),
            ChoiceChip(
              label: Text(s.trendsCustomPeriodLabel),
              selected: kind == TrendsPeriodKind.custom,
              onSelected: (_) => _pickRange(context),
            ),
          ],
        ),
        if (current != null) ...[
          const SizedBox(height: Dimens.spacing4),
          Row(
            children: [
              if (current.canStep)
                IconButton(
                  tooltip: s.trendsPreviousPeriod,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () =>
                      onLoad(LoadTrendsEvent(period: current.step(-1))),
                ),
              Expanded(
                child: Text(
                  _label(context, current),
                  textAlign: current.canStep
                      ? TextAlign.center
                      : TextAlign.start,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (current.canStep)
                IconButton(
                  tooltip: s.trendsNextPeriod,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () =>
                      onLoad(LoadTrendsEvent(period: current.step(1))),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
