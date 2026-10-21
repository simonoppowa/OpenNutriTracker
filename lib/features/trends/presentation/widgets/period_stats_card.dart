import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/trends/domain/period_stats.dart';
import 'package:opennutritracker/features/trends/domain/trends_tolerance_setting.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The numbers of the chosen period (#57): days with entries, the averages
/// over them and on how many days the energy and macro goals were met,
/// within a tolerance the user can change here (#56).
class PeriodStatsCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final List<TrackedDayEntity> days;
  final Map<DateTime, int> waterByDay;
  final int tolerancePercent;
  final ValueChanged<int> onToleranceChanged;

  const PeriodStatsCard({
    super.key,
    required this.start,
    required this.end,
    required this.days,
    required this.waterByDay,
    required this.tolerancePercent,
    required this.onToleranceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final stats = periodStats(
      start: start,
      end: end,
      days: days,
      waterByDay: waterByDay,
      tolerance: tolerancePercent / 100,
    );
    String grams(double? value) => value == null ? '—' : '${value.round()} g';

    final rows = <(String, String)>[
      (
        s.trendsTrackedDaysLabel,
        s.trendsDaysOfLabel(stats.trackedDays, stats.totalDays),
      ),
      if (stats.trackedDays > 0) ...[
        (
          s.trendsAvgEnergyLabel,
          EnergyDisplay.formatWithUnit(context, stats.avgKcal!),
        ),
        (s.carbsLabel, grams(stats.avgCarbs)),
        (s.fatLabel, grams(stats.avgFat)),
        (s.proteinLabel, grams(stats.avgProtein)),
      ],
      if (stats.avgWaterMl case final water?)
        (s.trendsAvgWaterLabel, '${water.round()} ml'),
      if (stats.trackedDays > 0) ...[
        (
          s.trendsKcalGoalMetLabel,
          s.trendsDaysOfLabel(stats.kcalOnTargetDays, stats.trackedDays),
        ),
        if (stats.macroGoalDays > 0)
          (
            s.trendsMacroGoalsMetLabel,
            s.trendsDaysOfLabel(stats.macrosOnTargetDays, stats.macroGoalDays),
          ),
      ],
    ];

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.trendsPeriodStatsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Semantics(
                identifier: 'trends-tolerance',
                child: PopupMenuButton<int>(
                  initialValue: tolerancePercent,
                  onSelected: onToleranceChanged,
                  itemBuilder: (_) => [
                    for (final percent in TrendsToleranceSetting.choices)
                      PopupMenuItem(
                        value: percent,
                        child: Text(s.trendsToleranceLabel(percent)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimens.spacing4,
                    ),
                    child: Text(
                      s.trendsToleranceLabel(tolerancePercent),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing12),
          if (stats.trackedDays == 0 && stats.avgWaterMl == null)
            Text(
              s.trendsNoEntriesLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            )
          else
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
