import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/pages/trends_metric_page.dart';
import 'package:opennutritracker/features/trends/presentation/trends_overview_calc.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/trends_range_pills.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/trends_tile.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The Trends tab: the streak, the range pills, then a tile per metric with
/// its headline for the range. A tile opens its metric's page, which shows
/// that metric's card from the Trends page.
class TrendsOverview extends StatelessWidget {
  final TrendsLoaded state;
  final Widget streak;
  final TrendsCardBuilder caloriesCard;
  final TrendsCardBuilder macrosCard;
  final TrendsCardBuilder waterCard;
  final TrendsCardBuilder weightCard;

  const TrendsOverview({
    super.key,
    required this.state,
    required this.streak,
    required this.caloriesCard,
    required this.macrosCard,
    required this.waterCard,
    required this.weightCard,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tiles = [
      TrendsTile(
        id: 'trends-tile-calories',
        title: s.trendsCaloriesLabel,
        onTap: () => TrendsMetricPage.open(
          context,
          title: s.trendsCaloriesLabel,
          body: (state, palette) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaloriesStats(state: state, palette: palette),
              const SizedBox(height: Dimens.spacing16),
              caloriesCard(state, palette),
            ],
          ),
        ),
        child: _CaloriesHeadline(state: state),
      ),
      TrendsTile(
        id: 'trends-tile-macros',
        title: s.trendsMacrosLabel,
        onTap: () => TrendsMetricPage.open(
          context,
          title: s.trendsMacrosLabel,
          body: macrosCard,
        ),
        child: _MacrosHeadline(state: state),
      ),
      TrendsTile(
        id: 'trends-tile-weight',
        title: s.weightHistoryWeightLabel,
        onTap: () => TrendsMetricPage.open(
          context,
          title: s.weightHistoryWeightLabel,
          body: weightCard,
        ),
        child: _WeightHeadline(state: state),
      ),
      TrendsTile(
        id: 'trends-tile-water',
        title: s.trendsWaterLabel,
        onTap: () => TrendsMetricPage.open(
          context,
          title: s.trendsWaterLabel,
          body: waterCard,
        ),
        child: _WaterHeadline(state: state),
      ),
    ];
    // At a large font a half-width tile is too narrow for its figures.
    final oneColumn = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing32,
      ),
      children: [
        streak,
        const SizedBox(height: Dimens.spacing16),
        TrendsRangePills(rangeDays: state.rangeDays),
        const SizedBox(height: Dimens.spacing16),
        if (oneColumn)
          for (final tile in tiles)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing12),
              child: tile,
            )
        else
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing12),
              // One height for both tiles of a row.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: Dimens.spacing12),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// The calories tile's average a day, over the average goal when set.
class _CaloriesHeadline extends StatelessWidget {
  final TrendsLoaded state;

  const _CaloriesHeadline({required this.state});

  @override
  Widget build(BuildContext context) {
    final average = windowAverage(
      state.days.map((d) => d.caloriesTracked),
      state.windowDays,
    );
    final goal = averageGoal(state.days.map((d) => d.calorieGoal));
    final unit = EnergyDisplay.unitLabel(context);
    final value = EnergyDisplay.formatValue(context, average);
    return TrendsTileValue(
      value: goal == null
          ? '$value $unit'
          : '$value / ${EnergyDisplay.formatValue(context, goal)} $unit',
      caption: S.of(context).trendsDailyAverageLabel,
    );
  }
}

/// The calories page's figures over its chart: the average a day and the
/// average goal, as the tile shows them.
class _CaloriesStats extends StatelessWidget {
  final TrendsLoaded state;
  final AppPalette palette;

  const _CaloriesStats({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = Theme.of(context).textTheme;
    final average = windowAverage(
      state.days.map((d) => d.caloriesTracked),
      state.windowDays,
    );
    final goal = averageGoal(state.days.map((d) => d.calorieGoal));
    final rows = [
      (
        s.trendsDailyAverageLabel,
        EnergyDisplay.formatWithUnit(context, average),
      ),
      if (goal != null)
        (s.goalLabel, EnergyDisplay.formatWithUnit(context, goal)),
    ];
    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        children: [
          for (final (label, value) in rows)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Dimens.spacing8),
                    // Wraps rather than overflows at a large font.
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: text.titleMedium?.copyWith(
                          color: palette.textStrong,
                          fontWeight: FontWeight.w700,
                        ),
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

/// The macros tile's grams a day of carbs, fat and protein, averaged and
/// cut to whole grams as the Daily average card shows them.
class _MacrosHeadline extends StatelessWidget {
  final TrendsLoaded state;

  const _MacrosHeadline({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final text = Theme.of(context).textTheme;
    double average(double? Function(TrackedDayEntity d) of) =>
        windowAverage(state.days.map(of), state.windowDays);
    final rows = [
      (s.carbsLabel, average((d) => d.carbsTracked)),
      (s.fatLabel, average((d) => d.fatTracked)),
      (s.proteinLabel, average((d) => d.proteinTracked)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, grams) in rows)
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: text.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Dimens.spacing8),
                Text(
                  '${grams.toInt()} ${s.gramUnit}',
                  style: text.bodySmall?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Text(
          s.trendsDailyAverageLabel,
          style: text.bodySmall?.copyWith(color: palette.textMuted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The weight tile's latest weigh-in, in the user's body-weight unit.
class _WeightHeadline extends StatelessWidget {
  final TrendsLoaded state;

  const _WeightHeadline({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // The bloc sorts the history oldest first.
    final latest = state.weight.isEmpty ? null : state.weight.last;
    return TrendsTileValue(
      value: latest == null
          ? '–'
          : formatBodyWeight(
              latest.weightKg,
              state.bodyWeightUnit,
              kgLabel: s.kgLabel,
              lbLabel: s.lbsLabel,
              stLabel: s.stLabel,
            ),
    );
  }
}

/// The water tile's average a day over the goal, in ml or fl oz as the water
/// card's header shows it (#1306).
class _WaterHeadline extends StatelessWidget {
  final TrendsLoaded state;

  const _WaterHeadline({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final now = DateTime.now();
    final averageMl = waterAverageMl(
      state.waterByDay,
      DateTime(now.year, now.month, now.day),
      state.windowDays,
    );
    final goalMl = state.waterGoalMl;
    return TrendsTileValue(
      value: state.usesImperialFoodUnits
          ? s.waterChipLabelFlOz(
              UnitCalc.mlToFlOz(averageMl.toDouble()).round(),
              UnitCalc.mlToFlOz(goalMl.toDouble()).round(),
            )
          : s.waterChipLabel(averageMl, goalMl),
      caption: s.trendsDailyAverageLabel,
    );
  }
}
